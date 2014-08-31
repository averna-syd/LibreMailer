use Test::More tests => 4;
use strict;
use warnings;

# the order is important
use Dancer::Test;
use JSON::Any;
use Data::Dumper;

use LibreMailer::EncodeSafeURL;

ok( my $encode = LibreMailer::EncodeSafeURL->new, 'New obj' );

isa_ok( $encode, 'LibreMailer::EncodeSafeURL' );

ok( my $string = $encode->encrypt_sting( 'hello' ), 'encrypt_sting' );

ok( $encode->decrypt_string( $string ), 'decrypt_string' );
