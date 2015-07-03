#!/usr/bin/perl
use strict;
my $ucfile = shift @ARGV;
my $tablefile = shift @ARGV;
open IN,$ucfile or die $!;
my %denovo;
while(<IN>){
	next if /\*/;
	chomp;
	my @a =split /\t/;
	my $id = $a[8];
	$id =~ /(\S+) \S+ \S+ \S+ \S+/;
	$id = $1;
	my $n = $a[9];
	$n =~ /denovo_(\d+)/;
	$n = $1;
	$denovo{$n}[0]++;
	push @{$denovo{$n}},$id;
}
close IN;
open OUT,">$tablefile" or die $!;
foreach my $n(sort {$a<=>$b} keys %denovo){
	print OUT "denovo_$n\t";
	shift @{$denovo{$n}};
	$" = "\t";
	print OUT "@{$denovo{$n}}\n";
}
close IN;
