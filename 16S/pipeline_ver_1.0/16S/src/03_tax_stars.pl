#!/usr/bin/env perl
use strict;
use File::Basename;
die "perl $0 <otu_L6.txt><group.txt>" unless(@ARGV==2);

my ($otu,$group)=@ARGV;
my @otu=split/\./,$otu;
my $otuname=shift @otu;
my $otubase=basename($otu);
my $main;
if($otubase eq "otu_table_L2.txt"){$main="Phylum";}
elsif($otubase eq "otu_table_L3.txt"){$main="Class";}
elsif($otubase eq "otu_table_L4.txt"){$main="Order";}
elsif($otubase eq "otu_table_L5.txt"){$main="Family";}
elsif($otubase eq "otu_table_L6.txt"){$main="Genus";}
open R, ">$otuname.stars.R";
print R<<RTXT;

library(grid)
X=read.table("$otu",sep="\\t",row.name=1,header=T)
group=read.table("$group",sep="\\t",row.name=1,header=F)
a=apply(X,1,mean)
b=order(a,decreasing = T)[1:10]
X1=X[b,]
name1=rownames(X[b,])
m=strsplit(name1,";")
name2=c()
for(i in 1:length(m)){
	x1=m[[i]][length(m[[i]])]
	if(x1=="g__" || x1=="Other"||x1=="f__"||x1=="o__"||x1=="c__"){
	x2=m[[i]][length(m[[i]])-1]
	x=paste(x2,x1,sep=";")
	name2=c(name2,x)}else{name2=c(name2,x1)}
}
name2
X2=X1[,rownames(group)]
colnames(X2)=rownames(group)
rownames(X2)=name2
palette(rainbow(12, s = 0.6, v = 0.75))
pdf("$otuname.stars.pdf",12,8)
par(mar=c(2.1,0,4.1,10.1))
#ncols=10
#if(ncol(X)%%10==0){ncols=11}
stars(t(X2), labels=colnames(X2),len = 1,ncol=6,key.loc = c(13, 2),main = "$main", draw.segments = TRUE)
palette("default")
dev.off()
RTXT

system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH $otuname.stars.R $otuname.stars.Rout");
system("/usr/bin/convert $otuname.stars.pdf $otuname.stars.png");

