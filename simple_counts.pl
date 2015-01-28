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

my ( $sam, $verbose, $help );
my $out_dir = '.';
my $threads = 1;

my $options = GetOptions(
    "out_dir=s" => \$out_dir,
    "threads=i" => \$threads,
    "sam"       => \$sam,
    "verbose"   => \$verbose,
    "help"      => \$help,
);

my @alignment_file_list = @ARGV;

validate_options( \@alignment_file_list, $sam, $threads, $help );

my $pm = Parallel::ForkManager->new($threads);
for my $alignment_file (@alignment_file_list) {
    $pm->start and next;

    say STDERR "Processing $alignment_file" if $verbose;

    my $counts = get_counts( $alignment_file, $sam );
    my $counts_file = name_counts_file( $alignment_file, $out_dir );

    make_path $out_dir;
    write_counts( $counts, $counts_file );

    $pm->finish;
}
$pm->wait_all_children;

exit;

sub get_counts {
    my ( $alignment_file, $sam ) = @_;
    my %counts;

    my $alignment_fh;
    if ($sam) {
        open $alignment_fh, "<", $alignment_file;
    }
    else {
        open $alignment_fh, "-|", "samtools view -H $alignment_file";
    }

    while (<$alignment_fh>) {
        if (/^@/) {    # Set count to 0 for all genes in header
            $counts{$1} = 0 if /\@SQ\tSN:(.+)\tLN:\d+/;
            next;
        }

    }

    close $alignment_fh;

    return \%counts;
}

sub name_counts_file {
    my ( $alignment_file, $out_dir ) = @_;
    my $counts_file;

    return $counts_file;
}

sub usage {
    return <<EOF;

Usage: $0 [options] <Alignment file(s)>

Options:
  -o, --out_dir           Output directory [.]
  -s, --sam               Alignment files are in SAM format (Default is BAM)
  -t, --threads           Number of files to process simultaneously [1]
  -v, --verbose           Report current progress
  -h, --help              Display this usage information

EOF
}

sub validate_options {
    my ( $alignment_file_list, $sam, $threads, $help ) = @_;

    my @errors;

    for (@$alignment_file_list) {
        push @errors, "File '$_' not found" unless -e $_;
        if ($sam) {
            push @errors, "File '$_' is not a .sam file" unless /.+\.sam$/;
        }
        else {
            push @errors, "File '$_' is not a .bam file" unless /.+\.bam$/;
        }
    }

    push @errors, "Option '--threads' must be an integer greater than 0"
        if $threads <= 0;

    if (@errors) {
        my $error_string = join "\n", map {"ERROR: $_"} @errors;
        die usage(), $error_string, "\n\n";
    }
    elsif ($help) {
        die usage();
    }
}

sub write_counts {
    my ( $counts, $alignment_file, $out_dir ) = @_;

}
