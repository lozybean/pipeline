#!/usr/bin/env perl
die "perl $0 [otu_table_all_CF.0mvs12m.diff.marker.for_draw.xls][otu_table_all_CF.0mvs12m.diff.marker.xls]" unless(@ARGV==2);
open IN, $ARGV[0] || die $!;
<IN>;
my %group;
my %taxs;
my @samples;
my %samples_group;
while(<IN>){
	chomp;
	my @t=split/\t/,$_;
	push @samples,$t[0] if(!exists $samples_group{$t[0]});
	$samples_group{$t[0]}=$t[3];
	$taxs{$t[1]}{$t[3]}{$t[0]}=$t[2];
	$group{$t[3]}=1;
} 
close IN;

open OUT, ">$ARGV[1]" || die $!;
my $sample_names;
foreach my $group (sort {$a cmp $b} keys %group){
	foreach my $sample(@samples){
		$sample_names.="\t$sample" if($samples_group{$sample} eq $group);
	}	
	#$sample_names.="\t$group";
}
print OUT "Tax$sample_names\n";

foreach my $tax(sort {$a cmp $b} keys %taxs){
	print OUT "$tax";
	foreach my $group (sort {$a cmp $b} keys %group){
		my $sample_percents;
		my $sample_num;
		my $average;
		foreach my $sample(@samples){
			if($samples_group{$sample} eq $group){
				$sample_num++;
		                $sample_percents.="\t$taxs{$tax}{$group}{$sample}";
				$average+=$taxs{$tax}{$group}{$sample}
			}
        	}
		$average=$average/$sample_num;
		print OUT "$sample_percents";
	}
	print OUT "\n";
}
close OUT;
