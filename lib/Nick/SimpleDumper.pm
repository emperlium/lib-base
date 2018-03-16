package Nick::SimpleDumper;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw( sdump );

=pod

=head1 NAME

Nick::SimpleDumper - Convert complex data sctructure into a string.

=head1 SYNOPSIS

    use Nick::SimpleDumper 'sdump';

    my $data = {
        'array' => [ 1 .. 3 ],
        'scalar' => 'text',
        'ref' => \do{ 'scalar ref' }
    };

    print sdump( $data ), "\n";

=cut

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
