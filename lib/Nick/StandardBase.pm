package Nick::StandardBase;

use strict;
use warnings;

our( $VERSION, $LOG );

BEGIN {
    $VERSION = '1.00';
}

=pod

=head1 NAME

Nick::StandardBase - Commonly used methods to be inherited.

=head1 SYNOPSIS

    use base 'Nick::StandardBase';

    my $uri = main -> eval_require( 'URI' ) -> new();
    main -> error( 'error message' );
    main -> throw( 'fatal error' );

=head1 METHODS

=head2 debug() info() log() error()

Calls the L<Nick::Log> methods of the same name.

    Nick::StandardBase -> info( 'info message' );

=head2 debug_dump()

Dumps arguments with L<Data::Dumper> and outputs result in L<Nick::Log> debug.

    Nick::StandardBase -> debug_dump( $var1, $var2 );

=head2 simple_dump()

Dumps arguments with L<Nick::SimpleDumper> and returns result.

    print Nick::StandardBase -> simple_dump( $var1, $var2 ), "\n";

=head2 throw()

Throws a L<Nick::Error> exception.

    Nick::StandardBase -> throw( 'fatal error' );

=head2 caller_throw()

Throws an L<Nick::Error> exception as if it came from the caller of the current code.

    Nick::StandardBase -> caller_throw( 'fatal error' );

The caller depth can be adjusted with the option second argument.

    Nick::StandardBase -> caller_throw( 'fatal error', 1 );

Subsequent arguments will be treated as a hash that the L<Nick::Error> exception will be instantiated with.

    Nick::StandardBase -> caller_throw( 'fatal error', 0, '-type' => 'timeout' );

=head2 dump_caller()

Iterates throw the callers of the current code, logging each with L<Nick::Log>.

    Nick::StandardBase -> dump_caller()

=head2 eval_require()

Attempts to require the module in the supplied string, returns the string successful, otherwise throws a L<Nick::Error> exception.

    my $uri = Nick::StandardBase -> eval_require( 'URI' ) -> new();

=cut

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
