#!/usr/bin/env perl
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
X=read.table("$otu0",header=TRUE,row.names=1,sep="\t")
nrow(X)
group=read.table("$group",header=F,row.names=1)
#rownames(X)=sub("X","",rownames(X))
X=X[c(rownames(group),rownames(X)[nrow(X)-1],rownames(X)[nrow(X)]),]
rownames(X)=c(rownames(group),rownames(X)[nrow(X)-1],rownames(X)[nrow(X)])
colors=labels2colors(group)
g=unique(group)
#g_order=g[order(g),1]
gcols=unique(colors)
#gcols_order=gcols[order(g)]
A=as.character(g[,1])
con=X[nrow(X),]/sum(X[nrow(X),])*100
#con=format(con,digits=3)
con=round(con,2)
xmin=min(min(X[1:(nrow(X)-2),1]))
ymin=min(min(X[1:(nrow(X)-2),2]))
xmax=max(max(X[1:(nrow(X)-2),1]))
ymax=max(max(X[1:(nrow(X)-2),2]))
labels=rownames(X)[1:(nrow(X)-2)]
labels
pdf(file="$otuname.pcaplot.pdf",11,8.5)
par(mar=c(4.1,5.1,3.1,2.1))
#par(mfrow = c(2,1))
#nf<-layout(matrix(c(1,1,1,2,2),5,1,byrow=TRUE))
nf<-layout(matrix(c(1,1,3,1,1,3,1,1,3,2,2,4,2,2,4),5,3,byrow=TRUE))
plot(X[1:(nrow(X)-2),1:2],col=colors,pch=20,cex=2,xlab=paste("PCoA1(",con[1],"%)",sep=""),ylab=paste("PCoA2(",con[2],"%)",sep=""),cex.axis=1.2,cex.lab=1.6,cex.main=2,xlim=c(xmin,xmax),ylim=c(ymin,ymax+0.05),main="$otubase")
#text(X[1:(nrow(X)-2),1],X[1:(nrow(X)-2),2],labels=rownames(X)[1:(nrow(X)-2)],cex=1.8)
legend("topright",A,col=gcols,pch=20,cex=1.5,horiz = T,bty="n")
par(mar=c(4.1,5.1,0,2.1))
Y=rbind(X[1:(nrow(X)-2),1],as.character(group[,1]))
Y=t(Y)
Y=as.data.frame(Y)
rownames(Y)=rownames(X)[-c(nrow(X)-1,nrow(X))]
colnames(Y)=c("pc","time")
Y\$pc=as.numeric(as.character(Y\$pc))
levels=rev(g[,1])
Y\$time=factor(Y\$time,levels)
boxplot(pc ~ time, data = Y, col = rev(gcols),horizontal=T,outline=T,cex.lab=1.6,cex.axis=1.2,xaxt="n")
par(mar=c(4.1,0,3.1,5.1))
Y1=rbind(X[1:(nrow(X)-2),2],as.character(group[,1]))
Y1=t(Y1)
Y1=as.data.frame(Y1)
rownames(Y1)=rownames(X)[-c(nrow(X)-1,nrow(X))]
colnames(Y1)=c("pc1","time1")
Y1\$pc1=as.numeric(as.character(Y1\$pc1))
levels=g[,1]
Y1\$time1=factor(Y1\$time1,levels)
boxplot(pc1 ~ time1, data = Y1, col = gcols,horizontal=F,outline=T,cex.lab=1.6,cex.axis=1.2,yaxt="n")
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH $otuname.pca.R $otuname.pca.Rout");
system("/usr/bin/convert $otuname.pcaplot.pdf $otuname.pcaplot.png");
#system("rm -f  $otuname.pca.R ");

