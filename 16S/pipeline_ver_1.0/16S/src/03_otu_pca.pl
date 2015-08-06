#!/usr/bin/env perl
die "perl $0 <otu_all.xls><group.txt>" unless(@ARGV==2); 
my ($otu0,$group)=@ARGV;
my @otu=split/\./,$otu0;
my $otuname=shift @otu;
open IN,$otu0 or die $!;
open OUT,">$otuname.sort.txt" or die $!;
my $header=<IN>;
my @headers=split/\t/,$header;
chomp @headers;
@headers=sort @headers;
$" = "\t";
print OUT "otu\t@headers\n";
while(<IN>){
	chomp;
	my @tab=split/\t/,$_;
	my %out;
	for(my $i=1;$i<@tab;$i++){
		$out{$headers[$i-1]}=$tab[$i];
	}
	my @out;
	foreach my $area(sort keys %out){
		push (@out,$out{$area});}
	$" = "\t";
	print OUT "$tab[0]\t@out\n";
}
close IN;
close OUT;
		
open R, ">$otuname.pca.R";
print R<<RTXT;
library(WGCNA)
X=read.table("$otu0",header=TRUE,row.names=1,sep="\\t")
group=read.table("$group",header=F,row.names=1)
#colnames(X)=sub("X","",colnames(X))
X=X[,rownames(group)]
group=as.data.frame(group)
colnames(X)=rownames(group)
colors=labels2colors(group[,1])
g=unique(group)
g_order=g[order(g),1]
gcols=unique(colors)
gcols_order=gcols[order(g)]
A=as.character(g_order)

library("ade4")
pdf(file="$otuname.pcaplot.pdf",11,8.5)
par(mar=c(4.1,5.1,4.1,2.1))
Xdist=dist(t(X))
#X.dudi=dudi.pco(Xdist,nf=2,scannf=F)
X.dudi=dudi.pca(t(X),center=T,scale=T,scan=F)
len=c()
con=X.dudi\$eig/sum(X.dudi\$eig)*100
con=round(con,2)
ymin=min(X.dudi\$li[,2])
ymax=max(X.dudi\$li[,2])
plot(X.dudi\$li,col=colors,pch=20,cex=1.2,ylim=c(ymin,ymax+0.1),xlab=paste("PCA1(",con[1],"%)",sep=""),ylab=paste("PCA2(",con[2],"%)",sep=""),cex.axis=1.5,cex.lab=2)
legend("topleft",A,col=gcols_order,pch=20,cex=1.5,bty="n",,horiz=T)
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/R CMD BATCH $otuname.pca.R $otuname.pca.Rout");
system("/usr/bin/convert $otuname.pcaplot.pdf $otuname.pcaplot.png");
#system("rm -f  $otuname.pca.R ");

