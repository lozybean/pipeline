#!/usr/bin/env perl
use File::Basename;
#use List::AllUtils qw(min max);
die "perl $0 <rdp_assign.txt><otu.txt>" unless(@ARGV==2);
my($seqs,$otus)=@ARGV;
my $dir=dirname($seqs);
open IN,$seqs || die "can not open $seqs\n";
my %taxa;
my %name;
my $otu;
while(<IN>){
	chomp;
	my @tab=split/\t/,$_;
	$otu++;
	if($tab[1]=~m/(k)\_\_\w+/){$taxa{$1}++;}
	if($tab[1]=~m/k\_\_\w+\;(p)\_\_\w+/){$taxa{$1}++;}
	if($tab[1]=~m/k\_\_\w+\;p\_\_\w+\;(c)\_\_\w+/){$taxa{$1}++;}
	if($tab[1]=~m/k\_\_\w+\;p\_\_\w+\;c\_\_\w+\;(o)\_\_\w+/){$taxa{$1}++;}
	if($tab[1]=~m/k\_\_\w+\;p\_\_\w+\;c\_\_\w+\;o\_\_\w+\;(f)\_\_\w+/){$taxa{$1}++;}
	if($tab[1]=~m/k\_\_\w+\;p\_\_\w+\;c\_\_\w+\;o\_\_\w+\;f\_\_\w+\;(g)\_\_\w+/){$taxa{$1}++;}
	if($tab[1]=~m/k\_\_\w+\;p\_\_\w+\;c\_\_\w+\;o\_\_\w+\;f\_\_\w+\;g\_\_\w+\;(s)\_\_\w+/){$taxa{$1}++;}
}
close IN;
open OUT,">$dir/otu_statistics.txt" || die $!;
print OUT "No. of OTUs\t$otu\n";
my $taxa="k\tp\tc\to\tf\tg\ts";
my @taxa=split/\t/,$taxa;
foreach my $taxon(@taxa){
	print $taxon;
	if($taxon eq "k"){$name{$taxon}="Assigned to Kingdom";}
	elsif($taxon eq "p"){$name{$taxon}="Assigned to Phylum";}
	elsif($taxon eq "c"){$name{$taxon}="Assigned to Class";}
	elsif($taxon eq "o"){$name{$taxon}="Assigned to Order";}
	elsif($taxon eq "f"){$name{$taxon}="Assigned to Family";}
	elsif($taxon eq "g"){$name{$taxon}="Assigned to Genus";}
	elsif($taxon eq "s"){$name{$taxon}="Assigned to Species";}
	print OUT "$name{$taxon}\t$taxa{$taxon}\n";
}
open IN,$otus or die $!;
my %group;my @Num;
while(<IN>){
        my @a = split /\t/;
        my $b = shift @a;
        my $num =substr($b,6,length($b)-6);
        foreach my $name(@a){
                if($name=~/(\S+)\_\w+$/){
                        $group{$1}.="$num\t";
                }
        }
}
close IN;
open OUT1,">$dir/sample_otu_statatistics.txt" || die $!;
print OUT1 "Sample\tOTU_Reads_Num\tOTU_Num\n";
foreach my $name(sort keys%group){
        chop $group{$name};
        my @nums=split/\t/,$group{$name};
        my @uniq=&uniq(@nums);
        @uniq=sort{$a <=>$b}@uniq;
        push @Num,scalar(@uniq);
	print OUT1 "$name\t".scalar(@nums)."\t".scalar(@uniq)."\n";
}
close OUT1;
@Num=sort{$b <=>$a}@Num;
my @mean=&means(@Num);
my $max=shift @Num;
my $min=pop @Num;
#my $sd=&means(@Num)[1];
print OUT "Min no. of OTUs per sample\t$min\n";
print OUT "Max no. of OTUs per sample\t$max\n";
print OUT "Mean no. of OTUs per sample\t$mean[0]\n";
print OUT "Sd no. of OTUs per sample\t$mean[1]\n";
close OUT;
sub uniq{
        my %seen;
        my @unique;
        foreach my $value (@_) {
                if (! $seen{$value}) {
                        push @unique, $value;
                        $seen{$value} = 1;
                }
        }
return(@unique);
}
sub means{
        my $aver = 0;
        my $sd=0;
        map{$aver += $_} @_;
        $aver /=scalar@_;
	map{$sd=($_-$aver)**2} @_;
        $sd=($sd/scalar@_)**0.5;
	my @mean;
	$mean[0]=$aver;$mean[1]=$sd;
	return @mean;
}


