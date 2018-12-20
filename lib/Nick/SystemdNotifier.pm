package Nick::SystemdNotifier;

use strict;
use warnings;

use base 'Nick::StandardBase';

use IO::Socket::UNIX;

use Nick::Log;

$| = 1;

our( @ISA, $SYSTEMD );

=pod

=head1 NAME

Nick::SystemdNotifier - Adds systemd notification for daemons.

=head1 SYNOPSIS

    package ExampleClass;

    use Nick::SystemdNotifier;

    Nick::SystemdNotifier -> run( 'ExampleClass', 'arg1', 'arg2' );

    sub run {
        my( $class, @args ) = @_;
        # behave as a daemon
    }

    sub started {
        # call when daemon is operating
    }

=cut

sub run {
    my( $class, $base, @args ) = @_;
    exists( $ENV{'NOTIFY_SOCKET'} )
        or return $base -> run( @args );
    Nick::Log -> instance( 'date' => 0 );
    my $socket = $ENV{'NOTIFY_SOCKET'};
    substr( $socket, 0, 1 ) eq '@'
        and substr( $socket, 0, 1 ) = "\0";
    $SYSTEMD = IO::Socket::UNIX -> new(
        'Type' => SOCK_DGRAM(),
        'Peer' => $socket
    ) or $class -> throw(
        "Unable to open systemd socket '$socket': $!"
    );
    $SYSTEMD -> autoflush( 1 );
    push @ISA => $base;
    $class -> SUPER::run( @args );
}

sub started {
    my( $class ) = @_;
    $SYSTEMD -> print( 'READY=1' )
        or $class -> throw(
            'Unable to send ready to systemd socket ' . $!
        );
    $class -> SUPER::started();
}

sub status {
    my( $class, $message ) = @_;
    $SYSTEMD -> print( 'STATUS=' . $message )
        or $class -> throw(
            'Unable to send status to systemd socket ' . $!
        );
}

1;
