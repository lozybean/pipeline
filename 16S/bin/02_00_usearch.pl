#!/usr/bin/perl
use strict;
use FindBin qw($Bin $Script);
use lib "$Bin/../lib";
use Cwd 'abs_path';
use File::Basename qw(basename dirname);
use PGAP qw(parse_config);

my $in_file = shift @ARGV;
$in_file = abs_path($in_file) unless $in_file =~ /^\//;
my $out_path = dirname($in_file);
$out_path = "$out_path/usearch_out";
`mkdir -p $out_path`;

my ($usearch,$GG_fa,$GG_tax,$Gold,$uc2table,$fasta_number) = parse_config("$Bin/../config.txt","$Bin/../","usearch","greengene_97_otus","greengene_97_taxonomy","gold_otus","uc2table","fasta_number");

open OUT,">$out_path/../usearch.pipeline" or die $!;
print OUT<<CMD;
cp $in_file $out_path/00_original.fasta
$usearch -derep_fulllength $in_file -output $out_path/01_derep.fa -sizeout
$usearch -sortbysize $out_path/01_derep.fa -output $out_path/02_sorted.fa -minsize 1
$usearch -cluster_otus $out_path/02_sorted.fa -otus $out_path/03_otus_cluster.fa
$usearch -uchime_ref $out_path/03_otus1.fa -db $Gold -strand plus -nonchimeras $out_path/04_otu_nochimeras.fa
python $fasta_number $out_path/04_otu_nochimeras.fa denovo_ >$out_path/05_otus.fa
$usearch -usearch_global $out_path/00_original.fasta -db $out_path/05_otus.fa -strand plus -id 0.97 -uc $out_path/06_map.uc
perl $uc2table $out_path/06_map.uc $out_path/07_otu.table
CMD

close OUT;
