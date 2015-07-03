#!/usr/bin/perl
use strict;
my ($file,$outfile) = @ARGV;
my %stat;
open IN,$file or die $!;
$/ = '>';
<IN>;
while(<IN>){
	chomp;
	my @lines = split /\n/;
	my $head = shift @lines;
	my $seq = join("",@lines);
	$head =~ /(\S+)_/;
	my $sample_name = $1;
	my $length = length($seq);
	$stat{$sample_name}{'min_length'} = $length unless exists $stat{$sample_name}{'min_length'};
	$stat{$sample_name}{'min_length'} = $length if $stat{$sample_name}{'min_length'} > $length;
	$stat{$sample_name}{'max_lenght'} = $length unless exists $stat{$sample_name}{'max_length'};
	$stat{$sample_name}{'max_length'} = $length if $stat{$sample_name}{'max_length'} < $length;
	$stat{$sample_name}{'total_length'} += $length;
	$stat{$sample_name}{'reads_num'} ++;
}
close IN;

open OUT,">$outfile" or die $!;
print OUT "SampleID\tHQ Reads\tMinLen\tMaxLen\tMeanLen\n";
foreach my $sample_name (sort keys %stat){
	my $min = $stat{$sample_name}{'min_length'};
	my $max = $stat{$sample_name}{'max_length'};
	my $reads_num = $stat{$sample_name}{'reads_num'};
	my $mean = $stat{$sample_name}{'total_length'} / $reads_num;
	print OUT "$sample_name\t$reads_num\t$min\t$max\t$mean\n";
}
close OUT;
