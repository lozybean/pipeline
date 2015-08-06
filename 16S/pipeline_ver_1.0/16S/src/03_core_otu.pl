#!/usr/bin/env perl
die "perl $0 <otu.txt><assign.txt>" unless(@ARGV==2); 
my ($otu0,$otuid)=@ARGV;
my @otu=split/\./,$otu0;
my $otuname=shift @otu;
my %num;
my %per;
my %group;
my %taxnum;
my $allnum;
open IN,$otuid || die "can not open $otuid\n";
while(<IN>){
        chomp;
        my @tab=split/\t/,$_;
	my @tax=split/;/,$tab[1];
	my $tax=pop @tax;
	$taxnum{$tab[0]}=$tax;
}
open IN,$otu0 || die "can not open $otu0\n";
open OUT,">$otuname.core.txt" || die "can not open $otuname.core.txt\n";
open OUT1,">$otuname.plot.txt" || die "can not open $otuname.plot.txt\n";
print OUT "OTU ID\tTaxonomy name\n";
<IN>;<IN>;
$group{">0.5"}=0;$group{">0.6"}=0;$group{">0.7"}=0;$group{">0.8"}=0;$group{">0.9"}=0;$group{"==1"}=0;
while(<IN>){
        chomp;
        my @tab=split/\t/,$_;
	$allnum=scalar(@tab)-1;
        for (my $i=1;$i<@tab;$i++){
                next if($tab[$i]==0);
		$num{$tab[0]}++;
        }
	$per{$tab[0]}=$num{$tab[0]}/$allnum;
        if($per{$tab[0]}>0.5){$group{">0.5"}++;}
        if($per{$tab[0]}>0.6){$group{">0.6"}++;}
        if($per{$tab[0]}>0.7){$group{">0.7"}++;}
        if($per{$tab[0]}>0.8){$group{">0.8"}++;}#print OUT "$tab[0]\t$taxnum{$tab[0]}\n";}
        if($per{$tab[0]}>0.9){$group{">0.9"}++;}
        if($per{$tab[0]}==1){$group{"==1"}++;print OUT "$tab[0]\t$taxnum{$tab[0]}\n";}
}
close IN;
for my $g(sort {$group{$b} <=> $group{$a}} keys %group){
	print OUT1 "$g\t$group{$g}\n";
}
open R, ">$otuname.core.R";
print R<<RTXT;
data=read.table("$otuname.plot.txt",row.names=1)
data=t(as.matrix(data))
pdf("$otuname.core.pdf",11,8.5)
par(mar=c(4.1,5.1,4.1,2.1))
barplot(data,ylab="Number of OTUs",xlab="Fraction of samples",cex.names=1.5,cex.axis=1.5,cex.lab=2)
RTXT
system("/data_center_01/home/NEOLINE/wuleyun/wuly/R-3.0.1/bin/Rscript $otuname.core.R --vanilla");
system("/usr/bin/convert $otuname.core.pdf $otuname.core.png");
system("rm -f   $otuname.core.R ");

