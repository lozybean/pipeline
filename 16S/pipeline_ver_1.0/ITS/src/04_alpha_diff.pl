#!/usr/bin/env perl
=pod
description: alpha test and boxplot
author: Wu Leyun
created date: 20150213
=cut

use Getopt::Long;
use File::Basename qw(dirname basename);

my ($alpha, $group,$group_number, $help,);

GetOptions("alpha:s" => \$alpha, "group:s" => \$group,"gnum:s" => \$group_number,"help|?" => \$help);

if (!defined $alpha || !defined $group ||!defined $group_number || defined $help) {
	        print STDERR << "USAGE";
description: alpha test and boxplot
usage: perl $0 [options]
options:
	-alpha *: alpha.txt
	-group *: group table,"sample\\tgroup"
	-gnum *:num
	-help|?: print help information
USAGE
        exit 1;
}


my @alpha=split/\./,$alpha;
my $alphaname=shift @alpha;
my $alphabase=basename($alphaname);
system("sed -n '1p' $alpha>$alphaname.head.txt");
system("sed -n '\$p' $alpha>$alphaname.tail.txt");
system("cat $alphaname.head.txt $alphaname.tail.txt>$alphaname.alpha.txt");
my %alpha;
open IN,"$alphaname.alpha.txt" || die "can not open $alphaname.alpha.txt\n";
open OUT,">$alphaname.w.txt" || die "can not open $alphaname.w.txt\n";
my $header=<IN>;
my @headers=split/\t/,$header;
shift @headers;shift @headers;shift @headers;
print OUT "alphaname\t@headers";
while(<IN>){
          chomp;
          my @tab=split/\t/,$_;
          shift @tab;shift @tab;shift @tab;
          print OUT "$alphabase\t@tab\n";
}
close IN;
close OUT;

open R, ">$alphaname.wilcox.diff.R";
print R<<RTXT;
library(WGCNA)
X=read.table("$alphaname.w.txt",header=TRUE,row.names=1)
#X=as.matrix(X)
group=read.table("$group",header=F,row.names=1)
#colnames(X)=sub("X","",colnames(X))####if the first letter of more than one colnames(X) is num,execute this progress
X=X[,rownames(group)]
colnames(X)=rownames(group)
colors=labels2colors(group)
g=unique(group)
#g_order=g[order(g),1]
gcols=unique(colors)
#gcols_order=gcols[order(g)]
xlist=c()
for(i in 1:nrow(g)){
	rname=which(group[,1]==g[i,1])
	g0=rownames(group)[rname]
	g0=g0[!is.na(g0)]
	Xg1=X[,g0][X[,g0]!="n/a"]
	Xg=list(as.numeric(Xg1))
	xlist=c(xlist,Xg)
}
means=c()
meanname=c()
for(j in 1:length(xlist)){
	area=as.character(g[j,1])
	mean=mean(as.numeric(xlist[[j]][xlist[[j]]!= "n/a"]))
	means=cbind(means,mean)
	meanname=c(meanname,paste("mean(",area,")",sep=""))
       }

pdf("$alphaname.boxplot.pdf",11,8.5)
y1=min(min(X[X!="n/a"],na.rm=T))
y2=max(max(X[X!="n/a"],na.rm=T))
par(mar=c(4.1,5.1,4.1,1.1))
library(RColorBrewer)
#cols=colorRampPalette(brewer.pal(9, "Set1"))(9)
xlist
boxplot(xlist,ylab=expression(paste(alpha, " Diversity ($alphabase diversity index)",sep="")),col=gcols,xaxt="n",cex.lab=1.4,cex.axis=1)
axis(side=1,at=1:length(xlist),labels=g[,1],cex.axis=1)
if($group_number==2){
	p=wilcox.test(xlist[[1]],xlist[[2]])["p.value"]}else{
	p=kruskal.test(xlist)["p.value"]}
statsKWs<-cbind(rownames(X),means,p)
colnames(statsKWs)<- c("alphaname",meanname,"pvalue")
write.table(statsKWs,"$alphaname.marker.txt",row.names=F,quote=F,sep="\\t")
RTXT

system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH $alphaname.wilcox.diff.R $alphaname.wilcox.diff.R.out");
system("/usr/bin/convert $alphaname.boxplot.pdf $alphaname.boxplot.png");
system("rm -f   $alphaname.head.txt $alphaname.tail.txt $alphaname.alpha.txt $alphaname.kruskalstats.R");# $alphaname.kruskalstats.R.out");

