use strict;
use warnings;

use Test::More 'tests' => 7;

BEGIN {
    use_ok 'Nick::SimpleDumper' => 'sdump';
}

is sdump( undef ) => 'undef', 'undefined value';
is sdump( 'hello' ) => 'hello', 'single value';
is sdump( \do{ 'scalar ref' } ) => '\{ scalar ref }', 'scalar reference';
is sdump( [ 4 .. 6 ] ) => '[ 4, 5, 6 ]', 'array reference';
is(
    sdump( { map { $_ => 1 } 7 .. 9 } ),
    '{ 7=1, 8=1, 9=1 }',
    'hash reference'
);
is(
    sdump( { map { $_ => [ 1, 2 ] } 7 .. 9 } ),
    '{ 7=[ 1, 2 ], 8=[ 1, 2 ], 9=[ 1, 2 ] }',
    'array nested hash reference'
);
