#!usr/bin/perl -w
use File::Basename;
die "perl $0 <otu_all.xls><group.txt>" unless(@ARGV==2);
my ($otu0,$group)=@ARGV;
my @otu=split/\./,$otu0;
my $otuname=shift @otu;
my $otubase=basename($otuname);


open R, ">$otuname.pca.R";
print R<<RTXT;
library(WGCNA)
library("ade4")
library(RColorBrewer)
X=read.table("$otu0",header=TRUE,row.names=1,sep="\\t")
nrow(X)
group=read.table("$group",header=F,row.names=1)
rownames(X)=sub("X","",rownames(X))
group=group[rownames(X)[1:(nrow(X))],1]
group=as.data.frame(group)
rownames(group)=rownames(X)[1:(nrow(X))]
rownames(group)
colors=labels2colors(group)
g=unique(group)
g_order=g[order(g),1]
gcols=unique(colors)
gcols_order=gcols[order(g)]
A=as.character(g_order)

labels=rownames(X)[1:(nrow(X))]

pdf(file="$otuname.pcaplot.pdf",11,8.5)
par(mar=c(4.1,5.1,3.1,2.1))
X.dudi = dudi.pco(as.dist(X),scannf = F, nf = 2)

#par(mfrow = c(2,1))
##nf<-layout(matrix(c(1,1,1,2,2),5,1,byrow=TRUE))

con = (  X.dudi\$eig / sum(X.dudi\$eig) )* 100;
con = round(con,2)

plot(X.dudi\$li,col=colors,pch=20,cex=2,xlab=paste("PCoA1(",con[1],"%)",sep=""),ylab=paste("PCoA2(",con[2],"%)",sep=""),cex.axis=1.2,cex.lab=1.6,cex.main=2,main="$otubase")

#text(X[1:(nrow(X)-2),1],X[1:(nrow(X)-2),2],labels=substr(rownames(X)[1:(nrow(X)-2)],4,6),cex=1.8)

legend("topright",A,col=gcols_order,pch=20,cex=1.5)

#par(mar=c(4.1,5.1,0,2.1))
##Y=rbind(X[1:(nrow(X)-2),1],as.character(group[,1]))
##Y=t(Y)
##Y=as.data.frame(Y)
##rownames(Y)=rownames(X)[-c(nrow(X)-1,nrow(X))]
##colnames(Y)=c("pc","time")
##Y\$pc=as.numeric(as.character(Y\$pc))
##levels=rev(g_order)
##Y\$time=factor(Y\$time,levels)
##boxplot(pc ~ time, data = Y, col = rev(gcols_order),horizontal=T,outline=FALSE,cex.lab=2,cex.axis=2,xaxt="n")
#

RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH $otuname.pca.R $otuname.pca.Rout");
system("/usr/bin/convert $otuname.pcaplot.pdf $otuname.pcaplot.png");

