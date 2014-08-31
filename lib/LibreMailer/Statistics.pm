package LibreMailer::Statistics;

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

simple_crud(
    record_title => 'Statistics',
    prefix => '/statistics',
    db_table => 'statistics',
    labels => {
        campaign_name => 'Campaign Name',
        list_id       => 'Contact List',
        campaign_id   => 'Campaign',
        start_sending => 'Started Sending',
        end_sending   => 'Ended Sending',
    },
    required         => [ qw( ) ],
    key_column       => 'id',
    editable_columns => [ qw( ) ],
    display_columns  => [ qw( campaign_name list_id end_sending ) ],
    deleteable => 0,
    editable => 0,
    sortable => 1,
    paginate => 100,
    template => 'statistics.tt',
    query_auto_focus => 0,
    downloadable => 1,
    foreign_keys => {
        list_id => {
            table => 'lists',
            key_column => 'id',
            label_column => 'name',
        },
    },
    custom_columns => {
        'Opens' => {
            raw_column => "id",
            transform  => sub {
                my $id    = shift;
                my $db    = database;
                my $stats = $db->quick_select( 'statistics', { id => $id } );
                my $rcpt  = $db->quick_count( 'statistics_recipients', { campaign_id => $stats->{campaign_id} } );
                my $open  = $db->quick_count( 'statistics_opens', { campaign_id => $stats->{campaign_id} } );
            
                my $opened = sprintf "%.2f", ( $open / $rcpt ) * 100;

                return "$opened&#37; <a href='/statistics/opens?searchfield=campaign_id&searchtype=c&q=$stats->{campaign_id}&o=&d=&searchsubmit=Search'>View</a>";
            },
        },
        'Links' => {
            raw_column => "id",
            transform  => sub {
                my $id    = shift;
                my $db    = database;
                my $stats = $db->quick_select( 'statistics', { id => $id } );
                my @links  = $db->quick_select( 'url_mappings', { campaign_id => $stats->{campaign_id} } );
                my $count;

                for my $link ( @links )
                {
                    $count += $db->quick_count( 'statistics_links', { url_id => $link->{id} } );
                }

                return "$count Clicks <a href='/statistics/links?searchfield=campaign_id&searchtype=c&q=$stats->{campaign_id}&o=contact_id&d=desc&searchsubmit=Search'>View</a>";
            },
        },
        'Unsubscribe' => {
            raw_column => "id",
            transform  => sub {
                my $id    = shift;
                my $db    = database;
                my $stats = $db->quick_select( 'statistics', { id => $id } );
                my $rcpt  = $db->quick_count( 'statistics_recipients', { campaign_id => $stats->{campaign_id} } );
                my $unsub = $db->quick_count( 'statistics_unsubscribes', { campaign_id => $stats->{campaign_id} } );

                my $unsubscribed = sprintf "%.2f", ( $unsub / $rcpt ) * 100;

                return "$unsubscribed&#37; <a href='/statistics/unsubscribes?searchfield=campaign_id&searchtype=c&q=$stats->{campaign_id}&o=&d=&searchsubmit=Search'>View</a>";
            },
        },
        'Bounce' => {
            raw_column => "id",
            transform  => sub {
                my $id     = shift;
                my $db     = database;
                my $stats  = $db->quick_select( 'statistics', { id => $id } );
                my $rcpt   = $db->quick_count( 'statistics_recipients', { campaign_id => $stats->{campaign_id} } );
                my $bounce = $db->quick_count( 'statistics_bounces', { campaign_id => $stats->{campaign_id} } );

                my $bounced = sprintf "%.2f", ( $bounce / $rcpt ) * 100;

                return "$bounced&#37; <a href='/statistics/bounces?searchfield=campaign_id&searchtype=c&q=$stats->{campaign_id}&o=&d=&searchsubmit=Search'>View</a>";
            },
        },
        'Report' => {
            raw_column => "id",
            transform  => sub {
                my $id = shift;

                return "<a href='/statistics/report/$id'>View</a>";
            },
        },
    },
);

simple_crud(
    record_title => 'Open Statistics',
    prefix => '/statistics/opens',
    db_table => 'statistics_opens',
    labels => {
        campaign_id => 'Campaign',
        contact_id  => 'Contact',
    },
    required         => [ qw( ) ],
    key_column       => 'campaign_id',
    editable_columns => [ qw( ) ],
    display_columns  => [ qw( campaign_id contact_id ) ],
    deleteable => 0,
    editable => 0,
    sortable => 1,
    paginate => 100,
    template => 'statistics_opens.tt',
    query_auto_focus => 0,
    downloadable => 1,
    foreign_keys => {
        campaign_id => {
            table => 'campaigns',
            key_column => 'id',
            label_column => 'name',
        },
        contact_id => {
            table => 'statistics_recipients',
            key_column => 'contact_id',
            label_column => 'email',
        },
    },
);

simple_crud(
    record_title => 'Links Statistics',
    prefix => '/statistics/links',
    db_table => 'statistics_links',
    labels => {
        campaign_id => 'Campaign',
        contact_id  => 'Contact',
    },
    required         => [ qw( ) ],
    key_column       => 'campaign_id',
    editable_columns => [ qw( ) ],
    display_columns  => [ qw( campaign_id contact_id ) ],
    deleteable => 0,
    editable => 0,
    sortable => 1,
    paginate => 100,
    template => 'statistics_links.tt',
    query_auto_focus => 0,
    downloadable => 1,
    foreign_keys => {
        campaign_id => {
            table => 'campaigns',
            key_column => 'id',
            label_column => 'name',
        },
        contact_id => {
            table => 'statistics_recipients',
            key_column => 'contact_id',
            label_column => 'email',
        },
    },
    custom_columns => {
        'Link Clicked' => {
            raw_column => "url_id",
            transform  => sub {
                my $id = shift;
                my $db   = database;
                my $link = $db->quick_select( 'url_mappings', { id => $id } );

                return "<a href='$link->{destination}'>$link->{name}</a>";
            },
        },
    },
);

simple_crud(
    record_title => 'Bounce Statistics',
    prefix => '/statistics/bounces',
    db_table => 'statistics_bounces',
    labels => {
        campaign_id => 'Campaign',
        contact_id  => 'Contact',
    },
    required         => [ qw( ) ],
    key_column       => 'campaign_id',
    editable_columns => [ qw( ) ],
    display_columns  => [ qw( campaign_id contact_id ) ],
    deleteable => 0,
    editable => 0,
    sortable => 1,
    paginate => 100,
    template => 'statistics_bounces.tt',
    query_auto_focus => 0,
    downloadable => 1,
    foreign_keys => {
        campaign_id => {
            table => 'campaigns',
            key_column => 'id',
            label_column => 'name',
        },
        contact_id => {
            table => 'statistics_recipients',
            key_column => 'contact_id',
            label_column => 'email',
        },
    },
);

simple_crud(
    record_title => 'Unsubscribe Statistics',
    prefix => '/statistics/unsubscribes',
    db_table => 'statistics_unsubscribes',
    labels => {
        campaign_id => 'Campaign',
        contact_id  => 'Contact',
    },
    required         => [ qw( ) ],
    key_column       => 'campaign_id',
    editable_columns => [ qw( ) ],
    display_columns  => [ qw( campaign_id contact_id ) ],
    deleteable => 0,
    editable => 0,
    sortable => 1,
    paginate => 100,
    template => 'statistics_unsubscribes.tt',
    query_auto_focus => 0,
    downloadable => 1,
    foreign_keys => {
        campaign_id => {
            table => 'campaigns',
            key_column => 'id',
            label_column => 'name',
        },
        contact_id => {
            table => 'statistics_recipients',
            key_column => 'contact_id',
            label_column => 'email',
        },
    },
);

any '/statistics/report/:id' => sub
{
    my $params = params;
    my $db     = database;

    my $stats = $db->quick_select( 'statistics', { id => $params->{id} } );

    my $opens          = {};
    $opens->{rcpt}     = $db->quick_count( 'statistics_recipients', { campaign_id => $params->{id} } );
    $opens->{opened}   = $db->quick_count( 'statistics_opens', { campaign_id => $params->{id} } );
    $opens->{bounced}  = $db->quick_count( 'statistics_bounces', { campaign_id => $params->{id} } );
    $opens->{unopened} = ( $opens->{opened} ) 
                       ? ( ( $opens->{rcpt} - $opens->{opened} ) - $opens->{bounced} )
                       : ( $opens->{rcpt} - $opens->{bounced} );

    my @links  = $db->quick_select( 'url_mappings', { campaign_id => $params->{id} } );

    for my $link ( @links )
    {
        $link->{count} = $db->quick_count( 'statistics_links', { url_id => $link->{id} } );
    }

    template 'report', { opens => $opens, links => \@links, stats => $stats };
};

true;

__END__

=pod

=head1 NAME

LibreMailer::Statistics

=head1 DESCRIPTION

stats viewing

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

