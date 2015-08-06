#!/usr/bin/env perl
use strict;
die "perl $0 <split.fa><drep.fa><otu.txt><out>" unless(@ARGV==4);
my($fa1,$fa2,$otu,$out)=@ARGV;
my %tags;
open IN,$fa1 or die $!;
$/ = '>';
<IN>;
while(<IN>){
	chomp;
	my @tab = split /\s+/;
	$tab[0]=~/(\S+)\_\w+$/;
	my $sample = $1;
	$tags{$sample}++;	
}
close IN;
my %singleton;
my %single;
open IN,$fa2 or die $!;
$/ = '>';
<IN>;
while(<IN>){
	chomp;
	my @tab = split /;/;
	next unless ($tab[1] eq "size=1");
	$tab[0]=~/(\S+)\_\w+$/;
	my $sample = $1;
	$singleton{$sample} ++;
	$single{$tab[0]} = $sample;
}
close IN;
my %tagsWithOutChimeras;
my %chimeras;
my %otu;
my %core;
open IN,$otu or die $!;
$/ = "\n";
while(<IN>){
	chomp;
	my @tab = split /\t/;
	shift @tab;
	my %o;my %oo;
	foreach my $i(@tab){
		$i=~/(\S+)\_\w+$/;
		my $sample =$1;
		#my $ss = substr($i,0,5);
		$o{$sample}++;
		#$oo{$ss}++;
		$tagsWithOutChimeras{$sample}++;
		$chimeras{$sample}++ if exists $single{$i};
	}
	my $n = keys %o;
	#my $nn = keys %oo;
	foreach my $s(sort keys %o){
		$otu{$s}++;
	}
}
close IN;


open OUT,">$out"or die $!;
print OUT "sample\ttags\tsingleton\tsingleton%\tchimeras\tchimeras%\tclean_tags\totus\n";
foreach my $sample(sort keys %tagsWithOutChimeras){
	chomp;
	$chimeras{$sample} += $tags{$sample} - $tagsWithOutChimeras{$sample} - $singleton{$sample};
	my $ratio1 = $singleton{$sample}/$tags{$sample}*100;
	my $ratio2 = $chimeras{$sample}/$tags{$sample}*100;
	print OUT "$sample\t$tags{$sample}\t$singleton{$sample}\t$ratio1\t$chimeras{$sample}\t$ratio2\t$tagsWithOutChimeras{$sample}\t$otu{$sample}\n";
}
close OUT;
