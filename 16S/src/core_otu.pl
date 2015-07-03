#!usr/bin/perl -w
use strict;
die "perl $0 <otu.txt><assign.txt><cutoff>" unless(@ARGV==3); 
my ($otu0,$otuid,$cutoff)=@ARGV;
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
    if($per{$tab[0]}>0.5){$group{">0.5"}++;print OUT "$tab[0]\t$taxnum{$tab[0]}\n" if $cutoff==0.5;}
    if($per{$tab[0]}>0.6){$group{">0.6"}++;print OUT "$tab[0]\t$taxnum{$tab[0]}\n" if $cutoff==0.6;}
    if($per{$tab[0]}>0.7){$group{">0.7"}++;print OUT "$tab[0]\t$taxnum{$tab[0]}\n" if $cutoff==0.7;}
    if($per{$tab[0]}>0.8){$group{">0.8"}++;print OUT "$tab[0]\t$taxnum{$tab[0]}\n" if $cutoff==0.8;}
    if($per{$tab[0]}>0.9){$group{">0.9"}++;print OUT "$tab[0]\t$taxnum{$tab[0]}\n" if $cutoff==0.9;}
    if($per{$tab[0]}==1){$group{"==1"}++;print OUT "$tab[0]\t$taxnum{$tab[0]}\n" if $cutoff==1;}
}
close IN;

print OUT1 <<TXT;
>0.5\t$group{">0.5"}
>0.6\t$group{">0.6"}
>0.7\t$group{">0.7"}
>0.8\t$group{">0.8"}
>0.9\t$group{">0.9"}
==1\t$group{"==1"}
TXT

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

open IN,"$otuname.core.txt" or die $!;
open OUT,">$otuname.core_otu_summary.xls" or die $!;
print OUT "OTU ID\tTaxonomy level\tTaxonomy name\n";
my %tax_info = ("k"=>"kingdom","p"=>"phylum","c"=>"class","o"=>"order","f"=>"family","g"=>"genus","s"=>"species");
<IN>;
while(<IN>){
	my @tabs = split /\t/;
	my($otu,$tax) = @tabs;
	$tax =~ /^(\w)__(\S+)/;
	my $level = $tax_info{$1};
	my $tax_name = $2;
	print OUT "$otu\t$level\t$tax_name\n";
}
close IN;
close OUT;
