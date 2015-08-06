#! /usr/bin/env perl
=pod
description: draw sample OTU tax stat figure
author: Wu Chunyan
created date: 20140826
=cut

use Getopt::Long;
use File::Basename qw(dirname basename);

my ($input, $prefix, $group, $level, $help, $max);

GetOptions("input:s" => \$input, "prefix:s" => \$prefix, "sample:s" => \$sample, "level:s" => \$level, "help|?" => \$help ,"max:s" => \$max);

if (!defined $input || !defined $prefix || !defined $sample ||!defined $level || defined $help) {
        print STDERR << "USAGE";
description: draw OTU tax stat figure
usage: perl $0 [options]
options:
        -input *: OTU table
	-sample*: sample list file, sample ID each row
	-level *: Tax Classify level, choose one from "Kingdom,Phylum,Class,Order,Family,Genus,Species"
	-max    : The number of tax for draw, default is 20
	-prefix *: prefix of output
        -help|?: print help information
USAGE
        exit 1;
}

my @levels = ('Kingdom','Phylum','Class','Order','Family','Genus','Species');
$level = $levels[$level - 1];


$max ||= 20;
my %group;
my @sample_sort;
open IN,$sample || die $!;
while(<IN>){
	chomp;
	my @tabs=split/\t/,$_;
	$group{$tabs[0]}=$tabs[1];
	push @sample_sort,$tabs[0];
}
#foreach my $sample(sort{$group{$a} cmp $group{$b}} keys %group){
#	push @sample_sort,$sample;
#}
close IN;
open IN,$input || die "can not open $input\n";
<IN>;
my $head=<IN>;
chomp ($head);
my @samples=split/\t/,$head;
shift @samples;
my %samples;
for (my $i=0;$i<@samples;$i++){
	my $j=$i+1;
	$samples{$j}=$samples[$i];
}

my %outline;
my %percent;

while(<IN>){
	chomp;
	my @tab=split/\t/,$_;
	my $tax=$1;
	if($tab[0]=~/;(Other)$/){
		$tax=$1;
	}elsif($tab[0]=~/;[a-z]__$/){
		$tax="Other";
	}elsif($tab[0]=~/;[a-z]__([^;]+)$/){	
		$tax=$1;
	}
	my $percent;
	for (my $i=1;$i<@tab;$i++){
		my $line= "$samples{$i}\t$tax\t".$tab[$i]*100;
		$outline{$samples{$i}}{$tax}=$line;
		$percent+=$tab[$i];
	}
	$percent{$tax}=$percent;
}
close IN;

my @tax_sort;
foreach my $tax(sort {$percent{$b} <=> $percent{$a}} keys %percent) {
	push @tax_sort,$tax;
}

my $out="$prefix.for_draw.xls";
open OUT,">$out" || die "can not open $out\n";
print OUT "Sample\tTax\tPercent\n";
foreach my $sample(@sample_sort){
	my $top;
	foreach my $tax(@tax_sort){
		$top++;
		last if($top>20);
		print OUT $outline{$sample}{$tax}."\n";
	}
	
}
close OUT;

open R, ">$prefix.R" || die "can not open $prefix.R\n";
print R <<RTXT;
library(ggplot2)
library(grid)
data <- read.table("$prefix.for_draw.xls",header=TRUE,sep="\t")
data\$Sample <- factor(data\$Sample,levels=unique(data\$Sample))
data\$Tax <- factor(data\$Tax,levels=unique(data\$Tax))
pdf("$prefix.pdf",width=18, height=8)
library(RColorBrewer)
group=read.table("$sample",header=F,row.names=1)
#rownames(X)=sub("X","",rownames(X))
library(WGCNA)
cols=labels2colors(group,colorSeq=2:8)

#col=colorRampPalette(brewer.pal(8, "Dark2"))(8)
#cols=c(rep(3,21),rep(4,13),rep(2,10))
gg_normal <-  ggplot(data = data, aes(x = Sample, y=Percent,fill=Tax,order=Sample))
gg_normal + geom_bar(position = "stack",stat="identity")+theme(axis.text=element_text(colour="black"),axis.text.x  = element_text(angle=90,vjust=0.5,color=cols),axis.text.y  = element_text(size=15))+scale_fill_discrete(name="$level",h=c(100,1000),c=100,l=60)+labs(title="",x = "",y = "")#+scale_fill_manual(values=cols)
dev.off()
RTXT

system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH $prefix.R $prefix.R.Rout");
system("/usr/bin/convert -density 300 $prefix.pdf $prefix.png");
#system("rm -f $prefix.R $prefix.R.Rout");


