package Nick::Log;

use strict;
use warnings;

use base 'Class::Singleton';

use Nick::Error;

our( %DEFAULTS, $AUTOLOAD, @LEVELS, %METHODS );

BEGIN {
    $| = 1;
    %DEFAULTS = qw(
        nl      1
        date    1
        process 0
    );
    @LEVELS = qw( debug info log warning error );
}

sub _new_instance {
    my( $class, %set ) = @_;
    for ( keys %DEFAULTS ) {
        exists( $set{$_} )
            and $DEFAULTS{$_} = $set{$_};
    }
    my $self = bless {} => $class;
    $self -> reset_output_method();
    $$self{'output_handler'} = $self -> _make_output_handler();
    $self -> reset_handlers();
    return $self;
}

sub AUTOLOAD {
    my( $self, @msg ) = @_;
    exists( $METHODS{$AUTOLOAD} )
        and &{ $METHODS{$AUTOLOAD} }( @msg );
}

sub reset_handlers {
    my( $self ) = @_;
    my $handler = $$self{'output_handler'};
    my $prefix = ref( $self ) . '::';
    for ( @LEVELS ) {
        $METHODS{ $prefix . $_ } = &$handler( $_ );
    }
}

sub set_type_handler {
    ref( $_[2] ) eq 'CODE'
        or Nick::Error -> throw(
            "Handler for type '$_[1]' should be a callback"
        );
    $_[0] -> {$_[1]} = $_[2];
}

sub reset_output_method {
    $_[0]{'output_method'} = sub {
        print @_;
    };
}

sub set_output_method {
    ref( $_[1] ) eq 'CODE'
        or Nick::Error -> throw(
            'Handler for output should be a callback'
        );
    $_[0]{'output_method'} = $_[1];
}

sub _make_output_handler {
    my $self = shift;
    my( $nl, $date, $process, %opt, @date );
    my $date_sub = sub {
        @date = ( localtime time )[ 3, 4, 5, 2, 1, 0 ];
        $date[1] ++;
        $date[2] %= 100;
        return sprintf(
            '[%02d/%02d/%02d %02d:%02d:%02d] ', @date
        );
    };
    my $output = sub {
        ( $nl, $date, $process ) = @DEFAULTS{ qw( nl date process ) };
        if (
            ref( $_[-1] ) eq 'ARRAY'
        ) {
            %opt = map { $_ => 1 } @{ pop() };
            $nl = 0 if exists( $opt{'no_nl'} );
            $date = 0 if exists( $opt{'no_date'} );
            $process = 0 if exists( $opt{'no_process'} );
        }
        return join( '',
            ( $date ? &$date_sub() : () ),
            ( $process ? "[$$] " : () ),
            join( ' ', @_ ),
            ( $nl ? "\n" : () )
        );
    };
    return sub {
        my $type = shift;
        my $header = (
            $type eq 'info' || $type eq 'log'
            ? ''
            : '[' . uc( $type ) . ']'
        );
        return sub {
            &{ $$self{'output_method'} }(
                &$output(
                    $header
                    ? ( $header, @_ )
                    : @_
                )
            );
        };
    };
}

sub options {
    my( $self, %set ) = @_;
    for ( keys %set ) {
        exists( $DEFAULTS{$_} )
            and $DEFAULTS{$_} = $set{$_};
    }
}

sub copy_to_file {
    my( $self, $file ) = @_;
    require IO::File;
    my $fh = IO::File -> new();
    $fh -> open( '>>' . $file )
        or Nick::Error -> throw(
            "Unable to append to log file '$file': $!"
        );
    $self -> log( 'Copying log to ' . $file );
    $self -> set_output_method(
        sub {
            print @_;
            $fh -> print( @_ );
        }
    );
}

1;
