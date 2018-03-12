use strict;
use warnings;

use Test::More 'tests' => 8;

BEGIN {
    use_ok 'Nick::Error' => ':try';
}

my $error;

try {
    Nick::Error -> throw(
        'error text',
        '-type' => 'test'
    );
} catch Nick::Error with {
    ( $error ) = @_;
    is $error -> text() => 'error text';
    is $error -> type() => 'test';
    is_deeply(
        $error, bless {
            '-line' => 13,
            '-file' => 't/Nick-Error.t',
            '-text' => 'error text',
            '-package' => 'main',
            '-type' => 'test'
        } => 'Nick::Error'
    );
};

try {
    die 'catch die';
} catch Nick::Error with {
    ( $error ) = @_;
    is $error -> text() => 'catch die';
    is $error -> type() => 'unknown type';
    is $error -> strings() => 'catch die in t/Nick-Error.t line 33.';
};

try {
    Nick::Error -> do_eval( '1/0' );
} catch Nick::Error with {
    ( $error ) = @_;
    is $error -> text() => q{eval( '1/0' ): Illegal division by zero};
};
