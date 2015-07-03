#!/usr/bin/perl
use strict;
use	FindBin qw($Bin);
my $ss = "$Bin/ss.o"; 
die "usage: perl $0 list cutoff\n" unless @ARGV==2;
my ($list_file,$cutoff) = @ARGV;

print "sample_name\tTotal_number|Total_number(>$cutoff)\tTotal_length_bp|Total_length_bp(>$cutoff)\tGap_number_bp|Gap_number_bp(>$cutoff)\tAverage_length_bp|Average_length_bp(>$cutoff)\tN50_length|N50_length(>$cutoff)\tN90_length|N90_length(>$cutoff)\tMaximum_length|Maximum_length(>$cutoff)\tMinimum_length|Minimum_length(>$cutoff)\tGC_content|GC_content(>$cutoff)\n";
open LIST,$list_file or die $!;
my @out;
while(<LIST>){
	chomp;
	my @tabs = split /\s+/;
	my ($sample_name,$in_file) = @tabs;
	open IN,$in_file or die $!;
	<IN>;<IN>;<IN>;
	my $line_num = 0;
	while(<IN>){
		chomp;
		my $line = $_;
		next unless $line;
		my @tabs = split /\t/;
		shift @tabs;shift@tabs;
		my $text = join(" ",@tabs);
		my @a = split /\s+/,$text;
		$out[$line_num] = "$a[0]|$a[3]";
		$line_num++;
	}
	close IN;
	$" = "\t";
	print "$sample_name\t@out\n";
}
close LIST;
