use Test::More tests => 5;
use strict;
use warnings;

# the order is important
use Dancer::Test;
use JSON::Any;
use Data::Dumper;

use LibreMailer::DateTime;

ok( my $datetime = LibreMailer::DateTime->new, 'New obj' );

isa_ok( $datetime, 'LibreMailer::DateTime' );

ok( my $dt = $datetime->current_datetime, 'current_datetime' );

ok( my $sql_dt = $datetime->sql_current_datetime, 'sql_current_datetime' );

ok( $datetime->convert_sqlt_to_dt( $sql_dt ), 'convert_sqlt_to_dt' );

ok( $datetime->convert_dt_to_sqlt( $dt ), 'convert_dt_to_sqlt' );

ok( $datetime->check_schedule( $sql_dt ), 'check_schedule'  );
