#!/usr/bin/env perl
# Mike Covington
# created: 2015-02-02
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';

use FindBin;
use lib "$FindBin::Bin/../lib";
use read_counter;

my $sam_file = $ARGV[0];
die "Must specify a SAM file.\n" unless $sam_file =~ /.+\.sam/i;

my ( $total, $mapped, $unmapped ) = count_reads_in_sam($sam_file);

print <<SUMMARY;
SAM file: $sam_file
Mapped:   $mapped
Unmapped: $unmapped
Total:    $total
SUMMARY
