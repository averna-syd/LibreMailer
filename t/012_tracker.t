use Test::More tests => 5;
use strict;
use warnings;

# the order is important
use LibreMailer::RestClient;
use Dancer::Test;
use JSON::Any;
use Data::Dumper;

my $j      = JSON::Any->new;
my $client = LibreMailer::RestClient->new( host => 'http://localhost:3000' );
my $url    = '/login';
my $data   = { username => 'admin', password => 'admin' };

my ( $code, $response ) = $client->request( 'POST', $url, $j->to_json( $data ) );
ok ( $code eq '200', "response expected: 200 response given: $code for POST $url" );

$url = '/t/open/U2FsdGVkX1-zXWiQRWvd1c2VGQuS2OR_/U2FsdGVkX19eXy0Eb0oPKBuEG5uzP_4c/open.gif';
( $code, $response ) = $client->request( 'GET', $url );
ok ( $code eq '200', "response expected: 200 response given: $code for GET $url" );

$url = '/t/link/U2FsdGVkX1-zXWiQRWvd1c2VGQuS2OR_/U2FsdGVkX19eXy0Eb0oPKBuEG5uzP_4c/U2FsdGVkX18ni-FQHhU2NaIfaP0mqyOd';
( $code, $response ) = $client->request( 'GET', $url );
ok ( $code eq '302', "response expected: 200 response given: $code for GET $url" );

$url = '/t/viewonline/U2FsdGVkX1-zXWiQRWvd1c2VGQuS2OR_/U2FsdGVkX19eXy0Eb0oPKBuEG5uzP_4c';
( $code, $response) = $client->request( 'GET', $url );
ok ( $code eq '200', "response expected: 200 response given: $code for GET $url" );

$url = '/t/unsubscribe/U2FsdGVkX1-zXWiQRWvd1c2VGQuS2OR_/U2FsdGVkX19eXy0Eb0oPKBuEG5uzP_4c';
( $code, $response) = $client->request( 'GET', $url );
ok ( $code eq '200', "response expected: 200 response given: $code for GET $url" );
