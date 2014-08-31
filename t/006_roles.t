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

$url = '/roles';
( $code, $response ) = $client->request( 'GET', $url );
ok ( $code eq '200', "response expected: 200 response given: $code for GET $url" );

$url = '/roles/add';
( $code, $response ) = $client->request( 'GET', $url );
ok ( $code eq '200', "response expected: 200 response given: $code for GET $url" );

$url = '/roles/edit/1';
( $code, $response) = $client->request( 'GET', $url );
ok ( $code eq '200', "response expected: 200 response given: $code for GET $url" );

$url = '/roles/delete/1';
( $code, $response) = $client->request( 'GET', $url );
ok ( $code eq '200', "response expected: 200 response given: $code for GET $url" );

