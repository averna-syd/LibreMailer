package LibreMailer;

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
use LibreMailer::DateTime;
use LibreMailer::Tracker;
use LibreMailer::Contacts;
use LibreMailer::Lists;
use LibreMailer::Users;
use LibreMailer::Roles;
use LibreMailer::Campaigns;
use LibreMailer::Statistics;
use LibreMailer::Worker;

our $VERSION = '0.1';

set VERSION => $VERSION;
set YEAR    => LibreMailer::DateTime->new()->current_datetime->year;

hook before => sub
{
    # Bunch of BS catch all ugly rubbish.
    my $params = params;

    if ( ! session('logged_in_user') && request->path_info !~ m{^/login|/t/} )
    {
        var requested_path => request->path_info;
        request->path_info('/login');
    }

    my $id         = session('user_id');
    my $admin_only = '/users/add|/users/edit|/roles/add|/roles/edit';

    if ( ! session('admin') && request->path_info =~ m{^$admin_only} && request->path_info !~ m{^/users/edit/$id} )
    {
        return redirect '/denied';
    }

    if ( session('logged_in_user') && request->path_info =~ m{/campaigns/(edit|delete)/(\d)+} )
    {
        my $id       = $2;
        my $db       = database;
        my $campaign = $db->quick_select( 'campaigns', { id => $id } );

        if ( $campaign->{sending} =~ m{yes}i || $campaign->{sent} =~ m{yes}i )
        {
            flash error        => "Permission Denied.";
            session denied_msg => 'You can not edit or delete a campaign that is currently sending or has already been sent.';

            return redirect '/denied';
        }
    }

    if ( session('logged_in_user') && request->path_info =~ m{/(lists|contacts)/(edit|delete)} && ! user_has_role('Manage Contacts') && ! user_has_role('Administrator') )
    {
        flash error        => "Permission Denied.";
        session denied_msg => 'You can not modify lists or contacts without the "Manage Contacts" or "Administrator" role.';

        return redirect '/denied';
    }

    if ( session('logged_in_user') && request->path_info =~ m{/campaigns/(edit|delete)} && ! user_has_role('Manage Campaigns') && ! user_has_role('Administrator') )
    {
        flash error        => "Permission Denied.";
        session denied_msg => 'You can not modify campaigns without the "Manage Contacts" or "Administrator" role.';

        return redirect '/denied';
    }

    if ( session('logged_in_user') && request->path_info =~ m{/users/(add|edit)} )
    {
        my $db   = database;
        my $user = $db->quick_select( 'users', { username => $params->{username} } );

        if ( $user->{id} && ( ( $params->{username} && ! $params->{id} ) || ( $params->{id} ne $user->{id} ) ) )
        {
            flash error        => "A user with username $params->{username} already exists.";
            session denied_msg => 'You can not add/edit a user and give them a username that already exists.';

            return redirect '/denied';
        }
    }

    if ( session('logged_in_user') && request->path_info =~ m{/roles/(add|edit)} )
    {
        my $db   = database;
        my $role = $db->quick_select( 'user_roles', { user_id => $params->{user_id}, role_id => $params->{role_id} } );

        if ( $role->{id} && ( $role->{user_id} eq $params->{user_id} ) && ( $role->{role_id} eq $params->{role_id} ) && ( $params->{id} ne $role->{id} ) )
        {
            flash error        => "Role for this user already exists.";
            session denied_msg => 'You can not add a role to a user when that role already exists.';

            return redirect '/denied';
        }
    }

    if ( session('logged_in_user') && request->path_info =~ m{/campaigns/(add|edit)} )
    {
        my $db       = database;
        my $campaign = $db->quick_select( 'campaigns', { name => $params->{name} } );

        if ( $campaign->{id} && ( ( $params->{name} && ! $params->{id} ) || ( $params->{id} ne $campaign->{id} ) ) )
        {
            flash error        => "A campaign with the name $params->{name} already exists.";
            session denied_msg => 'You can not add/edit a campaign and give it a name that already exists.';

            return redirect '/denied';
        }
    }
};

hook add_edit_row_pre_save => sub 
{
    # Ensure we don't screw up password field & flash with pretty name.
    my $row = shift;
    my $db  = database;

    if ( $row->{table_name} eq 'users' && $row->{params}->{password} !~ m/^{CRYPT}/ )
    {
        $row->{params}->{password} = passphrase( $row->{params}->{password} )->generate;
    }

    my $name =  $row->{table_name};

    $name =~ s/^([a-z])/\u$1/;
    $name =~ s/user_roles/Roles/gi;

    flash success => "Saved $name";
};

get '/login' => sub
{
    # Well, what the hell do you think this does?!?!
    session->destroy;

    template 'login', {};
};

post '/login' => sub
{
    # Login page YAY!
    my $params = params;
    my $db     = database;
    my $user   = $db->quick_select( 'users', { username => $params->{username} } );

    if ( $user->{id} )
    {
        if ( passphrase( $params->{password} )->matches( $user->{password} ) )
        {
            my $admin    = $db->quick_select( 'roles', { role => 'Administrator' } );
            my $is_admin = ( $db->quick_count( 'user_roles', { role_id => $admin->{id}, user_id => $user->{id} } ) )
                         ? 1
                         : 0;

            session logged_in_user       => $user->{username};
            session logged_in_user_realm => 'users';
            session admin                => $is_admin;
            session user_id              => $user->{id};
            session username             => $user->{username};
            session firstname            => $user->{firstname};
            session lastname             => $user->{lastname};
            session email                => $user->{email};

            session->flush();

            return redirect '/';
        }
    }

    flash error => 'Login failed.';

    return template 'login', {};
};

any '/' => sub
{
    # Redeict default route to campaigns cos I'm lazy and don't want to make any more pages.
    return redirect '/campaigns';
};

any '/denied' => sub
{
    # Our catch all YOU'RE DENIED for some reason.
    template 'denied', {};
};

any [ 'get', 'post' ] => '/logout' => sub
{
    # This logs the user out, SURPRISE! :)
    session->destroy;

    return redirect '/login';
};

any qr{.*}xms => sub
{
    # Catch all 404 page.
    if ( request->path_info =~ m{(?:json|xml)$}xmsi )
    {
        return status_not_found('Not found');
    }

    return template '404', {};
};

true;

__END__

=pod

=head1 NAME

LibreMailer

=head1 DESCRIPTION

Main web application module.

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
