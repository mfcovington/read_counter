use strict;
use warnings;
use autodie;
use feature 'say';
use List::Util 'sum';

sub counts_per_file {
    my ( $counts_file, $total_counts ) = @_;
    say join "\t", $counts_file, $total_counts;
}

sub import_counts {
    my $counts_file = shift;
    my %counts;

    open my $counts_fh, "<", $counts_file;
        while (<$counts_fh>) {
            chomp;
            my ( $gene, $depth ) = split /[\t,]/;
            $counts{$gene} = $depth;
        }
    close $counts_fh;

    return \%counts;
}

sub total_counts {
    my $counts = shift;
    return sum values %$counts;
}

1;
