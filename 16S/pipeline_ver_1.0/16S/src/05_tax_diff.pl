#!/usr/bin/env perl
=pod
description: tax test 
author: Wu Leyun
created date: 20150213
=cut

use Getopt::Long;
use File::Basename qw(dirname basename);

my ($profile, $group,$group_number,$qcutoff, $help,);

GetOptions("profile:s" => \$profile, "group:s" => \$group,"gnum:s" => \$group_number, "qcutoff:s" => \$qcutoff,"help|?" => \$help);

if (!defined $profile || !defined $group || !defined $group_number ||!defined $qcutoff ||defined $help) {
	print STDERR << "USAGE";
description: tax test
usage: perl $0 [options]
options:
	-profile *: profile.txt
	-group *: group table,"sample\\tgroup"
	-gnum *:num
	-qcutoff *:qcutoff
	-help|?: print help information
USAGE
exit 1;
}

my @profile=split/\./,$profile;
my $otuname=shift @profile;
open IN,$profile || die $!;
open OUT,">$otuname.t.txt"|| die $!;
my $header=<IN>;
print OUT $header;
while(<IN>){
        chomp;
        my @tabs=split/\t/,$_;
        next if($tabs[0]=~/Other/ or $tabs[0]=~/__$/ or $tabs[0]=~/Unclassified/);
        my @names=split/;/,$tabs[0];
        my $name=pop @names;
	shift @tabs;
	my $tab=join("\t",@tabs);
	print OUT "$name\t$tab\n";
        
}
close IN;
close OUT;

open R, ">$otuname.wilcox.diff.R";
print R<<RTXT;
X=read.table("$otuname.t.txt",header=TRUE,sep="\\t",row.names=1)
group=read.table("$group",header=F,row.names=1)
X=as.matrix(X)
#colnames(X)=sub("X","",colnames(X))####if the first letter of more than one colnames(X) is num,execute this progress
group=group[colnames(X),1]
group=as.data.frame(group)
rownames(group)=colnames(X)
g=unique(group)
g_order=g[order(g),1]
p=c()
means=c()
meanname=c()
glist=c()
xlist=c()
for(i in 1:length(g_order)){
	rname=which(group[,1]==g_order[i])
	g0=rownames(group)[rname]
	g0=g0[!is.na(g0)]
	mean=apply(X, 1, function(row) unlist(mean(as.matrix(row[g0]),na.rm=T)))
	means=cbind(means,mean)
	meanname=c(meanname,paste("mean(",g_order[i],")",sep=""))
	g1=list(as.character(g0))
	glist=c(glist,g1)
}
kruskal=function(X,group,g){
p=c()
for(i in 1:nrow(X)){
        xlist=c()
        for(j in 1:length(g_order)){
                rname=which(group[,1]==g_order[j])
                g0=rownames(group)[rname]
                g0=g0[!is.na(g0)]
                Xg=list(X[i,g0])
                xlist=c(xlist,Xg)
        }
        p0=kruskal.test(xlist)["p.value"][[1]][1]
        p=c(p,p0)
}
p
}

if($group_number==2){
	p <- apply(X, 1, function(row) unlist(wilcox.test(row[glist[[1]]],row[glist[[2]]])["p.value"]))
}else{p<-kruskal(X,group,g_order)}
p
fdr <- p.adjust(p, method = "fdr", n = length(p))
statsKWs<-cbind(rownames(X),means,p)
ploc=ncol(statsKWs)
colnames(statsKWs)<- c("taxonname",meanname,"pvalue")
statsKWs0<-statsKWs[statsKWs[,ploc]<$qcutoff,]
statsKWs1=matrix(statsKWs0,ncol=ploc)
colnames(statsKWs1)=colnames(statsKWs)
write.table(statsKWs1,"$otuname.diff.marker.txt",row.names=F,quote=F,sep="\t")
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.0.1/bin/R CMD BATCH $otuname.wilcox.diff.R $otuname.wilcox.diff.Rout");
system("rm -f $otuname.wilcox.diff.R ");
