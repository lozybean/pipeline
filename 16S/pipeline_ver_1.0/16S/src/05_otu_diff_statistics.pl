#!/usr/bin/env perl
die "perl $0 <diff.marker.txt><assign.txt>" unless(@ARGV==2); 
my ($otu0,$otuid)=@ARGV;
my @otu=split/\./,$otu0;
my $otuname=shift @otu;
my %taxnum;
open IN,$otuid || die "can not open $otuid\n";
while(<IN>){
        chomp;
        my @tab=split/\t/,$_;
        my @tax=split/;/,$tab[1];
        my $tax=pop @tax;
        $taxnum{$tab[0]}=$tax;
}
close IN;
open IN,$otu0 || die "can not open $otu0\n";
open OUT,">$otuname.diff.marker.statistics.txt"|| die "can not open $otuname.diff.marker.statistics.txt\n";
my $headers=<IN>;
chomp $headers;
print OUT "$headers\tTaxonomy\n";
while(<IN>){
        chomp;
        my @tab=split/\t/,$_;
	print OUT "$_\t$taxnum{$tab[0]}\n";
}
close IN;
close OUT;
