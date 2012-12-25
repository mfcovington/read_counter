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

my $usage = <<EOF;

    USAGE:
    $0
        --bam_dir       Directory containing .bam files [./]
        --out_dir       Output directory [./]
        --prefix        Filename prefix †
        --suffix        Filename suffix † [.bam]
        --alpha_only    Sort by sequence name ‡
        --num_only      Sort by number of counts ‡
        --verbose
        --help

        † A custom prefix/suffix combo can be used to restrict input files
        ‡ If no sorting options are chosen, two files are output for each
          input (one sorted by sequence name and the other by # of counts)

EOF

my $bam_dir = "./";
my $out_dir = "./";
my $prefix  = "";
my $suffix  = ".bam";
my ( $alpha_only, $num_only, $verbose, $help );

my $options = GetOptions(
    "bam_dir=s"  => \$bam_dir,
    "out_dir=s"  => \$out_dir,
    "prefix=s"   => \$prefix,
    "suffix=s"   => \$suffix,
    "alpha_only" => \$alpha_only,
    "num_only"   => \$num_only,
    "verbose"    => \$verbose,
    "help"       => \$help,
);

die $usage if $help;
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
        open my $out_alpha_fh, '>', "$out_dir/$bam.counts_a";
        say $out_alpha_fh "$_\t$gene_counts{$_}" for sort keys %gene_counts;
    }
    unless ($alpha_only) {
        open my $out_count_fh, '>', "$out_dir/$bam.counts_1";
        say $out_count_fh "$_\t$gene_counts{$_}"
          for sort { $gene_counts{$b} <=> $gene_counts{$a} } keys %gene_counts;
    }
}
