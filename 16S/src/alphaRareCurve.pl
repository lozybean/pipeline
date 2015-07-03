#!/usr/bin/perl
use strict;
die "perl $0 <alpha.txt>" unless(@ARGV==1);
my $alphafile = shift @ARGV;
open IN,$alphafile or die $!;
my $max = 0;
<IN>;
while(<IN>){
	my @tab = split /\t/;
	shift @tab;shift @tab;shift @tab;
	foreach (@tab){
		$max = $_ if $max < $_;
	}
}
close IN;
print "$max\n";
$max  = $max * 1.2;
my @a = split /\./,$alphafile;
my $alphaname = shift @a;
$alphaname =~ /\S+\/(\S+)/;
my $alpha_base = $1;
my $m = $max / 2;
open R, ">$alphaname.rare.R";
print R<<RTXT;
table = read.table("$alphafile", sep = "\t",head = T)
pdf("$alphaname.rare.pdf")
unique_readnumber = unique(as.numeric(as.character(table[,2])))
readnumber = as.numeric(as.character(table[,2]))
iteration = max(unique(as.numeric(as.character(table[,3])))) + 1
table = table[,-c(1, 2, 3)]
plot(0,xlim=c(0,max(readnumber)),ylim=c(0,$max),type="n",ylab="$alpha_base",xlab="readsnum")
#legend("topright",legend=paste("T",0:8,sep=""),col=rainbow(9),lwd=1.2)
otu <- function(reads, vmax, km){
  vmax * reads / (km + reads)
}
colors = rainbow(ncol(table))
for(i in 1:ncol(table))
{
	col = table[,i]
	col = as.numeric(as.character(col[col != "n/a"]))
	readnum = readnumber[1:length(col)]
#	color=colors[as.numeric(substr(colnames(table)[i],5,5))+1]
	color=colors[i]
	estimation = nls(col~otu(readnum, vmax, km), start=list( vmax = 120, km = 100 ))
	coef(estimation)
	x = seq(0,max(readnum), 1)
	y = otu(x, coef(estimation)[1], coef(estimation)[2])
	lines(x,y, type = "l",col=color)
}
dev.off()
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.0.1/bin/R CMD BATCH $alphaname.rare.R $alphaname.rare.R.out");
system("/usr/bin/convert $alphaname.rare.pdf $alphaname.rare.png");

