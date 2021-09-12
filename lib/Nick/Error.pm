package Nick::Error;

use strict;
use warnings;

use base 'Error';

$Error::ObjectifyCallback = sub {
    my( $args ) = @_;
    return Nick::Error -> new(
        Nick::Error -> _parse_die(
            $$args{'text'}, 3
        )
    );
};

=pod

=head1 NAME

Nick::Error - Inherits from and extends CPAN L<Error> module.

=head1 SYNOPSIS

    use 'Nick::Error' ':try'

    try {
        Nick::Error -> throw( 'error text' );
    } catch Nick::Error with {
        ( $error ) = @_;
        print $error -> stringify();
        $error -> rethrow( 'uhoh' );
    };

=head1 METHODS

=head2 rethrow()

Rethrows the current error, adding to the error message.

    $error -> rethrow( 'unable to blah' );

=head2 do_eval()

Eval given string, any errors are converted to an exception.

    Nick::Error -> do_eval( '1/0' );

=head2 die_throw()

Parse error message from a trapped die and throw as an exception.

Optionally supply text to prefix the error message.

    Nick::Error -> die_throw( $@, 'extra text' );

=head2 strings()

Convert error to die type string.

    printf "error: %s\n", $error -> strings();

=head2 text()

Get or set the text of an error.

    $error -> text( 'error message' );
    printf "error: %s\n", $error -> text();

=head2 type()

Get the type of an error.

    printf "type: %s\n", $error -> type();

=head2 error()

Log the error using Nick::Log.

Optionally supply text to prefix the error message.

    try {
        Nick::Error -> throw( 'error text' );
    } catch Nick::Error with {
        $_[0] -> error( 'extra text' );
    };

=cut

sub new {
    my $self = shift;
    my $text = shift;
    my %hash = (
        '-text' => $text,
        @_
    );
    local $Error::Depth =
        $Error::Depth
        + $self -> _add_depth()
        + (
            exists( $hash{'-depth'} )
            ? delete( $hash{'-depth'} )
            : 0
        );
#    local $Error::Debug = 1;
    return $self -> SUPER::new( %hash );
}

sub _add_depth {
    return 1;
}

sub do_eval {
    my( $class, $eval, $text, $depth ) = @_;
    my $got = eval $eval;
    return $got unless $@;
    my $error = $@;
    $error =~ s/ at \(eval \d+\) line \d+.\s*//s;
    $class -> die_throw(
        $error, $text || "eval( '$eval' )", $depth
    );
}

sub die_throw {
    my( $class, $error, $text, $depth ) = @_;
    my %hash;
    ( $error, %hash ) = $class -> _parse_die( $error, $depth );
    if ( $text ) {
        $error = "$text: $error";
    }
    if ( exists $hash{'-depth'} ) {
        $hash{'-depth'} ++;
    }
    $class -> throw( $error => %hash );
}

sub rethrow {
    my( $self, $msg ) = @_;
    $msg and $self -> text(
        $msg . ': ' . $self -> text()
    );
    $self -> throw();
}

sub stringify {
    return join( "\n",
        shift() -> strings(), ''
    );
}

sub strings {
    my( $self ) = @_;
    return sprintf(
        '%s in %s line %d.',
        $self -> SUPER::stringify(),
        $self -> file(),
        $self -> line()
    );
}

sub text {
    my( $self, $msg ) = @_;
    $msg and $$self{'-text'} = $msg;
    return $$self{'-text'};
}

sub type {
    return (
        exists( $_[0] -> {'-type'} )
        ? $_[0] -> {'-type'}
        : 'unknown type'
    )
}

sub error {
    my( $self, $msg ) = @_;
    $msg and $self -> text(
        $msg . ': ' . $self -> text()
    );
    require Nick::Log;
    my $log = Nick::Log -> instance();
    foreach (
        $self -> strings()
    ) {
        $log -> error( $_ );
    }
    return undef;
}

sub _parse_die {
    my $class = shift;
    my $text = shift || $@;
    my $depth = shift || 1;
    my %hash;
    if (
        $text
        &&
        ( $text = ( split /[\n\r\f]+/, $text )[0] )
        &&
        $text =~ s/\s+at\s+(\S+)\s+line\s+(\d+)(?:,\s*<[^>]*>\s+line\s+\d+)?\.?$//s
    ) {
        $hash{'-file'} = $1;
        $hash{'-line'} = $2;
    } else {
        $hash{'-depth'} = $depth;
    }
    return ( $text, %hash );
}

1;
