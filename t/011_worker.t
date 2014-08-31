use Test::More tests => 2;
use strict;
use warnings;

# the order is important
use Dancer::Test;
use JSON::Any;
use Data::Dumper;

use LibreMailer::Worker;

ok( my $worker = LibreMailer::Worker->new, 'New obj' );

isa_ok( $worker, 'LibreMailer::Worker' );
