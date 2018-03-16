package Nick::HandleBinEnvDir;

use strict;
use warnings;

=pod

=head1 NAME

Nick::HandleBinEnvDir - Current library search path management.

=head1 SYNOPSIS

    use Nick::HandleBinEnvDir;

    BEGIN {
        Nick::HandleBinEnvDir -> handle( 'APP_HOME' );
    }

=head1 METHODS

=head2 handle()

Adds directory* + /lib to the library search path.

*If an environment variable exists with the name supplied as an argument (typically the application home), otherwise the value returned by get().

=head2 get()

Tries to work out the application home based on the script path.

=cut

sub handle {
    my( $class, $name ) = @_;
    if ( exists $ENV{$name} ) {
        substr( $ENV{$name}, -1 ) eq '/'
            or $ENV{$name} .= '/';
    } else {
        $ENV{$name} = $class -> get() || './';
    }
    unshift @INC => $ENV{$name} . 'lib';
}

sub get {
    my $dir = substr(
        $0, 0, rindex( $0, '/' ) + 1
    );
    $dir eq './'
        and return '../';
    $dir =~ s'bin/$'';
    return $dir;
}

1;
