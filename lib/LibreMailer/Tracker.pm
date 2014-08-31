package LibreMailer::Tracker;

use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::SimpleCRUD;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Passphrase;
use Dancer::Session::Cookie;
use Dancer::Plugin::REST;
use Dancer::Plugin::FlashMessage;
use Dancer::FileUtils qw(dirname path read_file_content);
use Email::Valid;
use Text::CSV;
use Data::Dumper;

use LibreMailer::EncodeSafeURL;

our $VERSION = '0.1';

any '/t/open/:campaign_id/:contact_id/open.gif' => sub
{
    # Process open rate
    my $params   = params;
    my $db       = database;
    my $safe_url = LibreMailer::EncodeSafeURL->new();
    my $vdir     = Dancer::FileUtils::path( setting('appdir'), 'public' );

    $params->{campaign_id} = $safe_url->decrypt_string( $params->{campaign_id} );
    $params->{contact_id}  = $safe_url->decrypt_string( $params->{contact_id} );

    if ( $params->{campaign_id} && $params->{contact_id} )
    {
        my $count = $db->quick_count( 'statistics_opens', { 
                                                            campaign_id => $params->{campaign_id},
                                                            contact_id  => $params->{contact_id},
                                                          }
                                    );

        if ( ! $count )
        {
            $db->quick_insert( 'statistics_opens', {
                                                       campaign_id => $params->{campaign_id},
                                                       contact_id  => $params->{contact_id},
                                                   }
                             );
        }
    }

    header( 'Content-Type'  => 'image/gif' );
    header( 'Cache-Control' =>  'no-store, no-cache, must-revalidate' );

    open( my $fh, '<', $vdir . '/images/track.gif' );
        binmode( $fh );
        my $image = do { local $/; <$fh> };
    close( $fh );

    return $image;
};

any '/t/link/:campaign_id/:contact_id/:url_id' => sub 
{
    # Process url clicks
    my $params   = params;
    my $db       = database;
    my $safe_url = LibreMailer::EncodeSafeURL->new();

    $params->{campaign_id} = $safe_url->decrypt_string( $params->{campaign_id} );
    $params->{contact_id}  = $safe_url->decrypt_string( $params->{contact_id} );
    $params->{url_id}      = $safe_url->decrypt_string( $params->{url_id} );

    if ( $params->{campaign_id} && $params->{contact_id} && $params->{url_id} )
    {
        my $url = $db->quick_select( 'url_mappings', { id => $params->{url_id} } );

        my $count = $db->quick_count( 'statistics_links', {
                                                             campaign_id => $params->{campaign_id},
                                                             contact_id  => $params->{contact_id},
                                                             url_id      => $params->{url_id},
                                                          }
                                    );
        if ( ! $count )
        {
            $db->quick_insert( 'statistics_links', {
                                                       campaign_id => $params->{campaign_id},
                                                       contact_id  => $params->{contact_id},
                                                       url_id      => $params->{url_id},
                                                   }
                             );
        }

        return redirect $url->{destination};
    }

    return template '404', {};
};

any '/t/viewonline/:campaign_id/:contact_id' => sub
{
    # View html in, you know, a web browser where it f*%king should be!
    my $params   = params;
    my $db       = database;
    my $safe_url = LibreMailer::EncodeSafeURL->new();

    $params->{campaign_id} = $safe_url->decrypt_string( $params->{campaign_id} );
    $params->{contact_id}  = $safe_url->decrypt_string( $params->{contact_id} );

    if ( $params->{campaign_id} && $params->{contact_id} )
    {
        my $contact = $db->quick_select( 'contacts', { id => $params->{contact_id} } );

        $contact->{id} = $safe_url->encrypt_sting( $contact->{id} );

        return template 'data/html_campaign_' . $params->{campaign_id}, $contact, { layout => undef };
    }

    return template '404', {}, { layout => undef };
};

any '/t/unsubscribe/:campaign_id/:contact_id' => sub 
{
    # Process unsubscribes
    my $params   = params;
    my $db       = database;
    my $safe_url = LibreMailer::EncodeSafeURL->new();

    $params->{campaign_id} = $safe_url->decrypt_string( $params->{campaign_id} );
    $params->{contact_id}  = $safe_url->decrypt_string( $params->{contact_id} );

    if ( $params->{campaign_id} && $params->{contact_id} )
    {
        my $count = $db->quick_count( 'statistics_unsubscribes', { 
                                                                    contact_id => $params->{contact_id}, 
                                                                    campaign_id => $params->{campaign_id},
                                                                 }
                                    );

        if ( ! $count )
        {
            $db->quick_insert( 'statistics_unsubscribes', { 
                                                            contact_id => $params->{contact_id}, 
                                                            campaign_id => $params->{campaign_id},
                                                          } 
                             );
        }

        $db->quick_update( 'contacts', { id => $params->{contact_id} }, { status => 'Unsubscribed' } );
    }

    return template 'unsubscribe', {};
};

true;

__END__

=pod

=head1 NAME

LibreMailer::Tracker

=head1 DESCRIPTION

naughty tracking

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

