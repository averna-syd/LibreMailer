package LibreMailer::Worker;

use Moo;
use Dancer qw(:syntax !before !after);
use Dancer::Plugin::Database;
use Dancer::FileUtils qw(dirname path read_file_content);
use Parallel::ForkManager;
use HTML::LinkExtractor;
use Email::Stuff;
use Email::Send;
use Email::Valid;
use Mail::POP3Client;
use IO::Socket::SSL;
use Mail::DeliveryStatus::BounceParser;
use Data::Dumper;

use LibreMailer::DateTime;
use LibreMailer::EncodeSafeURL;

our $VERSION = '0.1';

has base_url                => ( is => 'ro', default => sub { config->{base_url} } );
has email_from              => ( is => 'ro', default => sub { config->{email_from} } );
has mailer                  => ( is => 'ro', default => sub { 'SMTP' } );
has host                    => ( is => 'ro', default => sub { config->{smtp_server} } );
has workers                 => ( is => 'ro', default => sub { 64 } );
has process_bounce_messages => ( is => 'ro', default => sub { config->{process_bounce_messages} } );
has pop3_bounce_ssl_host    => ( is => 'ro', default => sub { config->{pop3_bounce_ssl_host} } );
has pop3_bounce_username    => ( is => 'ro', default => sub { config->{pop3_bounce_username} } );
has pop3_bounce_password    => ( is => 'ro', default => sub { config->{pop3_bounce_password} } );

sub clean_lists
{
    # Clean lists for duplicates or bad emails or dead contacts.
    my $self  = shift;
    my $db    = database;
    my @lists = $db->quick_select( 'lists', { } );

    for my $list ( @lists )
    {
        my @contacts = $db->quick_select( 'contacts', { list_id => $list->{id} } );

        for my $contact ( @contacts )
        {
            if ( ! Email::Valid->address( $contact->{email} ) )
            {
                $db->quick_delete( 'contacts', { email => $contact->{email} } );
                next;
            }

            my $count_list = $db->quick_count( 'lists', { id => $contact->{list_id} } );

            if ( ! $count_list )
            {
                $db->quick_delete( 'contacts', { id => $contact->{id} } );
            }

            my $count_contact = $db->quick_count( 'contacts', { list_id => $list->{id}, email => $contact->{email} } );

            if ( $count_contact && $count_contact > 1 )
            {
                my @dedupe = $db->quick_select( 'contacts', { list_id => $list->{id}, email => $contact->{email} } );

                for my $dedupe ( @dedupe[1 .. $#dedupe] )
                {
                    $db->quick_delete( 'contacts', { id => $dedupe->{id} } );
                }
            }
        }
    }
}

sub process_campaigns
{
    # Process every campaign that is ready for sending.
    my $self      = shift;
    my $db        = database;
    my $campaigns = $self->_get_campaigns;

    for my $campaign ( @{ $campaigns } )
    {
        $self->_start_statistics( $campaign );
        $self->_generate_templates( $campaign->{id}, $campaign->{html_body}, $campaign->{text_body} );

        my $contacts = $self->_get_contacts( $campaign );
        my $pm       = Parallel::ForkManager->new( $self->workers );

        for my $contact ( @{ $contacts } )
        {
            $pm->start and next;
            $self->_send( $campaign, $contact );
            $pm->finish;
        }

        $db->quick_update( 'campaigns', { id => $campaign->{id} }, { send => 'No', sending => 'No', sent => 'Yes' } );
        $self->_end_statistics( $campaign );

        $pm->wait_all_children;
    }
}

sub process_bounces
{
    # Login into pop3 acccount get bounces and log it for stats
    my $self    = shift;
    my $process = $self->process_bounce_messages;
    my $host    = $self->pop3_bounce_ssl_host;
    my $user    = $self->pop3_bounce_username;
    my $pass    = $self->pop3_bounce_password;

    if ( ! $process || ! $host || ! $user || ! $pass )
    {
        return;
    }

    my $socket = IO::Socket::SSL->new( $host );
    my $pop    = Mail::POP3Client->new();

    $pop->User( $user );
    $pop->Pass( $pass );
    $pop->Socket( $socket );
    $pop->Connect();

    my $count = $pop->Count;

    if ( $count == -1 )
    {
        print "Unable to read Bounce Mailbox! Something went horribly wrong here.\n";
        return;
    }

    my $nummessages = $pop->Count();

    foreach my $message ( 1 ... $nummessages )
    {
        my $mailpiece = $pop->HeadAndBody( $message );
        my $bounce    = eval { Mail::DeliveryStatus::BounceParser->new( $mailpiece ) };

        if ( $@ ) 
        { 
            $pop->Delete( $message ); 
            next; 
        }

        if ( ! $bounce->is_bounce() ) 
        { 
            $pop->Delete( $message ); 
            next; 
        }

        my @reports = $bounce->reports();

        foreach my $report (@reports)
        {
            my $email   = $report->get('email');
            my $reason  = $report->get('std_reason');
            my $orig    = $bounce->orig_text();
            my $db      = database;
            my $contact = $db->quick_select( 'contacts', { email => $email } );

            if ( $contact->{id} )
            {
                $db->quick_update( 'contacts', { id => $contact->{id} }, { status => 'Bounced' } );

                if ( $mailpiece =~ m{Campaign-id:\s*(\d+)}i )
                {
                    my $campaign_id = $1;

                    if ( $campaign_id )
                    {
                        $db->quick_insert( 'statistics_bounces', { campaign_id => $campaign_id, contact_id => $contact->{id} } );
                    }
                }
            }

            next if ( ! $email );
        }

        $pop->Delete( $message );
    }

    $pop->State();
    $pop->Close();
}

sub _get_campaigns
{
    # Get campaigns ready for sending and mark them as sending thereby locking them from another process.
    my $self      = shift;
    my $db        = database;
    my @campaigns = $db->quick_select( 'campaigns', { send => 'Yes', sending => 'No' } );
    my $dt        = LibreMailer::DateTime->new();

    my @campaigns_ready;

    for my $campaign ( @campaigns )
    {
        if ( $dt->check_schedule( $campaign->{scheduled} ) )
        {
            $db->quick_update( 'campaigns', { id => $campaign->{id} }, { sending => 'Yes' } );
            push ( @campaigns_ready, $campaign )
        }
    }

    return \@campaigns_ready;
}

sub _get_contacts
{
    # Get all valid contacts for a specifc campaign send.
    my $self     = shift;
    my $campaign = shift;
    my $db       = database;

    my @contacts = $db->quick_select( 'contacts', { list_id => $campaign->{list_id}, confirmation => 'Confirmed', status => 'Active' } );

    return \@contacts;
}

sub _start_statistics
{
    # Insert stats with start sending time.
    my $self     = shift;
    my $campaign = shift;
    my $db       = database;
    my $dt       = LibreMailer::DateTime->new();

    $db->quick_insert( 'statistics', { 
                                        campaign_name   => $campaign->{name},
                                        campaign_id     => $campaign->{id},  
                                        list_id         => $campaign->{list_id}, 
                                        start_sending   => $dt->sql_current_datetime,
                                     }
                     );
}

sub _end_statistics
{
    # Insert stats end sending time.
    my $self     = shift;
    my $campaign = shift;
    my $db       = database;
    my $dt       = LibreMailer::DateTime->new();

    $db->quick_update( 'statistics', { campaign_id => $campaign->{id} }, { end_sending => $dt->sql_current_datetime } );
}

sub _generate_templates
{
    # Generate template from database and write to filesystem ready for campaign launch.
    my $self     = shift;
    my $id       = shift;
    my $html     = shift;
    my $text     = shift;
    my $db       = database;
    my $base_url = $self->base_url;
    my $vdir     = Dancer::FileUtils::path( setting('appdir'), 'views' );
    my $lx       = new HTML::LinkExtractor();

    $lx->parse( \$html );

    my $safe_url    = LibreMailer::EncodeSafeURL->new();
    my $mapped_html = $html;
    my $mapped_text = $text;
    my $encode_id   = $safe_url->encrypt_sting( $id );

    for my $link ( @{ $lx->links } )
    {
        next if ( $link->{tag} !~ m{a}i );

        my $name = $link->{_TEXT};

        if ( $link->{href} =~ m{\[\%\s*unsubscribe\s*\%\]}i )
        {
            $mapped_html =~ s/\[\%\s*unsubscribe\s*\%\]/$base_url\/t\/unsubscribe\/$encode_id\/[% id %]/g;
            $mapped_text =~ s/\[\%\s*unsubscribe\s*\%\]/$base_url\/t\/unsubscribe\/$encode_id\/[% id %]/g;
            next;
        }

        if ( $link->{href} =~ m{\[\%\s*viewonline\s*\%\]}i )
        {
            $mapped_html =~ s/\[\%\s*viewonline\s*\%\]/$base_url\/t\/viewonline\/$encode_id\/[% id %]/g;
            $mapped_text =~ s/\[\%\s*viewonline\s*\%\]/$base_url\/t\/viewonline\/$encode_id\/[% id %]/g;
            next;
        }

        $name = 'Unknown' if ( ! $name );
        $name =~ s/<.+?>//g;

        $db->quick_insert( 'url_mappings', { campaign_id => $id, name => $name, destination => $link->{href} } );

        my $href           = $db->quick_select( 'url_mappings', { campaign_id => $id, destination => $link->{href} } );
        my $encode_href_id = $safe_url->encrypt_sting( $href->{id} );

        $mapped_html =~ s/$link->{href}/$base_url\/t\/link\/$encode_id\/[% id %]\/$encode_href_id/g;
        $mapped_text =~ s/$link->{href}/$base_url\/t\/link\/$encode_id\/[% id %]\/$encode_href_id/g;
    }

    my $open_track = '<img src="' . "$base_url/t/open/$encode_id" . '/[% id %]/open.gif" alt="">';
    $mapped_html .= $open_track;

    for my $type ( qw( html text ) )
    {
        open( my $fh, '>:utf8', $vdir . '/data/' . $type . '_campaign_' . $id . '.tt' );
            print $fh ( ( $type eq 'text' ) ? $mapped_text : $mapped_html );
        close( $fh );
    }
}

sub _send
{
    # Send campaign email.
    my $self     = shift;
    my $campaign = shift;
    my $contact  = shift;
    my $db       = database;
    my $mail     = Email::Stuff->new;
    my $safe_url = LibreMailer::EncodeSafeURL->new();

    $db->quick_insert( 'statistics_recipients', {
                                                    campaign_id => $campaign->{id}, 
                                                    contact_id  => $contact->{id}, 
                                                    email       => $contact->{email},
                                                }
                     );

    $mail->from( $self->email_from );
    $mail->to( $contact->{email} );

    $mail->header( 'Campaign-id' => $campaign->{id} );
    $mail->header( 'Reply-to'    => $campaign->{email_reply_to} );
    $mail->header( 'Errors-To'   => $self->email_from );

    $mail->subject( $campaign->{subject} );

    $contact->{id} = $safe_url->encrypt_sting( $contact->{id} );

    if ( $contact->{format} =~ m{text}xmsi )
    {
        $mail->text_body( template 'data/text_campaign_' . $campaign->{id}, $contact, { layout => undef } );
    }
    else
    {
        $mail->html_body( template 'data/html_campaign_' . $campaign->{id}, $contact, { layout => undef } );
    }

    my $mailer = Email::Send->new( { mailer => $self->mailer } );
    $mailer->mailer_args( [ Host => $self->host ] );

    $mail->send( $mailer );
}

1;

__END__

=pod

=head1 NAME

LibreMailer::Worker

=head1 DESCRIPTION

The brains of the app!

=head1 AUTHOR

Sarah Fuller, C<< <sarah at averna.id.au> >>

=head1 LICENSE AND COPYRIGHT

This file is part of LibreMailer

LibreMailer is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

LibreMailer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with LibreMailer.  If not, see <http://www.gnu.org/licenses/>.

=cut
