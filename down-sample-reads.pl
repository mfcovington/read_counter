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
use File::Path 'make_path';
use Getopt::Long;

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

make_path $out_dir;
downsample_reads( $alignment_file, $output_file, $fraction, $seed );

exit;

sub downsample_reads {
    my ( $input_file, $output_file, $fraction, $seed ) = @_;

    my ( $fraction_int, $fraction_dec ) = $fraction =~ /(-?\d+)?\.(\d+)/;
    $fraction_int //= 0;

    die <<EOF if $seed ne '' && $fraction_int > 0 && $seed != $fraction_int;
ERROR: Random seed has been set as $fraction_int (via '--fraction $fraction') and as $seed (via '--seed $seed').
       Please use a single method to set the random seed.
EOF

    my $seed_fraction
        = $fraction_int == 0 ? "$seed.$fraction_dec" : $fraction;

    my $cmd
        = "samtools view -Sh -s $seed_fraction $input_file > $output_file";
    system($cmd);
}
