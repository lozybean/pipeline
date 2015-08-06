#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Getopt::Long;
use File::Basename;



my($input, $out, $help);
GetOptions("input:s" =>\$input, "out:s" => \$out, "help|?" => \$help);
if(!defined $input || !defined $out || defined $help){
	print STDERR << "USAGE";
	options:
	-input:plesae inout big file of together.fa
	-out: out two file ,example single.fa, mul.fa
	-help:
USAGE
	exit 1;
}

my $title;
my $seq;
my %read;
my %read_size;
my @array;
my $all=0;
my $rm_single=0;
my $single=0;
my $mul_number=0;
open(IN , $input) or die $!;
open(SIN, ">$out/single.fa") or die $!;
open(MUL, ">$out/mul.fa") or die $!;
open(DER, ">$out/derep.fa") or die $!;
open(REM, ">$out/remove_single.fa") or die $!;
while(my $line = <IN>){
	chomp($line);
	$title = $line;
	$seq = <IN>;
	chomp($seq);
	$all=$all+1;
	if(exists $read{$seq}){
		$rm_single=$rm_single+1;
		$read_size{$seq} = $read_size{$seq}+1;
		print REM "$title\n";
		print REM "$seq\n";
	}else{
		$read{$seq} = $title;
		$read_size{$seq} = 1;
	}
}
close IN;
foreach my $key(keys %read_size){
	print DER "$read{$key};size=$read_size{$key};\n";
	print DER "$key\n";
	if($read_size{$key}==1){
		$single=$single+1;
		print SIN "$read{$key};size=$read_size{$key};\n";
		print SIN "$key\n";
	}else{
		$mul_number=$mul_number+$read_size{$key};
		print MUL "$read{$key};size=$read_size{$key};\n";
		print MUL "$key\n";
	}
}
close SIN;
close MUL;
close DER;
print "all\trm_single\tsingle\tmul_number\n";
print "$all\t$rm_single\t$single\t$mul_number\n";
