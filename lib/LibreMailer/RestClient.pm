package LibreMailer::RestClient;

# I just use this for testing. Feel free to ignore it.

use Moo;
use REST::Client;
use LWP::UserAgent;
use HTTP::Cookies;
use Data::Dumper;

our $VERSION = '1.0';

has host          => ( is => 'rw', default => sub { 'http://localhost:3000'; }, );
has cookie_file   => ( is => 'rw', default => sub { return '/tmp/.libre_lwp_cookies.dat'; }, );
has cookie_jar    => ( is => 'rw', default => \&_set_cookie_jar, );
has lwp_ua        => ( is => 'rw', default => \&_set_lwp_ua, );
has client        => ( is => 'rw', default => \&_set_rest_client, lazy => 1, );
has show_progress => ( is => 'rw', default => sub { 1; }, );

sub _set_cookie_jar
{
    my $self = shift;

    return HTTP::Cookies->new( file => $self->cookie_file, autosave => 1, );
}

sub _set_lwp_ua
{
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        cookie_jar => $self->cookie_jar,
        requests_redirectable => [ 'GET', 'HEAD', 'POST', 'PUT', 'DELETE' ]
    );

    $ua->show_progress( $self->show_progress );

    return $ua;
}

sub _set_rest_client
{
    my $self = shift;

    return REST::Client->new( { useragent => $self->lwp_ua } );
}

sub request
{
    my $self   = shift;
    my $type   = shift;
    my $url    = shift;
    my $data   = shift;
    my $c_type = shift;

    $c_type =
      ( !$c_type && $url && $url =~ m/json$/ )
      ? 'application/json'
      : 'text/html';

    $self->client->request( $type, $self->host . $url,
        $data, { "Content-type" => $c_type } );

    return ( $self->client->responseCode(), $self->client->responseContent() );
}

1;

__END__

=pod

=head1 NAME

LibreMailer::RestClient

=head1 DESCRIPTION

Just a rest client helper for testing.
Not part of app.

=head1 AUTHOR

Sarah Fuller, C<< <sarah at averna.id.au> >>

=head1 LICENSE AND COPYRIGHT

This file is part of LibreMailer.

LibreMailer is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

LibreMailer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with LibreMailer. If not, see <http://www.gnu.org/licenses/>.

=cut
