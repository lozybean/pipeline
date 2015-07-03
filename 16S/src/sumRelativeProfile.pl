#!/usr/bin/perl
use strict;
my @tax_name = ("kingdom","phylum","class","order","family","genus","species");
my %tax;
my %tax_all;
my %kingdom;my %phylum;my %class;my %order;my %family;my %genus;my %species;
open IN,"03_09_rdp_qiimeform.tax" or die $!;
while(<IN>){
	chomp;
	my @tabs = split /\t/;
	my ($otu,$tax) = @tabs;
	next if $tax eq "";
	my @taxes = split /;/,$tax;
	my $tax_deep = pop @taxes;
	$tax{$otu} = $tax_deep;
	$tax_all{$otu} = $tax;
}
close IN;

open IN,"03_10_otu_table.profile" or die $!;
<IN>;
chomp(my $text = <IN>);
my @tabs = split /\t/,$text;shift @tabs;
my @samples = @tabs;
$" = "\t";
my %profile_sum;
my %profile;
my $otu_num=0;

while(<IN>){
	chomp;
	my @tabs = split /\t/;
	my $otu = shift @tabs;
	next unless exists $tax{$otu};
	$otu_num ++;
	for(my $i=0;$i<@tabs;$i++){
		$profile{$otu}{$samples[$i]} = $tabs[$i];
		$profile_sum{$samples[$i]} += $tabs[$i];
	}
}
close IN;

my %relative;
my %tax_tree_relative;
my %tax_tree;
open OUT,">relative.profile" or die $!;
$" = "\t";
print OUT "#OTU ID\ttax\t@samples\n";
foreach my $otu(sort keys %profile){
	my @profile_out;
	foreach my $sample(sort keys %{$profile{$otu}}){
		my $relative = $profile{$otu}{$sample} / $profile_sum{$sample} * 100000;
		if($relative){
			$relative{$sample}{$otu} = $relative;
			my @taxes;
			@taxes = split /;/,$tax_all{$otu};
#			push(@taxes,"unidentified") unless @taxes>=6;
#			print "$otu\t$tax_all{$otu}\t@taxes\n";
			my $tax_long = $taxes[0];
			$tax_tree_relative{$sample}{$tax_long} += $relative;
			for(my $i=1;$i<@taxes;$i++){
				$tax_long = "$tax_long;$taxes[$i]";
				$tax_tree_relative{$sample}{$tax_long} += $relative;
			}
#			if(@taxes == 6){
			$tax_long = "$tax_long;$otu";
				$tax_tree_relative{$sample}{$tax_long} += $relative;
#			}
			my $tax_all = join(";",@taxes);
			$tax_all= "$tax_all;$otu" ;#if @taxes == 6;
			$tax_tree{$sample}{$tax_all} ++;
		}
		push (@profile_out,$relative);
	}
	$" = "\t";
	print OUT "$otu\t$tax{$otu}\t@profile_out\n";
}
close OUT;

chomp(my $Bin = `pwd`);
`mkdir -p $Bin/relative`;
foreach my $sample (sort keys %relative){
	$sample =~ /16S(\S+)/;
	my $file_base = $1;
	$file_base =~ s/\./-/g;
=cut1	
	open OUT,">$Bin/relative/$file_base.xls" or die $!;
	open OUT_Acti,">$Bin/relative/$file_base\_Actinobacteria.xls" or die $!;
	open OUT_Baci,">$Bin/relative/$file_base\_Bacillus.xls" or die $!;
	foreach my $otu(sort keys %{$relative{$sample}}){
		print OUT "$tax_all{$otu}\t$relative{$sample}{$otu}\n";
		print OUT_Acti "$tax_all{$otu}\t$relative{$sample}{$otu}\n" if $tax_all{$otu} =~ /p__Actinobacteria/;
		print OUT_Baci "$tax_all{$otu}\t$relative{$sample}{$otu}\n" if $tax_all{$otu} =~ /g__Bacillus/;
	}
	close OUT;
	close OUT_Acti;
	close OUT_Baci;
=cut
	open OUT,">$Bin/relative/$file_base.tree.xls" or die $!;	
	open OUT_Acti,">$Bin/relative/$file_base\_Actinobacteria.tree.xls" or die $!;
	open OUT_Baci,">$Bin/relative/$file_base\_Bacillus.tree.xls" or die $!;
	my %tax_out;
	my %tax_child;
	foreach my $tax_all(sort keys %{$tax_tree{$sample}}){
		my @taxes = split /;/,$tax_all;
		$tax_out{'kingdom'}{$taxes[0]} ++;
		my $tax_long = $taxes[0];
		for( my $i=1;$i<@taxes;$i++){
			my $s_tax = $tax_long;
			$tax_long = "$tax_long;$taxes[$i]";
			$tax_child{$s_tax}{$tax_long} ++;
		}
#		$tax_child{$taxex[@taxes]}{$otu}++;
	}
	my $if_Acti = 0;
	my $if_Baci = 0;
	my $tax_text = '';
	
	foreach my $kingdom(sort keys %{$tax_out{'kingdom'}}){
		$tax_text = ( split /;/,$kingdom)[-1];
		print OUT "$tax_text\t$tax_tree_relative{$sample}{$kingdom}\n";
		foreach my $phylum(sort keys %{$tax_child{$kingdom}}){
			$tax_text = (split /;/,$phylum)[-1];
			#		print $tax_text;
			print OUT "\t$tax_text\t$tax_tree_relative{$sample}{$phylum}\n";
			if ($phylum =~ /Actinobacteria/ ){
				$if_Acti = 1;
			}else{
				$if_Acti = 0;
			}
			print OUT_Acti "$phylum\t$tax_tree_relative{$sample}{$phylum}\n" if $if_Acti;
			foreach my $class(sort keys %{$tax_child{$phylum}}){
				$tax_text = (split /;/,$class)[-1];
				print OUT "\t\t$tax_text\t$tax_tree_relative{$sample}{$class}\n";
				print OUT_Acti "\t$tax_text\t$tax_tree_relative{$sample}{$class}\n" if $if_Acti;
				foreach my $order(sort keys %{$tax_child{$class}}){
					$tax_text = (split /;/,$order)[-1];
					print OUT "\t\t\t$tax_text\t$tax_tree_relative{$sample}{$order}\n";
					print OUT_Acti "\t\t$tax_text\t$tax_tree_relative{$sample}{$order}\n" if $if_Acti;
					foreach my $family(sort keys %{$tax_child{$order}}){
						$tax_text = (split /;/,$family)[-1];
						print OUT "\t\t\t\t$tax_text\t$tax_tree_relative{$sample}{$family}\n";
						print OUT_Acti "\t\t\t$tax_text\t$tax_tree_relative{$sample}{$family}\n"  if $if_Acti;
						foreach my $genus(sort keys %{$tax_child{$family}}){
							if ($genus =~ /Bacillus/){
								$if_Baci = 1;
							}else{
								$if_Baci = 0;
							}
							$tax_text = (split /;/,$genus)[-1];
							print OUT "\t\t\t\t\t$tax_text\t$tax_tree_relative{$sample}{$genus}\n";
							print OUT_Acti "\t\t\t\t$tax_text\t$tax_tree_relative{$sample}{$genus}\n" if $if_Acti;
							print OUT_Baci "$tax_text\t$tax_tree_relative{$sample}{$genus}\n" if $if_Baci;
							foreach my $species(sort keys %{$tax_child{$genus}}){
								$tax_text = (split /;/,$species)[-1];
								print OUT "\t\t\t\t\t\t$tax_text\t$tax_tree_relative{$sample}{$species}\n";
								print OUT_Acti  "\t\t\t\t\t$tax_text\t$tax_tree_relative{$sample}{$species}\n" if $if_Acti;
								print OUT_Baci  "\t$tax_text\t$tax_tree_relative{$sample}{$species}\n" if $if_Baci;
							}
						}
					}
				}
			}
		}
	}
	print "###\n";
}

