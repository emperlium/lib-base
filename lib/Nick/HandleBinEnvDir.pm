package Nick::HandleBinEnvDir;

use strict;
use warnings;

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
