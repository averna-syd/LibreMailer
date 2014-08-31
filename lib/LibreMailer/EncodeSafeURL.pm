package LibreMailer::EncodeSafeURL;

use Moo;
use Dancer qw(:syntax !before !after);
use Dancer::Plugin::Database;
use MIME::Base64::URLSafe;
use Crypt::CBC;
use Crypt::Blowfish;
use Try::Tiny;
use Data::Dumper;

our $VERSION = '0.1';

sub encrypt_sting
{
    # Encrypt string for sending
    my $self   = shift;
    my $string = shift;
    my $cipher = Crypt::CBC->new(
      -key        => config->{url_key},
      -cipher     => 'Blowfish',
      -padding    => 'space',
      -add_header => 1
    );

    my $enc = $cipher->encrypt( $string  );

    return urlsafe_b64encode( $enc );
}

sub decrypt_string
{
    # Decrypt string for processing
    my $self   = shift;
    my $string = urlsafe_b64decode( shift );
    my $dec;
    my $cipher = Crypt::CBC->new(
      -key        => config->{url_key},
      -cipher     => 'Blowfish',
      -padding    => 'space',
      -add_header => 1
    );

    try{ $dec = $cipher->decrypt( $string ); };

    return $dec; 
}

1;

__END__

=pod

=head1 NAME

LibreMailer::EncodeSafeURL

=head1 DESCRIPTION

url encoding and encryption

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
