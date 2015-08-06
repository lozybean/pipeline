#!/usr/bin/env perl
die "perl $0 <otu.txt> <seqs.fna><out_seqs.fna>" unless(@ARGV==3);
my($otu,$seqs,$out)=@ARGV;
open IN,$otu || die "can not open $otu\n";
my @samples;
my %seq;
while(<IN>){
        chomp;
        my @tab=split/\t/,$_;
        foreach(my $i=1;$i<@tab;$i++){
        	push @samples,$tab[$i];}
}
close IN;
open IN,$seqs || die "can not open $seqs\n";
$/=">";
while(<IN>){
	my @tab=split/\n/,$_;
	if($tab[0]=~/^(\S+)$/){
	$seq{$1}=$tab[1];}
}	
close IN;
#$/="\n";
open OUT,">$out" || die "can not open $out\n";
foreach my $sample(@samples){
        print OUT ">$sample\n$seq{$sample}\n";
}
close OUT;

