#!/usr/bin/env perl
# Mike Covington
# created: 2015-01-29
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';
use Getopt::Long;

use FindBin;
use lib "$FindBin::Bin/../lib";
use read_counter;

my $fraction;
my $out_dir = '.';
my $seed    = '';

my $options = GetOptions(
    "out_dir=s"  => \$out_dir,
    "fraction=s" => \$fraction,
    "seed=i"     => \$seed,
);

my @alignments_file_list = @ARGV;

my $alignment_file = $alignments_file_list[0];
my $output_file    = "$out_dir/downsampled.sam";

downsample_reads( $alignment_file, $output_file, $fraction, $seed );

exit;
