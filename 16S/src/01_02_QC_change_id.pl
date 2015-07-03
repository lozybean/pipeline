### this script aims to remove the pandaseq-concatenated sequences with average quality less than a cutoff
### at the same time, change the sequence id to the form as qiime split library steps. the output will be in fasta format

#!/usr/bin/perl
use warnings;
use strict;

die "$0 <concatenated.fq> <average_quality_value_cutoff_system+Qvalue> <max_N> <min_length> <max_length> <output>" unless @ARGV == 6;

my $fq = $ARGV[0];
$fq =~ s/.*\/([^\/]+)\.fq$/$1/;
$fq =~ s/^([0-9]+)$/SSS$1/;

open FQ, "$ARGV[0]" or die $!;
open FNA, ">$ARGV[5]" or die $!;
my $seqcount = 0;
while (<FQ>){
	my $seq = <FQ>;
	my @N_number = ($seq =~ /N/g);
	if(@N_number > $ARGV[2]){
		<FQ>;
		<FQ>;
		next;
	}
	<FQ>;
	my $qual = <FQ>;
	
	chomp($qual);
	my $len = length($qual);
	
	if($len < $ARGV[3] or $len > $ARGV[4]){
		next;
	}
	
	my $qualsum = 0;
	my $seq1 = $seq;
	while(my $character = chop $seq1){
		$qualsum += ord($character);
	}
	my $ave = $qualsum /$len;
	
	if($ave >= ($ARGV[1])){
		$seqcount++;
		
		print FNA ">${fq}_$seqcount\n$seq";
	}
}
close FNA;
close FQ;


