#!/usr/bin/env perl
# Mike Covington
# created: 2015-02-02
#
# Description:
#
use strict;
use warnings;
use Log::Reproducible;
use autodie;
use feature 'say';
use File::Basename;
use Getopt::Long;
use List::Util qw(min);
use Pod::Usage;

use FindBin;
use lib "$FindBin::Bin/../lib";
use read_counter;

=head1 TITLE

down-sample-reads-auto.pl - Down-sample reads in bulk w/ auto-calc'd fractions

=head1 SYNOPSIS

perl down-sample-reads-auto.pl [options] <Alignment file(s)>

=head1 DESCRIPTION

Given a list of SAM files, automatically down-sample reads to match the lowest coverage

=head1 OPTIONS AND ARGUMENTS

  -o, --out_dir     Output directory [.]
  -s, --seed        Random seed for down-sampling [0 aka -1]
  -v, --verbose     Report current progress
  -h, -?, --help    Display information about usage, options, and arguments
  -m, --man         Display man page

=cut

my $message_text = "ERROR: Must specify random seed\n";

my ( $verbose, $help, $man );
my $out_dir = '.';
my $seed    = '';

GetOptions(
    "out_dir=s" => \$out_dir,
    "seed=i"    => \$seed,
    "verbose"   => \$verbose,
    "help|?"    => \$help,
    "man"       => \$man
) or pod2usage( -verbose => 1 );

my @sam_file_list = @ARGV;

validate_options( \@sam_file_list, $help, $man );

say "Counting reads in SAM files" if $verbose;
my $reads_per_sam;
my $min_total_reads = "inf";
for my $sam_file (@sam_file_list) {
    my ($total_reads) = count_reads_in_sam($sam_file);
    $$reads_per_sam{$sam_file} = $total_reads;
    $min_total_reads = min $total_reads, $min_total_reads;
}

for my $sam_file (@sam_file_list) {
    my ( $filename, undef, undef ) = fileparse( $sam_file, qr/\.sam/ );
    my $fraction = sprintf "%.3f",
        $min_total_reads / $$reads_per_sam{$sam_file};
    my $output_file = "$out_dir/$filename-$fraction.sam";
    say "Downsampling from $sam_file to $output_file" if $verbose;
    downsample_reads( $sam_file, $output_file, $fraction, $seed );
}

exit;

sub validate_options {
    my ( $sam_file_list, $help, $man ) = @_;

    my @errors;

    push @errors, "Must specify at least two SAM files"
        if scalar @$sam_file_list < 2;

    for (@$sam_file_list) {
        push @errors, "File '$_' not found" unless -e $_;
        push @errors, "File '$_' is not a .sam file"
            unless /.+\.sam$/i;
    }

    if ($man) {
        pod2usage( -exitval => 0, -verbose => 2 );
    }
    elsif ($help) {
        pod2usage( -verbose => 1 );
    }
    elsif (@errors) {
        my $error_string = join "\n", map {"ERROR: $_"} @errors;
        pod2usage(
            -exitval => 255,
            -message => $error_string,
            -verbose => 1
        );
    }
}
