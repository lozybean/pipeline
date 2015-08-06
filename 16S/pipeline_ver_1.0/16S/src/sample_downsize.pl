#!/usr/bin/env perl
use strict;
use warnings;
use List::Util qw(shuffle);

die "$0 <otu_to_downsize> <pick_number> <Y/N_keep_small_size_sample><out>" unless @ARGV == 4;

open IN, "$ARGV[0]" or die "$ARGV[0]";
my %sample_number;
my %samples;
my @title = ();
while(<IN>){
	chomp;
        my @tab= split /\t/,$_;
        foreach(my $i=1;$i<@tab;$i++){
		$samples{$tab[$i]}=$tab[0];
		push @title,$tab[$i];
		if($tab[$i]=~m/(\S+)\_\w+$/){
			$sample_number{$1}++;
		}
	}
}
close IN;

#print "2\n";

my @min = sort { $sample_number{$a} <=> $sample_number{$b} } (keys %sample_number);
my %small_sample;
for my $small (@min){
	if( $sample_number{$small} < $ARGV[1]){
		$small_sample{$small} = $sample_number{$small};
		delete $sample_number{$small};
	}else{
		last;
	}
}

if( (keys %small_sample) > 0){
	my @small_sample = keys %small_sample;
	if($ARGV[2] eq "Y"){
		for my $key (keys %small_sample){
			$sample_number{$key} = $small_sample{$key};
		}
		print "warnings: some samples, @small_sample, have too fewer reads, but they are still kept\n";
	}elsif($ARGV[2] eq "N"){
		print "some samples, @small_sample, have too fewer reads. These small samples will be removed\n";
	}else{
		die "\n*************argument 3 shold be 'Y' or 'N'*********\n";
	}
}
my $min = $ARGV[1];


@title = shuffle @title;

my %read_count;
map {$read_count{$_} = 0} keys %sample_number;

my @final_list;
for my $value ( @title ){
    $value=~/(\S+)\_\w+$/;
    my $sample = $1;
    if(exists $read_count{$sample}){
        if($read_count{$sample} < $min ){
            $read_count{$sample}++;
            push @final_list, $value;
        }
    }
}

my %otus;
foreach my $sample(@final_list){
	my $otu=$samples{$sample};
	$otus{$otu}.="$sample\t";
}
open OUT, ">$ARGV[3]" or die "$ARGV[3]";
foreach my $otuname(keys%otus){
	chop $otus{$otuname};
	print OUT "$otuname\t$otus{$otuname}\n";
#print "3\n";
}
close OUT;
