#!/usr/bin/env perl
# Mike Covington
# created: 2015-02-02
#
# Description:
#
use strict;
use warnings;
use Log::Reproducible;
use autodie;
use feature 'say';
use File::Basename;
use List::Util qw(min);

use FindBin;
use lib "$FindBin::Bin";
use read_counter;

my @sam_file_list = @ARGV;

my $out_dir = 'downsampled';
my $seed    = '';
my $verbose = 1;

say "Counting reads in SAM files" if $verbose;
my $reads_per_sam;
my $min_total_reads = "inf";
for my $sam_file (@sam_file_list) {
    my ($total_reads) = count_reads_in_sam($sam_file);
    $$reads_per_sam{$sam_file} = $total_reads;
    $min_total_reads = min $total_reads, $min_total_reads;
}

for my $sam_file (@sam_file_list) {
    my ( $filename, undef, undef ) = fileparse( $sam_file, qr/\.sam/ );
    my $fraction = sprintf "%.3f",
        $min_total_reads / $$reads_per_sam{$sam_file};
    my $output_file = "$out_dir/$filename-$fraction.sam";
    say "Downsampling from $sam_file to $output_file" if $verbose;
    downsample_reads( $sam_file, $output_file, $fraction, $seed );
}

