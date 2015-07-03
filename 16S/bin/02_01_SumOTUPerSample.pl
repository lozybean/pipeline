#!/usr/bin/perl
use strict;

chomp(my $Bin=`pwd`);
my ($original,$derep,$otu_table,)

my %tags;
open IN,$original or die $!;
$/ = '>';
<IN>;
while(<IN>){
	chomp;
	/(\S+?)_/;
	$tags{$1}++;	
}
close IN;
my %singleton;
my %single;
open IN,"/data_center_03/Project/TH2014I15A03-1/ITS_1/01_pick_otus/test/derep.fa" or die $!;
$/ = '>';
<IN>;
while(<IN>){
	chomp;
	my @tab = split /;/;
	next unless ($tab[1] eq "size=1");
	$tab[0] =~ /(\S+?)_/;
	my $sample = $1;
	$singleton{$sample} ++;
	$single{$tab[0]} = $sample;
}
close IN;
my %tagsWithOutChimerasDownsize;
my %tagsWithOutChimeras;
my %chimeras;
my %chimeras_downsize;
my %otu;
my %otu_downsize;
my %core;
my %core_downsize;
=cut
open IN,"otus_downsize.table" or die $!;
$/ = "\n";
while(<IN>){
	chomp;
	my @tab = split /\s+/;
	my $denovo = shift @tab;
	my %o;my %oo;
	foreach my $i(@tab){
		my $sample = substr($i,0,5);
		$o{$sample}++;
		$tagsWithOutChimerasDownsize{$sample}++;
		$chimeras_downsize{$sample}++ if exists $single{$i};
	}
	my $n = keys %o;
	$core_downsize{$denovo}++ if ($n>=100);
	foreach my $s(sort keys %o){
		$otu_downsize{$s}++;
	}
}
close IN;
=cut
open IN,"otus.table" or die $!;
$/ = "\n";
while(<IN>){
        chomp;
        my @tab = split /\s+/;
        my $denovo = shift @tab;
        my %o;my %oo;
        foreach my $i(@tab){
                my $sample = substr($i,0,5);
                $o{$sample}++;
                $tagsWithOutChimeras{$sample}++;
                $chimeras{$sample}++ if exists $single{$i};
        }
        my $n = keys %o;
        $core{$denovo}++ if ($n>=100);
        foreach my $s(sort keys %o){ 
                $otu{$s}++;
        }
}
close IN;
=cut
open OUT,">sample_OTU_downsize.txt" or die $!;
print OUT "sample\ttags\tsingleton\tsingleton%\tchimeras\tchimeras%\tclean_tags\tdownsize_num\totus\n";
foreach my $sample(sort keys %tagsWithOutChimerasDownsize){
	chomp;
	my $downsize_num = $tagsWithOutChimeras{$sample} - $tagsWithOutChimerasDownsize{$sample};
	$chimeras_downsize{$sample} += $tags{$sample} - $tagsWithOutChimerasDownsize{$sample} - $singleton{$sample} - $downsize_num;
	my $ratio1 = $singleton{$sample}/$tags{$sample};
	my $ratio2 = $chimeras_downsize{$sample}/$tags{$sample};
	print OUT "$sample\t$tags{$sample}\t$singleton{$sample}\t$ratio1\t$chimeras_downsize{$sample}\t$ratio2\t$tagsWithOutChimerasDownsize{$sample}\t$downsize_num\t$otu_downsize{$sample}\n";
}
close OUT;
=cut
open OUT,">$Bin/sample_OTU.xls" or die $!;
print OUT "sample\ttags\tsingleton\tsingleton%\tchimeras\tchimeras%\tclean_tags\totus\n";
foreach my $sample(sort keys %tagsWithOutChimeras){
	chomp;
	$chimeras{$sample} += $tags{$sample} - $tagsWithOutChimeras{$sample} - $singleton{$sample};
	my $ratio1 = $singleton{$sample}/$tags{$sample};
	my $ratio2 = $chimeras{$sample}/$tags{$sample};
	print OUT "$sample\t$tags{$sample}\t$singleton{$sample}\t$ratio1\t$chimeras{$sample}\t$ratio2\t$tagsWithOutChimeras{$sample}\t$otu{$sample}\n";
}
close OUT;
open OUT,">$Bin/coreOTU.list" or die $!;
foreach my $denovo(sort keys %core){
	print OUT "$denovo\n";
}
=cut
open OUT,">coreOTU_downsize.list" or die $!;
foreach my $denovo(sort keys %core_downsize){
	print OUT "$denovo\n";
}
close OUT;
=cut
