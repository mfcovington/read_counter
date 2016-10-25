#!/usr/bin/env perl
# Mike Covington
# created: 2016-10-25
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';
use Getopt::Long;
use List::Util 'sum';

my ( $transcripts_file, $help );
my $append = "merged-transcripts";

my $options = GetOptions(
    "transcripts_file=s" => \$transcripts_file,
    "append=s"           => \$append,
    "help=s"             => \$help,
);

my @counts_file_list = @ARGV;

my $usage = <<USAGE;

Usage:
    perl merge-counts-from-alternative-transcripts.pl \\
        --transcripts_file <Tab-delimited file with Gene IDs and Transcript IDs> \\
        --append <String to append to new counts files; Default: "merged-transcripts">

USAGE

die $usage unless defined $transcripts_file && scalar @ARGV > 0;
die $usage if $help;

my %transcripts;
open my $transcripts_fh, "<", $transcripts_file;
<$transcripts_fh>;
while (<$transcripts_fh>) {
    chomp;
    my ( $gene_id, $transcript_id ) = split;
    $transcripts{$transcript_id} = $gene_id;
}
close $transcripts_fh;

for my $counts_file (@counts_file_list) {
    my %gene_counts;

    open my $counts_fh, "<", $counts_file;
    while (<$counts_fh>) {
        chomp;
        my ( $transcript_id, $count ) = split;
        my $gene_id = $transcripts{$transcript_id};
        $gene_counts{$gene_id} = [] unless exists $gene_counts{$gene_id};
        push @{ $gene_counts{$gene_id} }, $count;
    }
    close $counts_fh;

    open my $merged_fh, ">", "$counts_file.$append";
    for my $gene_id ( sort keys %gene_counts ) {
        say $merged_fh join "\t", $gene_id, mean( $gene_counts{$gene_id} );
    }
    close $merged_fh;
}

sub mean {
    my $counts = shift;
    return sum(@$counts) / scalar @$counts;
}
