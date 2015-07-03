#!/usr/bin/perl
use strict;
use warnings;

die "$0 <pe1> <pe2> <concatenated_sequence.fq> <fna> <output_dir> <output>" unless @ARGV == 6;

my $sampleid = $ARGV[3];
$sampleid =~ s/.*\/([^\/]+)\.fna$/$1/;

-e -d $ARGV[4] || mkdir $ARGV[4];

open FQ1, "$ARGV[0]" or die $!;
my $fq1_number = 0;
my $fq1_base = 0;
while(<FQ1>){
	unless(/^\@/){
		  die "your fastaq file, $ARGV[0], is strange, line $. of pe1 doesn't start with >\n";
	}
	
	my $seq = <FQ1>;
	$fq1_number++;
	$fq1_base += (length($seq) - 1);
	
	<FQ1>;
	<FQ1>; 
}
close FQ1;

open FQ2, "$ARGV[1]" or die $!;
my $fq2_number = 0;
my $fq2_base = 0;
while(<FQ2>){
    unless(/^\@/){
          die "your fastaq file, $ARGV[1], is strange, line $. of pe2 doesn't start with >\n";
    }
    
    my $seq = <FQ2>;
    $fq2_number++;
    $fq2_base += (length($seq) - 1);
    
    <FQ2>;
    <FQ2>; 
}
close FQ2;

if ($fq1_number != $fq2_number){
	die "$ARGV[0] and $ARGV[1] don't have the same number of lines\n";
}

open FQ, "$ARGV[2]" or die $!;
my $fq_number = 0;
my $fq_base = 0;
while(<FQ>){
    unless(/^\@/){
          die "your fastaq file, $ARGV[2], is strange, line $. of pe2 doesn't start with >\n";
    }
    
    my $seq = <FQ>;
    $fq_number++;
    $fq_base += (length($seq) - 1);
    
    <FQ>;
    <FQ>; 
}
close FQ;

open FNA, "$ARGV[3]" or die $!;
my $fna_number = 0;
my $fna_base = 0;
my @len;
while(<FNA>){
    unless(/^>/){
          die "your fasta file, $ARGV[3], is strange, line $. doesn't start with >\n";
    }
    
    my $seq = <FNA>;
    $fna_number++;
    my $len = length($seq) - 1;
    push @len, $len;
    $fna_base += $len;
}
close FNA;

my $aver = $fna_base / $fna_number;
my $sum = 0;
foreach my $va (@len){
	$sum += ($va - $aver)**2;
}

my $sd = ($sum / ($fna_number - 1))**0.5;

open OUT, ">$ARGV[4]/$ARGV[5]" or die $1;
print OUT "sample_ID\tmiseq_read_number\tpe1_bases\tpe2_bases\tpandaseq_reads\tpandaseq_bases\tconcatenation_ratio\tfinal_reads\tfinal_bases\taverage_length\tsd\tfinal_useful_ratio\t\n";
print OUT "$sampleid\t$fq1_number\t$fq1_base\t$fq2_base\t$fq_number\t$fq_base\t", $fq_number / $fq1_number, "\t$fna_number\t$fna_base\t$aver\t$sd\t", $fna_number / $fq1_number, "\n";
close OUT;
