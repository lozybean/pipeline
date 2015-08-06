#!/usr/bin/env perl
=pod
description: draw Group OTU tax stat figure
author: Wu Chunyan
created date: 20140826
=cut

use Getopt::Long;
use File::Basename qw(dirname basename);

my ($input, $prefix, $group, $level, $help, $max);

GetOptions("input:s" => \$input, "prefix:s" => \$prefix, "group:s" => \$group, "level:s" => \$level, "help|?" => \$help ,"max:s" => \$max);

if (!defined $input || !defined $prefix || !defined $group ||!defined $level || defined $help) {
        print STDERR << "USAGE";
description: draw OTU tax stat figure
usage: perl $0 [options]
options:
        -input *: OTU table
	-group *: group table,"sample\tgroup"
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
my @group_sort;
my %group_temp;
open IN,$group || die $!;
while(<IN>){
	chomp;
	my @tabs=split/\t/,$_;
	$group{$tabs[0]}=$tabs[1];
	push @group_sort,$tabs[1] if(!exists $group_temp{$tabs[1]});
	$group_temp{$tabs[1]}=1;
}
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

my %tax_percent;
my %percent;

while(<IN>){
	chomp;
	my @tab=split/\t/,$_;
	my $tax;
	if($tab[0]=~/;(Other)$/){
		$tax=$1;
	}elsif($tab[0]=~/;[a-z]__$/){
		$tax="Other";
	}elsif($tab[0]=~/;[a-z]__([^;]+)$/){	
		$tax=$1;
	}
	my $percent;
	for (my $i=1;$i<@tab;$i++){
		next if(!exists $group{$samples{$i}});
		my $group=$group{$samples{$i}};
		$tax_percent{$group}{$tax}+=$tab[$i];
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
open OUT, ">$out" || die "can not open $out\n";
print OUT "Group\tTax\tPercent\n";
foreach my $group(@group_sort){
	my $total;
	foreach my $tax(keys %{$tax_percent{$group}}){
		$total+=$tax_percent{$group}{$tax};
	}
	foreach my $tax(keys %{$tax_percent{$group}}){
		$tax_percent{$group}{$tax}=$tax_percent{$group}{$tax}/$total*100;
	}
	my $top;
	my $total_tmp;
	foreach my $tax(@tax_sort){
		$top++;
		if($top<$max){
			if ($tax eq "Other"){
				$top--;
				next;
			}
			$total_tmp+=$tax_percent{$group}{$tax};
			print OUT "$group\t$tax\t$tax_percent{$group}{$tax}\n";
		}else{
			my $percent=100-$total_tmp;
			print OUT "$group\tOther\t$percent\n";
			last;
		}
	}
}
close OUT;
open R, ">$prefix.R" || die $!;
print R <<RTXT;
library(ggplot2)
library(grid)
data <- read.table("$prefix.for_draw.xls",header=TRUE,sep="\t")
data\$Group <- factor(data\$Group,levels=unique(data\$Group))
data\$Tax <- factor(data\$Tax,levels=unique(data\$Tax))
pdf("$prefix.pdf",width=6, height=7)
gg_normal <-  ggplot(data = data, aes(x = Group, y=Percent, fill = Tax,order=Group))
gg_normal + geom_bar(position = "stack",stat="identity")+theme(axis.text=element_text(colour="black"),axis.text.x  = element_text(angle=90, size=8,vjust=0.5))+scale_fill_discrete(name="$level",h=c(100,1000),c=100,l=60)+labs(title="",x = "",y = "")
dev.off()
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.0.1/bin/R CMD BATCH $prefix.R $prefix.R.Rout");
system("/usr/bin/convert -density 300 $prefix.pdf $prefix.png");
system("rm -f  $prefix.R $prefix.R.Rout");
