#!/usr/bin/env perl
use strict;
use File::Basename;
die "perl $0 <beta_dist.txt><group.txt>" unless(@ARGV==2);

my ($dist,$group)=@ARGV;
my @dist=split/\./,$dist;
my $distname=shift @dist;
my $distbase=basename($distname);
open R, ">$distname.boxplot.R";
print R<<RTXT;

library(grid)
library(WGCNA)
X=read.table("$dist",sep="\\t",row.name=1,header=T)
#colnames(X)=sub("X","",colnames(X))
group=read.table("$group",sep="\\t",row.name=1,header=F)
X=X[,rownames(group)]
colnames(X)=rownames(group)
colors=labels2colors(group)
g=unique(group)
#g_order=g[order(g),1]
gcols=unique(colors)
#gcols_order=gcols[order(g)]
A=as.character(g[,1])
xlist=c()
for(i in 1:nrow(g)){
        rname=which(group[,1]==g[i,1])
        g0=rownames(group)[rname]
        g0=g0[!is.na(g0)]
        Xg1=X[g0,g0]
	Xg1=as.dist(Xg1)
	Xg2=as.vector(Xg1)
        Xg=list(as.numeric(Xg2))
        xlist=c(xlist,Xg)
}
pdf("$distname.boxplot.pdf",8,8)
boxplot(xlist,ylab="$distbase",col=gcols,xaxt="n",cex.lab=1.4,cex.axis=1)
axis(side=1,at=1:length(xlist),labels=g[,1],cex.axis=1,cex.lab=2)
dev.off()
#pdf(paste(Args[8],".NMDS.pdf",sep=""),11,8)
#library(ecodist)
#Xdist=as.dist(X)
#X.nmds=nmds(Xdist,mindim = 1, maxdim = ncol(X))
#X.min <- nmds.min(X.nmds)
#plot(X.min[,1:2],col=colors,cex.axis=1.2,cex.lab=1.6,xlab="NMDS1",ylab="NMDS2")
#legend("topleft",A,col=gcols_order,pch=20,cex=1.5,bty="n",,horiz=T)
#dev.off()
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH $distname.boxplot.R $distname.boxplot.Rout");
system("/usr/bin/convert $distname.boxplot.pdf $distname.boxplot.png");

