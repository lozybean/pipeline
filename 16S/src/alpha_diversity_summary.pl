#!/usr/bin/perl
use strict;
use File::Basename;
die "perl $0 <alpha_all.txt>" unless(@ARGV==1);
my ($alpha)=@ARGV;
my @alpha=split/\./,$alpha;
my $alphaname=shift @alpha;
my $alphabase=basename($alphaname);
system("sed -n '1p' $alpha>$alphaname.head.txt");
system("sed -n '\$p' $alpha>$alphaname.tail.txt");
system("cat $alphaname.head.txt $alphaname.tail.txt>$alphaname.alpha.txt");
my %alpha;
open IN,"$alphaname.alpha.txt" || die "can not open $alphaname.alpha.txt\n";
open OUT,">$alphaname.w.txt" || die "can not open $alphaname.w.txt\n";
my $header=<IN>;
my @headers=split/\t/,$header;
shift @headers;shift @headers;shift @headers;
print OUT "alphaname\t@headers";
while(<IN>){
          chomp;
          my @tab=split/\t/,$_;
          shift @tab;shift @tab;shift @tab;
          print OUT "$alphabase\t@tab\n";
}
close IN;
close OUT;
