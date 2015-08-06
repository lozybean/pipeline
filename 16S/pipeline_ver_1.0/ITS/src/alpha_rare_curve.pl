#!/usr/bin/env perl
use strict;
use File::Basename;
die "perl $0 <alpha_all.txt><group.txt>< if col by group>" unless(@ARGV==3);

my ($alpha,$group,$choice)=@ARGV if @ARGV==3;
my @alpha=split/\./,$alpha;
my $alphaname=shift @alpha;
my $alphabase=basename($alphaname);

open R, ">$alphaname.rare.R";
print R<<RTXT;
library(WGCNA)
table = read.table("$alpha", sep = "\\t",head = T)
group=read.table("$group", sep = "\\t",head = F,row.names=1)
pdf("$alphaname.rare.pdf")
par(mar=c(5.1,5.1,3.1,2.1))
unique_readnumber = unique(as.numeric(as.character(table[,2])))
readnumber = as.numeric(as.character(table[,2]))
iteration = max(unique(as.numeric(as.character(table[,3])))) + 1
table = table[,-c(1, 2, 3)]
if("$choice" == "Y"){
group=group[colnames(table),1]}else{group=colnames(table)}
group=as.data.frame(group)
rownames(group)=colnames(table)
colors=labels2colors(group)
g=unique(group)
g_order=g[order(g),1]
gcols=unique(colors)
gcols_order=gcols[order(g)]
ymax=max(as.numeric(as.character(table[table != "n/a"])))
plot(0,0,xlim=c(0,max(readnumber)+1800),ylim=c(0,ymax),type="n",xlab="reads",ylab="$alphabase",cex.lab=1.4)
if("$choice" == "N"){legend("topright",legend=g_order,col=gcols_order,seg.len=1.5,lwd=1.6,cex=0.8)}
otu <- function(reads, vmax, km){
  vmax * reads / (km + reads)
}
#colors = rainbow(9)
for(i in 1:ncol(table))
{
        col = table[,i]
        col = as.numeric(as.character(col[col != "n/a"]))
        readnum = readnumber[1:length(col)]
        color=colors[i]
	estimation = nls(col~otu(readnum, vmax, km), start=list( vmax = max(col), km = 100),lower=c(0,0.2),algorithm = "port")
	estimation
        x = seq(0,max(readnum), 1)
        y = otu(x, coef(estimation)[1], coef(estimation)[2])
        lines(x,y, type = "l",col=color)
	if("$choice" == "Y"){text(max(readnum),max(y),colnames(table)[i])}
	#if("$choice" == "N"){text(max(readnum),max(y),substr(colnames(table)[i],3,5))}
}
dev.off()
RTXT

system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH $alphaname.rare.R $alphaname.rare.R.out");
system("/usr/bin/convert $alphaname.rare.pdf $alphaname.rare.png");
