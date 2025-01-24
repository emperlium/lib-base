package Nick::Log;

use strict;
use warnings;

use base 'Class::Singleton';

use Nick::Error;

our( %DEFAULTS, $AUTOLOAD, @LEVELS, %METHODS, $OUTPUT_METHOD );

BEGIN {
    $| = 1;
    %DEFAULTS = qw(
        nl      1
        date    1
        process 0
    );
    @LEVELS = qw( debug info log warning error );
}

=pod

=head1 NAME

Nick::Log - General purpose logging module.

=head1 SYNOPSIS

    use Nick::Log

    my $log = Nick::Log -> instance();

    $log -> info( 'info message' );
    $log -> error( 'error message' );

=head1 DESCRIPTION

A singleton logging module with optional process id, date and output overide options.

=head1 METHODS

=head2 instance()

Nick::Log instance constructor.

All parameters are optional.

    $log = Nick::Log -> instance(
        # entries are terminated with a newline
        # default:1
        'nl' => 1,
        # entries copntain a [date]
        # default:1
        'date' => 1,
        # entries copntain a [process_id]
        # default:0
        'process' => 0
    );

=head2 debug() info() log() warning() error()

Create a log entry at the level of the method name used.

    $log -> info( 'info message' );
    $log -> info( 'info', 'message' );

Methods other than B<info()> and B<log()> will include a B<[METHOD]> section.

The arguments will be joined with a space as the log body.

If the last argument is a reference to a array, the strings B<no_nl>, B<no_date> or B<no_process> will suppress those options for this log.

    $log -> info( 'processing...', [ 'no_nl' ] );
    $log -> info( ' done' );

Methods B<warning()> and B<error()> return undef, all others return 1.

=head2 set_type_handler()

Set a callback to handle a specific log level handler.

    $log -> set_type_handler(
        'debug' => sub { warn $_[0]; }
    );

=head2 reset_handlers()

Reset all log level handlers.

=head2 set_output_method()

Set the output callback for all log levels.

    $log -> set_output_method(
        sub { print $_[0]; }
    );

=head2 reset_output_method()

Reset output callback for all log levels.

=head2 options()

Persistently set an option value.

See B<instance()> method for available options.

    $log -> options( 'process' => 1 );

=head2 copy_to_file()

Echo all log entries to a file.

    $log -> copy_to_file( '/tmp/log.txt' );

=cut

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
    substr $AUTOLOAD, 0, rindex( $AUTOLOAD, ':' ) + 1, '';
    return(
        $AUTOLOAD && exists( $METHODS{$AUTOLOAD} )
        ? &{ $METHODS{$AUTOLOAD} }( @msg )
        : undef
    );
}

sub reset_handlers {
    my( $self ) = @_;
    my $handler = $$self{'output_handler'};
    for ( @LEVELS ) {
        $METHODS{$_} = &$handler( $_ );
    }
}

sub set_type_handler {
    ref( $_[2] ) eq 'CODE'
        or Nick::Error -> throw(
            "Handler for type '$_[1]' should be a callback"
        );
    $METHODS{ $_[1] } = $_[2];
}

sub reset_output_method {
    $OUTPUT_METHOD = sub {
        print @_;
    };
}

sub set_output_method {
    ref( $_[1] ) eq 'CODE'
        or Nick::Error -> throw(
            'Handler for output should be a callback'
        );
    $OUTPUT_METHOD = $_[1];
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
            &$OUTPUT_METHOD(
                &$output(
                    $header
                    ? ( $header, @_ )
                    : @_
                )
            );
            return(
                $type eq 'error' || $type eq 'warning'
                ? undef
                : 1
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
