use strict;
use warnings;
use autodie;
use feature 'say';
use File::Basename;
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

sub name_counts_file {
    my ( $input_file, $out_dir ) = @_;
    my $sample = fileparse( $input_file, qr/[sb]am/i );

    return "$out_dir/${sample}counts";
}

sub total_counts {
    my $counts = shift;
    return sum values %$counts;
}

sub write_counts {
    my ( $counts, $counts_file, $csv ) = @_;

    open my $counts_fh, ">", $counts_file;
    for my $gene ( sort keys %$counts ) {
        my $delimiter = $csv ? ',' : "\t";
        say $counts_fh join $delimiter, $gene, $$counts{$gene};
    }
    close $counts_fh;
}

1;
