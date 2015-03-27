use strict;
use warnings;
use autodie;
use feature 'say';
use File::Basename;
use File::Path 'make_path';
use List::Util qw(min sum);

sub counts_per_file {
    my ( $counts_file, $total_counts ) = @_;
    say join "\t", $counts_file, $total_counts;
}

sub count_reads_in_sam {
    my ( $sam_file ) = @_;

    my $mapped   = 0;
    my $unmapped = 0;

    my $cmd = "samtools view -S $sam_file";
    open my $cmd_fh, "-|", $cmd;
    while (<$cmd_fh>) {
        if   (/^[^\t]+\t4\t\*\t/) { $unmapped++; }
        else                     { $mapped++; }
    }
    close $cmd_fh;

    my $total = $mapped + $unmapped;

    return $total, $mapped, $unmapped;
}

sub downsample_reads {
    my ( $input_file, $output_file, $fraction, $seed ) = @_;

    my ( $fraction_int, $fraction_dec ) = $fraction =~ /(-?\d+)?\.(\d+)/;
    $fraction_int //= 0;

    die <<EOF if $seed ne '' && $fraction_int > 0 && $seed != $fraction_int;
ERROR: Random seed has been set as $fraction_int (via '--fraction $fraction') and as $seed (via '--seed $seed').
       Please use a single method to set the random seed.
EOF

    my ( undef, $out_dir, undef ) = fileparse $output_file;
    make_path $out_dir;

    my $seed_fraction
        = $fraction_int == 0 ? "$seed.$fraction_dec" : $fraction;

    my $cmd
        = "samtools view -Sh -s $seed_fraction $input_file > $output_file";
    system($cmd);
}

sub import_counts {
    my $counts_file = shift;
    my %counts;

    open my $counts_fh, "<", $counts_file;
        while (<$counts_fh>) {
            chomp;
            my ( $gene, $depth ) = split /[\t,]/;

            next if $gene eq '*';

            $counts{$gene} = $depth;
        }
    close $counts_fh;

    return \%counts;
}

sub minimum_read_counts {
    my ( @sam_file_list ) = @_;

    my $min_total_reads    = "inf";
    my $min_mapped_reads   = "inf";
    my $min_unmapped_reads = "inf";
    for my $sam_file (@sam_file_list) {
        my ( $total, $mapped, $unmapped ) = count_reads_in_sam($sam_file);

        $min_total_reads    = min $total,    $min_total_reads;
        $min_mapped_reads   = min $mapped,   $min_mapped_reads;
        $min_unmapped_reads = min $unmapped, $min_unmapped_reads;
    }

    return $min_total_reads, $min_mapped_reads, $min_unmapped_reads;
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
