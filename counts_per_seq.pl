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
use Getopt::Long;

my $usage = <<EOF;

    USAGE:
    $0
        --bam_dir        Directory containing .bam files [./]
        --out_dir        Output directory [./]
        --seq_list       File containing sequences to count (Default: all sequences)
        --consolidate    Delimiter between Sample ID and Rep ID *
        --prefix         Filename prefix †
        --suffix         Filename suffix † [.bam]
        --alpha_only     Sort by sequence name ‡
        --num_only       Sort by number of counts ‡
        --verbose
        --help

        * Optionally used to consolidate related samples. For example,
          to consolidate 'sample_1.rep_1.bam' and 'sample_1.rep_2.bam',
          use: "--consolidate ."
        † A custom prefix/suffix combo can be used to restrict input files
        ‡ If no sorting options are chosen, two files are output for each
          input (one sorted by sequence name and the other by # of counts)

EOF

my $bam_dir = "./";
my $out_dir = "./";
my $prefix  = "";
my $suffix  = ".bam";
my ( $consolidate, $seq_file, $alpha_only, $num_only, $verbose, $help );

my $options = GetOptions(
    "bam_dir=s"     => \$bam_dir,
    "out_dir=s"     => \$out_dir,
    "consolidate=s" => \$consolidate,
    "seq_file=s"    => \$seq_file,
    "prefix=s"      => \$prefix,
    "suffix=s"      => \$suffix,
    "alpha_only"    => \$alpha_only,
    "num_only"      => \$num_only,
    "verbose"       => \$verbose,
    "help"          => \$help,
);

die $usage if $help;
die
"  ERROR: Can't sort 'alphabetically only' AND 'numerically only' at the same time.\n"
  if $alpha_only && $num_only;

my @bam_file_list = glob "$bam_dir/$prefix*$suffix";

if ( defined $consolidate ) {
    my %bam_groups;
    for (@bam_file_list) {
        my ($group) = $_ =~ m|(.*\/[^\/]*?)\Q$consolidate\E[^\/]*|;
        $bam_groups{$group}++;
    }
    @bam_file_list = sort keys %bam_groups;
}

my %seq_list;
if ( defined $seq_file ) {
    open my $seq_fh, '<', $seq_file;
    chomp( my @seqs = <$seq_fh> );
    $seq_list{$_}++ for @seqs;
    my $seq_count = scalar keys %seq_list;
    say "  Found $seq_count sequences in $seq_file" if $verbose;
}

for my $bam (@bam_file_list) {
    say "  Combining:  $bam" if $verbose && defined $consolidate;
    my %gene_counts;
    for ( glob "$bam*" ) {
        say "  Processing: $_" if $verbose;
        open my $bam_fh, '-|', "samtools view $_";
        for my $line (<$bam_fh>) {
            my @elements = split /\s/, $line;
            next unless defined $seq_file && exists $seq_list{ $elements[2] };
            $gene_counts{ $elements[2] }++;
        }
    }
    my ($id) = $bam =~ m|.*\/([^\/]*)(?(?{ !defined $consolidate; })\.bam)|;
    $id .= ".$seq_file" if defined $seq_file;
    unless ($num_only) {
        open my $out_alpha_fh, '>', "$out_dir/$id.counts_a";
        say $out_alpha_fh "$_\t$gene_counts{$_}" for sort keys %gene_counts;
    }
    unless ($alpha_only) {
        open my $out_count_fh, '>', "$out_dir/$id.counts_1";
        say $out_count_fh "$_\t$gene_counts{$_}"
          for sort { $gene_counts{$b} <=> $gene_counts{$a} } keys %gene_counts;
    }
}
