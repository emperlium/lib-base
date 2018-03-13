use strict;
use warnings;

use Test::More 'tests' => 5;

our( $LOG, $GOT );

BEGIN {
    use_ok 'Nick::Log';
}

$LOG = Nick::Log -> instance(qw(
    nl      0
    date    0
    process 0
));
$LOG -> set_output_method(
    sub {
        ( $GOT ) = @_;
    }
);

$LOG-> log( 'test log' );
is $GOT => 'test log';

$LOG-> error( 'test error' );
is $GOT => '[ERROR] test error';

$LOG -> set_type_handler(
    'debug' => sub {
        $GOT = 'prefix:' . $_[0];
    }
);
$LOG -> debug( 'test' );
is $GOT => 'prefix:test';

$LOG -> options( 'process' => 1 );
$LOG -> log( 'test process' );
is $GOT => "[$$] test process";
