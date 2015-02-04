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
use lib "$FindBin::Bin";
use read_counter;

my $sam_file = $ARGV[0];
my ( $total, $mapped, $unmapped ) = count_reads_in_sam($sam_file);
say $total;
say $mapped;
say $unmapped;
