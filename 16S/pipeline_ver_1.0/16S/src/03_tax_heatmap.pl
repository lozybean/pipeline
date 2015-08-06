#!/usr/bin/env perl
die "perl $0 <otu_table_L.txt><group.txt>" unless(@ARGV==2); 
my ($otu0,$group)=@ARGV;
my @otu=split/\./,$otu0;
my $otuname=shift @otu;
open IN,$otu0 ||die $!;
<IN>;
open OUT,">$otuname.heatmap.profile"|| die $!;
my $header=<IN>;
$header =~ s/^#//;
print OUT $header;
my %num;
my %value;
my %per;
my $b;
my $allnum;
while(<IN>){
	chomp;
	my @tabs=split/\t/,$_;
	$allnum=scalar(@tabs)-1;
	next if($tabs[0]=~/Other/ or $tabs[0]=~/__$/);
	my @names=split/;/,$tabs[0];
	my $name=pop @names;
	shift @tabs;
	my $tabs=join("\t",@tabs);
	print OUT "$name\t$tabs\n";
	$num{$name}=0;
        for (my $i=0;$i<@tabs;$i++){
                next if($tabs[$i]==0);
                $num{$name}++;
		$value{$name}+=$tabs[$i];
        }
	#print $num{$tab[0]}."\t";
        $per{$name}=$num{$name}/$allnum;
        if($per{$name}>0.8 && $value{$name}>0.0001){$b.="1\t";}else{$b.="0\t";}
}
close IN;
close OUT;
open OUT,">$otuname.show_rowname.xls" || die $!;
chop $b;
print OUT  $b."\n";
close OUT;
open R, ">$otuname.heatmap.R";
print R<<RTXT;
library(pheatmap)
library(gplots)
library(RColorBrewer)
library(WGCNA)
data=read.table("$otuname.heatmap.profile",header=TRUE,row.names=1,sep="\\t")
#colnames(data)=sub("S","",colnames(data))
group=read.table("$group",sep="\\t",header=F,row.names=1)
#group=as.character(group)
name=read.table("$otuname.show_rowname.xls",header=F)
rows=rep(" ",nrow(data))
for(i in 1:nrow(data)){
	if(name[1,i]==1){
		rows[i]=rownames(data)[i]
	}
}
group=group[colnames(data),1]
group=as.data.frame(group)
rownames(group)=colnames(data)
colors=labels2colors(group,colorSeq=c(3,4,2,5:8))
pdf("$otuname.heatmap.pdf",20,12)
par(mar=c(2.1,1.1,2.1,5.1))
col1=colorRampPalette(brewer.pal(9, "YlOrBr")[7:2])(10)
col2=colorRampPalette(brewer.pal(9, "YlGnBu")[3:7])(2340)
col=c(col1,col2)
col3=colorRampPalette(brewer.pal(9, "YlOrBr")[7:2])(1175)
col4=colorRampPalette(brewer.pal(9, "YlGnBu")[3:7])(1175)
cols=c(col3,col4)
#max(max(data))
#pheatmap(data,color=col,annotation=group,cluster_rows = F,clustering_distance_cols = function(x) hclust(x,method='complete'))
heatmap.2(as.matrix(data),col=col,na.rm=T,distfun=function(x) dist(x),hclustfun=function(x) hclust(x,method='complete'),dendrogram="col",Rowv=F,labRow=rows,ColSideColors=colors,cexRow=1.16,offsetRow=0.1,cexCol=1.4,symkey=FALSE,density.info="none",trace="none",key=F,margins=c(8,10),keysize=0.3)
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.1.2/bin/Rscript $otuname.heatmap.R --vanilla");
system("/usr/bin/convert $otuname.heatmap.pdf $otuname.heatmap.png");
#system("rm -f  $otuname.heatmap.R ");

