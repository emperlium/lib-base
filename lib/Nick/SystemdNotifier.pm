package Nick::SystemdNotifier;

use strict;
use warnings;

use base 'Nick::StandardBase';

use IO::Socket::UNIX;

$| = 1;

our( @ISA, $SYSTEMD );

sub run {
    my( $class, $base, @args ) = @_;
    exists( $ENV{'NOTIFY_SOCKET'} )
        or return $base -> run( @args );
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
