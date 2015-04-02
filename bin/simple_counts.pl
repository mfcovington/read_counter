#!/usr/bin/env perl
# Mike Covington
# created: 2015-01-27
#
# Description:
#
use strict;
use warnings;
use Log::Reproducible;
use autodie;
use feature 'say';
use File::Path 'make_path';
use Getopt::Long;
use Parallel::ForkManager;

use FindBin;
use lib "$FindBin::Bin/../lib";
use read_counter;

my ( $csv, $verbose, $help );
my $out_dir = '.';
my $threads = 1;

my $options = GetOptions(
    "out_dir=s" => \$out_dir,
    "threads=i" => \$threads,
    "csv"       => \$csv,
    "verbose"   => \$verbose,
    "help"      => \$help,
);

my @alignment_file_list = @ARGV;

validate_options( \@alignment_file_list, $threads, $help );

my $pm = Parallel::ForkManager->new($threads);
for my $alignment_file (@alignment_file_list) {
    $pm->start and next;

    say STDERR "Processing $alignment_file" if $verbose;

    my $counts = get_counts($alignment_file);
    my $counts_file = name_counts_file( $alignment_file, $out_dir );

    make_path $out_dir;
    write_counts( $counts, $counts_file, $csv );

    $pm->finish;
}
$pm->wait_all_children;

exit;

sub get_counts {
    my $alignment_file = shift;
    my %counts;

    my $alignment_fh;
    if ( $alignment_file =~ /.+\.sam$/i ) {
        open $alignment_fh, "<", $alignment_file;
    }
    elsif ( $alignment_file =~ /.+\.bam$/i ) {
        open $alignment_fh, "-|", "samtools view -h $alignment_file";
    }
    else {    # Should never happen because validate_options()
        die "File '$alignment_file' is not a .sam/.bam file\n";
    }

    while (<$alignment_fh>) {
        if (/^@/) {    # Set count to 0 for all genes in header
            $counts{$1} = 0 if /\@SQ\tSN:(.+)\tLN:\d+/;
            next;
        }

        my $gene = (split)[2];
        next if $gene =~ /^\*$/;    # skip unmapped reads
        $counts{$gene}++;
    }

    close $alignment_fh;

    return \%counts;
}

sub usage {
    return <<EOF;

Usage:
    perl $0 [options] <Alignment file(s)>

Options:
  -o, --out_dir    Output directory [.]
  -c, --csv        Output comma-delimited file (Default is tab-delimited)
  -t, --threads    Number of files to process simultaneously [1]
  -v, --verbose    Report current progress
  -h, --help       Display this usage information

EOF
}

sub validate_options {
    my ( $alignment_file_list, $threads, $help ) = @_;

    my @errors;

    push @errors, "Must specify at least one .sam/.bam file"
        unless @$alignment_file_list;

    for (@$alignment_file_list) {
        push @errors, "File '$_' not found" unless -e $_;
        push @errors, "File '$_' is not a .sam/.bam file"
            unless /.+\.[sb]am$/i;
    }

    push @errors, "Option '--threads' must be an integer greater than 0"
        if $threads <= 0;

    if ($help) {
        die usage();
    }
    elsif (@errors) {
        my $error_string = join "\n", map {"ERROR: $_"} @errors;
        die usage(), $error_string, "\n\n";
    }
}
