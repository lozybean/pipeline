#!usr/bin/perl -w
die "perl $0 <diff.marker.xls><group.txt><col1><col2>" unless(@ARGV==4); 
my ($otu0,$group,$col1,$col2)=@ARGV;
my @otu=split/\./,$otu0;
my $otuname=shift @otu;
open R, ">$otuname.heatmap.R";
print R<<RTXT;
data=read.table("$otu0",header=TRUE,row.names=1,sep="\t")
group=read.table("$group",sep="\t",row.names=1)

colnames(group)="G"
pdf("$otuname.diff.marker.heatmap_cluster.pdf",11,8.5)
par(mar=c(2.1,2.1,4.1,5.1))
library(pheatmap)
library(RColorBrewer)
m1=min(min(data,na.rm=T),na.rm=T)
m2=max(max(data,na.rm=T),na.rm=T)
col1=colorRampPalette(brewer.pal(9, "YlOrBr")[7:2])($col1)
col2=colorRampPalette(brewer.pal(9, "YlGnBu")[3:7])($col2)
col=c(col1,col2)
pheatmap(data,color=col,annotation=group)
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.0.1/bin/Rscript $otuname.heatmap.R --vanilla");
system("/usr/bin/convert $otuname.diff.marker.heatmap_cluster.pdf $otuname.diff.marker.heatmap_cluster.png");
system("rm -f  $otuname.heatmap.R ");

