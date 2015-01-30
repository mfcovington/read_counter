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

my $options = GetOptions(
    "out_dir=s"  => \$out_dir,
    "fraction=f" => \$fraction,
);

my @alignments_file_list = @ARGV;

my $alignment_file = $alignments_file_list[0];
my $output_file    = "$out_dir/downsampled.sam";

make_path $out_dir;
downsample_reads( $alignment_file, $output_file, $fraction );

exit;

sub downsample_reads {
    my ( $input_file, $output_file, $fraction ) = @_;

    my $cmd = "samtools view -Sh -s $fraction $input_file > $output_file";
    system($cmd);
}
