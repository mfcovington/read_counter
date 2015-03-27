# Read Counting Scripts

<!-- MarkdownTOC -->

- [Count number of reads mapped to each reference sequence](#count-number-of-reads-mapped-to-each-reference-sequence)
- [Summarize counts files](#summarize-counts-files)
- [Get quick, simple summary of mapped, unmapped, and total reads in SAM file](#get-quick-simple-summary-of-mapped-unmapped-and-total-reads-in-sam-file)

<!-- /MarkdownTOC -->

## Count number of reads mapped to each reference sequence

`counts_per_seq.pl` is a script that does the following: 

- Read through the BAM files in a directory
- Count the number of reads mapping to each reference sequence
- For each BAM file, write output file(s) with # of reads per sequence (sorted by sequence name and/or # of counts)

Usage:

    perl counts_per_seq.pl

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

## Summarize counts files

`count_summary.pl` is a script that does the following:

- Import multiple counts files created by `simple_counts.pl` or `counts_per_seq.pl`
- Output a summary:
    - Counts for each file
    - Minimum, maximum, and mean counts for set of files

Usage:

    perl count_summary.pl path/to/sample.counts ...

## Get quick, simple summary of mapped, unmapped, and total reads in SAM file

`count-reads-in-sam.pl` is a very simple script that takes a single SAM file and reports the numbers of mapped reads, unmapped reads, and total reads.

Usage:

    perl count-reads-in-sam.pl path/to/file.sam
