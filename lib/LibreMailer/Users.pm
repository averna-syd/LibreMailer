package LibreMailer::Users;

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
    record_title => 'User',
    prefix => '/users',
    db_table => 'users',
    labels => {
        username     => 'Username',
        password     => 'Password',
        firstname    => 'First Name',
        lastname     => 'Last Name',
        email        => 'Email Address',
    },
    validation => {
        id       => qr/\d+/,
    },
    input_types => {
        username  => 'text',
        firstname => 'text',
        lastname  => 'text',
        password  => 'password',
        email     => 'text',
    },
    required         => [ qw( username password firstname lastname email ) ],
    key_column       => 'id',
    editable_columns => [ qw( username password firstname lastname email ) ],
    display_columns  => [ qw( username firstname lastname email ) ],
    deleteable => 1,
    editable => 1,
    sortable => 1,
    paginate => 100,
    template => 'users.tt',
    query_auto_focus => 0,
    downloadable => 1,
    custom_columns => {
        'Roles' => {
            raw_column => "id",
            transform  => sub {
                my $id         = shift;
                my $db         = database;
                my @user_roles = $db->quick_select( 'user_roles', { user_id => $id } );
                my @roles;

                map { my $role = $db->quick_select( 'roles', { id => $_->{role_id} } ); push( @roles, $role ); } @user_roles;

                my $roles;

                map { $roles .= '<a href="/roles?searchfield=user_id&searchtype=c&q=' . $id . '&o=&d=&searchsubmit=Search">' . $_->{role} . '</a>, ' } @roles;

                $roles = '<a href="/roles/add">Add a Role</a>' if ( ! $roles );

                return $roles;
            },
        },
    },
    auth => {
        view => {
            require_login => 1,
        },
        edit => {
            require_role => 'Administrator',
        },
    },
);

true;

__END__

=pod

=head1 NAME

LibreMailer::Users

=head1 DESCRIPTION

user management

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

