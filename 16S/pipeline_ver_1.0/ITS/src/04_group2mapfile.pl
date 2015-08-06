#!/usr/bin/env perl
die "perl $0 <group.txt><map.txt>" unless(@ARGV==2);
#choice:sample,group,time
my($group,$map)=@ARGV;
my %groups;
open IN,$group || die "can not open $group\n";
open OUT,">$map" || die "can not open $map\n";
print OUT "#SampleID\tDescription\n";
print OUT "#Example mapping file for the QIIME analysis package.\n";
while(<IN>){
        chomp;
        my @tab=split/\t/,$_;
	print OUT $_."\n";
}
close IN;
close OUT;
