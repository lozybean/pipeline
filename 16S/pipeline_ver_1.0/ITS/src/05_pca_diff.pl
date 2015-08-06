#!/usr/bin/env perl
=pod
description: pca of diff tax
author: Wu Leyun
created date: 20150213
=cut
use Getopt::Long;
use File::Basename qw(dirname basename);

my ($profile,$group,$help,);

GetOptions("profile:s" => \$profile, "group:s" => \$group, "help|?" => \$help);

if (!defined $profile ||!defined $group|| defined $help) {
	        print STDERR << "USAGE";
description: pca of diff tax
usage: perl $0 [options]
options:
        -profile *: profile
	-group *: group table,"sample\\tgroup"
	-help|?: print help information
USAGE
        exit 1;
}

my @otu=split/\./,$profile;
my $otuname=shift @otu;
open R, ">$otuname.pca.R";
print R<<RTXT;
library(WGCNA)
library("ade4")
library(RColorBrewer)
X=read.table("$profile",header=TRUE,row.names=1,sep="\\t")
group=read.table("$group",header=F,row.names=1)
#colnames(X)=sub("X","",colnames(X))####if the first letter of more than one colnames(X) is num,execute this progress
group=group[colnames(X),1]
group=as.data.frame(group)
rownames(group)=colnames(X)
colors=labels2colors(group)

g=unique(group)
g_order=g[order(g),1]
gcols=unique(colors)
gcols_order=gcols[order(g)]
A=factor(group[,1])
pdf(file="$otuname.pca.pdf",11,8.5)
X.dudi=dudi.pca(t(X),center=T,scale=T,scan=F)
con=X.dudi\$eig/sum(X.dudi\$eig)*100
con=format(con,digits=2)
s.class(X.dudi\$li,A,cpoint = 1.2,col=gcols_order,cellipse =0.8,axesell = T,addaxes = T,grid=F)
#mtext(paste("PCA1(",con[1],"%)",sep=""),side=1)
#mtext(paste("PCA2(",con[2],"%)",sep=""),side=2)
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH  $otuname.pca.R $otuname.pca.Rout");
system("/usr/bin/convert $otuname.pca.pdf $otuname.pca.png");
system("rm -f  $otuname.pca.R ");

