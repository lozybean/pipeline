#!/usr/bin/env perl
die "perl $0 <otu_all.txt><group><out>" unless(@ARGV==3); 
my ($otu0,$group,$out)=@ARGV;
my @otu=split/\./,$otu0;
my $otuname=shift @otu;
system("sort $otu0|uniq -u  >$otuname\_su.txt");
system("sort $otu0|uniq -d  >$otuname\_head.txt");
system("cat $otuname\_head.txt $otuname\_su.txt>$otuname.trans.txt");
open IN,$group or die $!;
my %group;
while(<IN>){
	chomp;
	my @tab=split/\t/,$_;
	$group{$tab[0]}=$tab[1];

}
close IN;
open IN,"$otuname.trans.txt" || die "can not open $otuname.trans.txt\n";
open OUT,">$out" || die "can not open $out\n";
my $header=<IN>;
my @headers=split/\t/,$header;
shift @headers;
chomp @headers;
my $otu;my $samples;
foreach my $sample(@headers){$otu.="$group{$sample}\t";$samples.="$sample\t";}
chop $otu;chop $samples;
print OUT "class\t$otu\n";
print OUT "Taxon\t$samples\n";
while(<IN>){
           chomp;
           my @tab=split/\t/,$_;
           #s/\w\_\_//g;
           #s/\[//g;s/\]//g;
           s/;/\|/g;
           next if(/\|\w\_\_\t/ or /Other\t/);
           print OUT "$_\n";
}
close IN;
close OUT;
system("rm -f $otuname\_head.txt $otuname\_su.txt");
