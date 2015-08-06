#!/usr/bin/env perl
die "perl $0 <map.uc> <output.table>" unless(@ARGV==2);
my($map,$out)=@ARGV;
open IN,$map || die "can not open $map\n";
my %otus;
while(<IN>){
        chomp;
        my @tab=split/\t/,$_;
        my @sample=split/\s+/,$tab[8];
        $otus{$tab[9]}.="$sample[0]\t";
}
close IN;
open OUT,">$out" || die "can not open $out\n";
foreach my $otu(keys%otus){
	chop  $otus{$otu};
        next if($otu=~/\*/);
        print OUT "$otu\t$otus{$otu}\n";
}
close OUT;

