package Nick::SimpleDumper;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw( sdump );

sub sdump {
    if (
        ! @_
    ) {
        return '';
    } elsif (
        @_ > 1
    ) {
        return join( ', ',
            map sdump( $_ ), @_
        )
    } elsif (
        ref( $_[0] )
    ) {
        if (
            ref( $_[0] ) eq 'ARRAY'
        ) {
            return '[ '
                . sdump( @{ $_[0] } )
            . ' ]';
        } elsif (
            ref( $_[0] ) eq 'HASH'
        ) {
            return '{ '
                . sdump(
                    map(
                        "$_=" . sdump( $_[0]{$_} ),
                        sort keys( %{ $_[0] } )
                    )
                )
            . ' }';
        } elsif (
            ref( $_[0] ) eq 'SCALAR'
        ) {
            return '\{ ' . ${ $_[0] } . ' }';
        } else {
            return ref( $_[0] );
        }
    } elsif (
        defined $_[0]
    ) {
        return $_[0];
    } else {
        return 'undef'
    }
}

1;
