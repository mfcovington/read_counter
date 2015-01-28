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
use File::Path 'make_path';
use Getopt::Long;

my $usage = <<EOF;

    USAGE:
    $0
        --bam_dir        Directory containing .bam files [./]
        --out_dir        Output directory [./]
        --seq_list       File containing sequences to count (Default: all sequences)
        --no_zero        Ignore sequences with zero counts
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
my ( $consolidate, $seq_file, $no_zero, $alpha_only, $num_only, $verbose,
    $help );

my $options = GetOptions(
    "bam_dir=s"     => \$bam_dir,
    "out_dir=s"     => \$out_dir,
    "seq_file=s"    => \$seq_file,
    "no_zero"       => \$no_zero,
    "consolidate=s" => \$consolidate,
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

# consolidate similar samples/replicates, if applicable
if ( defined $consolidate ) {
    my %bam_patterns;
    for (@bam_file_list) {
        my ($group) = $_ =~ m|(.*\/[^\/]*?)\Q$consolidate\E[^\/]*|;
        $bam_patterns{$group}++;
    }
    @bam_file_list = sort keys %bam_patterns;
}

# get user-defined sequences, if applicable
my %seq_list;
if ( defined $seq_file ) {
    open my $seq_fh, '<', $seq_file;
    chomp( my @seqs = <$seq_fh> );
    close $seq_fh;
    $seq_list{$_}++ for @seqs;
    my $seq_count = scalar keys %seq_list;
    say "  Found $seq_count sequences in $seq_file" if $verbose;
    $seq_file =~ s|.*\/([^\/]*)|$1|;
}

for my $bam (@bam_file_list) {
    say "  Combining:  $bam" if $verbose && defined $consolidate;
    my @bam_group = glob "$bam*";
    my %gene_counts;

    # prime %gene_counts with zeros, unless --no_zero option used
    if ( defined $seq_file && !$no_zero ) {
        $gene_counts{$_} = 0 for keys %seq_list;
    }
    elsif ( !$no_zero ) {
        open my $header_fh, '-|', "samtools view -H $bam_group[0] |
          grep -e ^\@SQ | cut -f2 | cut -d: -f2";
        chomp( my @header = <$header_fh> );
        close $header_fh;
        $gene_counts{$_} = 0 for @header;
    }

    # count reads per sequence
    for (@bam_group) {
        say "  Processing: $_" if $verbose;
        open my $bam_fh, '-|', "samtools view $_";
        for my $line (<$bam_fh>) {
            my @elements = split /\s/, $line;
            next if defined $seq_file && !exists $seq_list{ $elements[2] };
            $gene_counts{ $elements[2] }++;
        }
        close $bam_fh;
    }

    # write to output file(s)
    make_path $out_dir;
    my ($id) = $bam =~ m|.*\/([^\/]*)(?(?{ !defined $consolidate; })\.bam)|;
    $id .= ".$seq_file" if defined $seq_file;
    unless ($num_only) {
        open my $out_alpha_fh, '>', "$out_dir/$id.counts_a";
        say $out_alpha_fh "$_\t$gene_counts{$_}" for sort keys %gene_counts;
        close $out_alpha_fh;
    }
    unless ($alpha_only) {
        open my $out_count_fh, '>', "$out_dir/$id.counts_1";
        say $out_count_fh "$_\t$gene_counts{$_}"
          for sort { $gene_counts{$b} <=> $gene_counts{$a} } keys %gene_counts;
        close $out_count_fh;
    }
}
