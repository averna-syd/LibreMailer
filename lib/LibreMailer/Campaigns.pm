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
    record_title => 'Campaign',
    prefix => '/campaigns',
    db_table => 'campaigns',
    labels => {
        list_id      => 'Contact List',
    },
    input_types => {
        list_id         => 'select',
        name            => 'text',
        email_reply_to  => 'text',
        subject         => 'text',
        text_body       => 'textarea',
        html_body       => 'textarea',
        send            => 'text',
        scheduled       => 'text',
        send            => 'select', 
    },
    required         => [ qw( list_id name email_reply_to subject text_body html_body scheduled send ) ],
    key_column       => 'id',
    editable_columns => [ qw( list_id name email_reply_to subject text_body html_body scheduled send ) ],
    display_columns  => [ qw( list_id name email_reply_to subject send sending sent scheduled ) ],
    deleteable => 1,
    editable => 1,
    sortable => 1,
    paginate => 100,
    template => 'campaigns.tt',
    query_auto_focus => 0,
    downloadable => 1,
    default_value => {
        html_body => &default_html_template,
        text_body => &default_text_template,
    },
    foreign_keys => {
        list_id => {
            table => 'lists',
            key_column => 'id',
            label_column => 'name',
        },
    },
);

sub default_html_template
{
return <<EOF;
<html>
<body bgcolor="#2D2D2D">
<table width="100%" height="100%" align="center" border="0" cellpadding="0" cellspacing="0" bgcolor="#2D2D2D">
        <tbody>
                <tr>
                        <td valign="top" height="50">
                        <table align="center" border="0" cellpadding="0" cellspacing="0" width="600">
                          <tbody>
                                <tr>
                                        <td valign="top"><font color="#ffffff" face="Helvetica, Arial, sans-serif" size="6">My Company<br></font><br></td>
                                </tr>
                           </tbody>
                          </table>
                        </td>
                </tr>
                <tr>
                        <td valign="top">
                        <table align="center" border="0" cellpadding="40" cellspacing="0" width="600" bgcolor="#ffffff">
                          <tbody>
                                <tr>
                                        <td valign="top">
<p style="text-align: center;"><font color="#5a5a5a" face="Helvetica, Arial, sans-serif" size="2">Having trouble viewing this email? Try <a href="[% viewonline %]">viewing it online</a>.</font></p>
<br><br>
<font color="#5a5a5a" face="Helvetica, Arial, sans-serif" size="3">Hi [% firstname %],<br><br>

<a href="http://www.google.com/">Google</a>.<br><br>
<a href="http://www.youtube.com/">YouTube</a>.<br><br>

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris eu rutrum justo. Fusce massa odio, blandit eu molestie in, commodo a lorem. Cras facilisis mi diam. Sed sit amet auctor magna, sit amet facilisis sapien. Nam fermentum odio eu eros porta, ut fermentum orci maximus. Quisque sem lorem, fermentum et convallis et, consectetur at enim. Sed quis laoreet sapien. Etiam sit amet dolor vitae nulla facilisis egestas varius vel eros. Maecenas blandit, sapien et pulvinar tincidunt, sem nunc pulvinar mauris, id viverra diam velit ut justo. Donec et dapibus augue. Nam ullamcorper est sit amet neque hendrerit accumsan.</font>
<br><br><br><br><br><br><br><br>
<p style="text-align: center;"><font color="#5a5a5a" face="Helvetica, Arial, sans-serif" size="2"><a href="[% unsubscribe %]">Unsubscribe</a></font></p>
</font></td>
                                </tr>
                           </tbody>
                          </table>
                        <br><br><br><br>
                        </td>
                </tr>
        </tbody>
</table>
</body>
</html>
EOF
}

sub default_text_template
{
return <<EOF;
Having trouble viewing this email? Try viewing it online: [% viewonline %]

My Company

Hi [% firstname %],

Google: http://www.google.com/
YouTube: http://www.youtube.com/

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris eu rutrum justo. Fusce massa odio, blandit eu molestie in, commodo a lorem. Cras facilisis mi diam. Sed sit amet auctor magna, sit amet facilisis sapien. Nam fermentum odio eu eros porta, ut fermentum orci maximus. Quisque sem lorem, fermentum et convallis et, consectetur at enim. Sed quis laoreet sapien. Etiam sit amet dolor vitae nulla facilisis egestas varius vel eros. Maecenas blandit, sapien et pulvinar tincidunt, sem nunc pulvinar mauris, id viverra diam velit ut justo. Donec et dapibus augue. Nam ullamcorper est sit amet neque hendrerit accumsan.



unsubscribe: [% unsubscribe %]
EOF
}

true;

__END__

=pod

=head1 NAME

LibreMailer::Campaigns

=head1 DESCRIPTION

Campaign management

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
