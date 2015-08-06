#!/usr/bin/env perl
die "perl $0 <diff.marker.xls><group.txt><col1><col2>" unless(@ARGV==4); 
my ($otu0,$group,$col1,$col2)=@ARGV;
my @otu=split/\./,$otu0;
my $otuname=shift @otu;
open R, ">$otuname.heatmap.R";
print R<<RTXT;
data=read.table("$otu0",header=TRUE,row.names=1,sep="\t")
group=read.table("$group",sep="\t",row.names=1)
s=c()
for(i in 1:nrow(data)){
        s[i]=sum(as.numeric(data[i,]))
}
list=order(s,decreasing=T)
data0=data[list,]
rownames(data0)=rownames(data)[list]

colnames(group)="G"
pdf("$otuname.diff.marker.heatmap.pdf",11,8.5)
par(mar=c(2.1,2.1,4.1,5.1))
library(pheatmap)
library(RColorBrewer)
m1=min(min(data,na.rm=T),na.rm=T)
m2=max(max(data,na.rm=T),na.rm=T)
col1=colorRampPalette(brewer.pal(9, "YlOrBr")[7:2])($col1)
col2=colorRampPalette(brewer.pal(9, "YlGnBu")[3:7])($col2)
col=c(col1,col2)
pheatmap(data0,color=col,annotation=group,cluster_rows = F, cluster_cols = F)
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.0.1/bin/Rscript $otuname.heatmap.R --vanilla");
system("/usr/bin/convert $otuname.diff.marker.heatmap.pdf $otuname.diff.marker.heatmap.png");
system("rm -f  $otuname.heatmap.R ");

