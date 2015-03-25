#!/usr/bin/env perl
# Mike Covington
# created: 2015-01-28
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';
use List::Util qw(min max sum);

use FindBin;
use lib "$FindBin::Bin";
use read_counter;

my @counts_file_list = @ARGV;
my @all_counts;

for my $counts_file (@counts_file_list) {
    my $counts       = import_counts($counts_file);
    my $total_counts = total_counts($counts);
    push @all_counts, $total_counts;
    counts_per_file( $counts_file, $total_counts );
}

say join "\t", "Min counts",  min @all_counts;
say join "\t", "Max counts",  max @all_counts;
say join "\t", "Mean counts", sprintf "%.0f",
    sum(@all_counts) / scalar @all_counts;

exit;
