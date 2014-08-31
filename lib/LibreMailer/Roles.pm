package LibreMailer::Roles;

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
    record_title => 'Role',
    prefix => '/roles',
    db_table => 'user_roles',
    labels => {
        user_id => 'Username',
        role_id => 'Role',
        
    },
    input_types => {
        role_id   => 'select',
        user_id   => 'select',
    },
    required         => [ qw( role_id user_id ) ],
    key_column       => 'id',
    editable_columns => [ qw( role_id user_id ) ],
    display_columns  => [ qw( role_id user_id ) ],
    deleteable => 1,
    editable => 1,
    sortable => 1,
    paginate => 100,
    template => 'roles.tt',
    query_auto_focus => 0,
    downloadable => 1,
    foreign_keys => {
        role_id => {
            table => 'roles',
            key_column => 'id',
            label_column => 'role',
        },
        user_id => {
            table => 'users',
            key_column => 'id',
            label_column => 'username',
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

LibreMailer::Roles

=head1 DESCRIPTION

Does anyone even read this stuff?

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
