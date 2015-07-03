#!/usr/bin/perl
use strict;
my %tax_info = (
"k"=>"kingdom","p"=>"phylum","c"=>"class","o"=>"order","f"=>"family","g"=>"genus","s"=>"species",
);
my %tax_num;
my $file = shift @ARGV;
open IN,$file or die $!;
while(<IN>){
	chomp;
	my @tabs = split /\t/;
	my($otu_name,$tax_ass) = @tabs;
	my @taxs = split /;/,$tax_ass;
	my $tax_acc = pop @taxs;
	$tax_acc =~ /(\w)__(\w+)/;
	my $tax_char = $1;
#	print "$tax_char\n";
	$tax_num{$tax_info{$tax_char}}++;
}
close IN;
open OUT,">$file.summary" or die $!;
foreach my $tax_name(sort keys %tax_num){
	print OUT "$tax_name\t$tax_num{$tax_name}\n";
}
close OUT;
