package Nick::StandardBase;

use strict;
use warnings;

our( $VERSION, $LOG );

BEGIN {
    $VERSION = '1.00';
}

sub _log {
    return(
        $LOG || do {
            require Nick::Log;
            $LOG = Nick::Log -> instance()
        }
    );
}

sub log {
    shift() -> _log() -> log( @_ );
}

sub info {
    shift() -> _log() -> info( @_ );
}

sub debug {
    shift() -> _log() -> debug( @_ );
}

sub error {
    shift() -> _log() -> error( @_ );
}

sub debug_dump {
    require Data::Dumper;
    shift() -> debug(
        Data::Dumper -> Dump( \@_ )
    );
}

sub simple_dump {
    shift;
    require Nick::SimpleDumper;
    return Nick::SimpleDumper::sdump( @_ );
}

sub throw {
    shift() -> caller_throw(
        shift(), 0, @_
    );
}

sub caller_try_throw {
    shift() -> caller_throw(
        shift(),
        ( shift() || 1 ) + 3,
        @_
    );
}

sub caller_throw {
    my( $self, $text, $depth, %hash ) = @_;
    require Nick::Error;
    Nick::Error -> throw(
        $text,
        %hash,
        '-depth' => (
            exists( $hash{'-depth'} )
                ? $hash{'-depth'}
                : 0
        ) + (
            $depth || 0
        ) + 2
    );
}

sub dump_caller {
    $_[0] -> _log();
    my @call;
    my $i = 0;
    $LOG -> log( 'Called by;' );
    while ( @call = caller( $i++ ) ) {
        $LOG -> log(
            sprintf '  %d: line %d, %s', $i, @call[ 2, 1 ]
        );
    }
}

sub eval_require {
    require Nick::Error;
    Nick::Error -> do_eval(
        'require ' . $_[1], undef, 2
    );
    return $_[1];
}

1;
