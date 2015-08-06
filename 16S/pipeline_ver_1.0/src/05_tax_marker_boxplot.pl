#!/usr/bin/env perl
=pod
description: draw OTU tax stat figure
author: Wu Chunyan
created date: 20140826
=cut

use Getopt::Long;
use File::Basename qw(dirname basename);

my ($input, $prefix, $group, $marker, $help,);

GetOptions("input:s" => \$input, "prefix:s" => \$prefix, "group:s" => \$group, "marker:s" => \$marker, "help|?" => \$help);

if (!defined $input || !defined $prefix || !defined $group ||!defined $marker || defined $help) {
        print STDERR << "USAGE";
description: draw OTU tax stat figure
usage: perl $0 [options]
options:
        -input *: OTU table
	-group *: group table,"sample\\tgroup"
	-marker *: marker,"Tax\\tPvalue"
	-prefix *: prefix of output
        -help|?: print help information
USAGE
        exit 1;
}

my %group;
my @sample_sort;
open IN,$group || die $!;
while(<IN>){
	chomp;
	my @tabs=split/\t/,$_;
	$group{$tabs[0]}=$tabs[1];
	push @sample_sort,$tabs[0];
}
close IN;
my %marker;
open IN,$marker || die $!;
while(<IN>){
	chomp;
	my @tabs=split/\t/,$_;
	next if($tabs[0]=~/Other/ or $tabs[0]=~/__$/);
	my @names=split/;/,$tabs[0];
	my $name=pop @names;
	$marker{$name}=$tabs[1];
}
close IN;

open IN,$input || die "can not open $input\n";
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
	my @names=split/;/,$tab[0];
	my $tax=pop @names;
	next unless(defined $tax && exists $marker{$tax});
	my $percent;
	for (my $i=1;$i<@tab;$i++){
		next unless(exists $group{$samples{$i}});
		my $line= "$samples{$i}\t$tax\t".$tab[$i];
		$line.="\t$group{$samples{$i}}";
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

my $out="$prefix.marker.for_draw.xls";
my $out1="$prefix.marker.for_draw_top20.xls";
open OUT,">$out" || die "can not open $out\n";
open OUT1,">$out1" || die "can not open $out1\n";
print OUT "Sample\tTax\tPercent\tGroup\n";
print OUT1 "Sample\tTax\tPercent\tGroup\n";
my $i=0;
foreach my $tax(@tax_sort){
	$i++;
	foreach my $sample(@sample_sort){
		print OUT $outline{$sample}{$tax}."\n"; 
		next if($i>20);
		print OUT1 $outline{$sample}{$tax}."\n";
	}
	
}
close OUT;
close OUT1;
open R, ">$prefix.marker.boxplot.R" || die "can not open $prefix.marker.boxplot.R\n";
print R <<RTXT;
library(ggplot2)
library(grid)
data <- read.table("$prefix.marker.for_draw_top20.xls",header=TRUE,sep="\t")
data\$Sample <- factor(data\$Sample,levels=unique(data\$Sample))
data\$Tax <- factor(data\$Tax,levels=unique(data\$Tax))
pdf("$prefix.marker.boxplot.pdf",width=10, height=5)
p <-ggplot(data, aes(Tax,log2(Percent),fill=Group))
p+geom_boxplot(outlier.size=1)+theme(axis.text=element_text(colour="black"),axis.text.x  = element_text(angle=60, size=8,vjust=0.5))+scale_fill_discrete(name="Group",h=c(100,1000),c=100,l=60)+labs(title="",x="",y = "log2(Relative Abundance)")+theme(legend.position=c(0.85,0.70))
dev.off()
RTXT

system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.0.1/bin/R CMD BATCH $prefix.marker.boxplot.R $prefix.marker.boxplot.R.Rout");
system("/usr/bin/convert -density 300 $prefix.marker.boxplot.pdf $prefix.marker.boxplot.png");


