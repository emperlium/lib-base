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
