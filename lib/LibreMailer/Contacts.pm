package LibreMailer::Contacts;

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
    record_title => 'Contact',
    prefix => '/contacts',
    db_table => 'contacts',
    labels => {
        list_id      => 'Contact List',
        email        => 'Email Address',
        format       => 'Email Format',
        confirmation => 'Confirmation Status',
        firstname    => 'First Name',
        lastname     => 'Last Name',
    },
    input_types => {
        list_id      => 'select',
        firstname    => 'text',
        lastname     => 'text',
        format       => 'select',
        confirmation => 'select',
        status       => 'select',
    },
    required         => [ qw( list_id email format confirmation status firstname lastname ) ],
    key_column       => 'id',
    editable_columns => [ qw( list_id email format confirmation status firstname lastname ) ],
    display_columns  => [ qw( list_id email format confirmation status firstname lastname ) ],
    deleteable => 1,
    editable => 1,
    sortable => 1,
    paginate => 100,
    template => 'contacts.tt',
    query_auto_focus => 0,
    downloadable => 1,
    foreign_keys => {
        list_id => {
            table => 'lists',
            key_column => 'id',
            label_column => 'name',
        },
    },
);

true;

__END__

=pod

=head1 NAME

LibreMailer::Contacts

=head1 DESCRIPTION

Contact management

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

