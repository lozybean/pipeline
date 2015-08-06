#!/usr/bin/env perl 
=pod
description: venn
author: Wu Leyun
created date: 20150305
=cut

use Getopt::Long;
use File::Basename qw(dirname basename);


my ($otu, $group,$gnum, $help);

GetOptions("otu:s" => \$otu, "group:s" => \$group,"gnum:s" => \$gnum,"help|?" => \$help);

if (!defined $otu || !defined $group ||!defined $gnum || defined $help) {
                print STDERR << "USAGE";
description: alpha test and boxplot
usage: perl $0 [options]
options:
        -otu *: otu.txt
        -group *: group table,"sample\\tgroup"
        -gnum *:num "2 3 4 5"
        -help|?: print help information
USAGE
        exit 1;
}


my @otu=split/\./,$otu;
my $otuname=shift @otu;
use strict;
open IN,$group or die $!;
my %group;
my @g;
while(<IN>){
	chomp;
        my @tab = split /\t/,$_;
        $group{$tab[0]}=$tab[1];
	push @g,$tab[1];
}
my %seen = ( ); 
my @guniq = grep { ! $seen{$_} ++ } @g; 
#my @guniq=unique(@g);
@guniq=sort{$a cmp $b}@guniq;
#print @guniq;
close IN;
open IN,$otu or die $!;
my %stat;
while(<IN>){
	chomp;
	my @a = split /\t/;
	my $b = shift @a;
	my $num =substr($b,6,length($b)-6);
	foreach my $name(@a){
		$name=~/(\S+)\_\d+/;
		my $g=$group{$1};
		$stat{$g}.="$num\t";
	}
}
close IN;
open OUT,">$otuname.venn.txt" or die $!;
foreach my $name(sort keys%stat){
	chop $stat{$name};
	my @nums=split/\t/,$stat{$name};
	my @uniq=&uniq(@nums);
	@uniq=sort{$a <=>$b}@uniq;
	my $nums=scalar(@uniq);
	print OUT "$name\_$nums\t@uniq\n";
}
close OUT;
sub uniq{
	my %seen;
	my @unique;
	foreach my $value (@_) {
		if (! $seen{$value}) {
			push @unique, $value;
			$seen{$value} = 1;
  		}
	}
return(@unique);
}
open R, ">$otuname.venn.R" || die $!;
print R <<RTXT;
library(VennDiagram)
library(grid)
X=read.table("$otuname.venn.txt",sep="\\t",row.name=1,header=F)
g=c()
for (i in 1:nrow(X)){
	a=X[i,]
	a=as.vector(a)
	a=strsplit(a," ")
	g=c(g,a)
}
RTXT
if($gnum==2){
print R <<RTXT;
venn.plot <- venn.diagram(
        x = list($guniq[0]=g[1][[1]],$guniq[1]=g[2][[1]]),
        filename = "$otuname.venn.tiff",
        col = "black",
	fill = c("dodgerblue", "goldenrod1"),
	cat.col = c("dodgerblue", "goldenrod1"),
        cat.cex = 1.5,
        cat.fontface = "bold",
        margin = 0.14
        )
RTXT
}
if($gnum==3){
print R <<RTXT;
venn.plot <- venn.diagram(
        x = list($guniq[0]=g[1][[1]],$guniq[1]=g[2][[1]],$guniq[2]=g[3][[1]]),
        filename = "$otuname.venn.tiff",
        col = "black",
        fill = c("dodgerblue", "goldenrod1","darkorange1"),
        cat.col = c("dodgerblue", "goldenrod1","darkorange1"),
        cat.cex = 1.5,
        cat.fontface = "bold",
        margin = 0.14
        )
RTXT
}
if($gnum==4){
print R <<RTXT;
venn.plot <- venn.diagram(
        x = list($guniq[0]=g[1][[1]],$guniq[1]=g[2][[1]],$guniq[2]=g[3][[1]],$guniq[3]=g[4][[1]]),
        filename = "$otuname.venn.tiff",
        col = "black",
        fill = c("dodgerblue", "goldenrod1","darkorange1","seagreen3"),
        cat.col = c("dodgerblue", "goldenrod1","darkorange1","seagreen3"),
        cat.cex = 1.5,
        cat.fontface = "bold",
        margin = 0.14
        )
RTXT
}
if($gnum==5){
print R <<RTXT;
venn.plot <- venn.diagram(
        x = list($guniq[0]=g[1][[1]],$guniq[1]=g[2][[1]],$guniq[2]=g[3][[1]],$guniq[3]=g[4][[1]],$guniq[4]=g[5][[1]]),
        filename = "$otuname.venn.tiff",
        col = "black",
        fill = c("dodgerblue", "goldenrod1", "darkorange1", "seagreen3", "orchid3"),
        cat.col = c("dodgerblue", "goldenrod1","darkorange1","seagreen3", "orchid3"),
	cex = c(1.5, 1.5, 1.5, 1.5, 1.5, 1, 0.8, 1, 0.8, 1, 0.8, 1, 0.8,1, 0.8, 1, 0.55, 1, 0.55, 1, 0.55, 1, 0.55, 1, 0.55, 1, 1, 1, 1, 1, 1.5),
        cat.cex = 1.5,
        cat.fontface = "bold",
        margin = 0.14
		)
RTXT
}

system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH $otuname.venn.R $otuname.venn.R.Rout");
