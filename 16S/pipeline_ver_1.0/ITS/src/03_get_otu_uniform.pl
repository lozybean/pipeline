#!/usr/bin/env perl
die "perl $0 <profiling.anno>" unless(@ARGV==1); 
my ($otu0)=@ARGV;
my @otu=split/\./,$otu0;
my $otuname=shift @otu;
open IN,$otu0 || die "can not open $otu0\n";
open OUT,">$otuname.removefirst.txt" ||die $!;
<IN>;
while(<IN>){
	chomp;
	my @tab=split/\t/,$_;
	if(/#(.*)/){print OUT "$1\n";}
	else{print OUT "$_\n";}
}
#open OUT,$out || die "can not open $out\n";
close IN;
close OUT;

open R,">$otuname.R";
print R<<RTXT;
X=read.table("$otuname.removefirst.txt",header=TRUE,row.names=1,sep="\\t")
colnames(X)=sub("X","",colnames(X))
X_uniform =sweep(X,2,apply(X,2,sum),"/")
colnames(X_uniform)=colnames(X)
write.table(X_uniform,"$otuname\_profile1.txt",sep="\\t",quote=F,row.names=T,col.names=T)
RTXT


system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.0.1/bin/Rscript $otuname.R --vanilla");
#system("rm -f $otuname.removefirst.txt");
open IN,"$otuname\_profile1.txt" || die "can not open $otuname\_profile1.txt\n";
open OUT,">$otuname\_profile.txt" ||die $!;
my $header=<IN>;
print OUT "otu\t$header";
while(<IN>){
	chomp;
	print OUT "$_\n";
}
close IN;
close OUT;
