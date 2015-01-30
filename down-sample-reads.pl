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

my @alignments_file_list = @ARGV;

my $alignment_file = $alignments_file_list[0];
my $output_file    = "downsampled.sam";
my $fraction       = 0.2;

downsample_reads( $alignment_file, $output_file, $fraction );

exit;

sub downsample_reads {
    my ( $input_file, $output_file, $fraction ) = @_;

    my $cmd = "samtools view -Sh -s $fraction $input_file > $output_file";
    system($cmd);
}
