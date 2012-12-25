#!/usr/bin/env perl
# counts_per_seq.pl
# Mike Covington
# created: 2012-12-21
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';
use Data::Printer;
use Getopt::Long;

my $bam_dir = "./";
my $out_dir = "./";
my $prefix  = "";
my $suffix  = ".bam";
my ( $alpha_only, $num_only, $verbose );

my $options = GetOptions(
    "bam_dir=s"  => \$bam_dir,
    "out_dir=s"  => \$out_dir,
    "prefix=s"   => \$prefix,
    "suffix=s"   => \$suffix,
    "alpha_only" => \$alpha_only,
    "num_only"   => \$num_only,
    "verbose"    => \$verbose,
);

die
"  ERROR: Can't sort 'alphabetically only' AND 'numerically only' at the same time.\n"
  if $alpha_only && $num_only;

my @bam_files = glob "$bam_dir/$prefix*$suffix";

for (@bam_files) {
    say "  Processing: $_" if $verbose;
    my ($bam) = $_ =~ m|.*\/([^\/]*)\.bam|;
    my %gene_counts;
    open my $bam_fh, '-|', "samtools view $_";
    for my $line (<$bam_fh>) {
        my @elements = split /\s/, $line;
        $gene_counts{ $elements[2] }++;
    }
    unless ($num_only) {
        open my $out_alpha_fh, '>', "$bam.counts_a";
        say $out_alpha_fh "$_\t$gene_counts{$_}" for sort keys %gene_counts;
    }
    unless ($alpha_only) {
        open my $out_count_fh, '>', "$bam.counts_1";
        say $out_count_fh "$_\t$gene_counts{$_}"
          for sort { $gene_counts{$b} <=> $gene_counts{$a} } keys %gene_counts;
    }
}
