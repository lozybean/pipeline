#!/usr/bin/env perl
die "perl $0 <L2.txt> <L1.txt>" unless(@ARGV==2); 
my ($txt,$out)=@ARGV;
my %subject1;
my %taxonprofiling;
my %taxonprofile;
open IN,$txt || die "can not open $txt\n";
open OUT,">$out" || die "can not open $out\n";
my $header=<IN>;
my @samples=split/\t/,$header;
shift @samples;
print OUT $header;
while(<IN>){
           chomp;
           my @tab=split/\t/,$_;
           my @subjects=split/\;/,$tab[0];
           $subject1{$subjects[0]}=$subjects[1];
           for(my $i=1;$i<@tab;$i++){
                      $taxonprofiling{$subjects[1]}{$samples[$i-1]}=$tab[$i];
               }
}
for my $sub1(keys%subject1){
        my $profile;
        for my $sample(@samples){
                   for my $subject(keys%taxonprofiling){
                             $taxonprofile{$sample}+= $taxonprofiling{$subject}{$sample};
                   }
                   $profile.="$taxonprofile{$sample}\t";
        }
        chop $profile;
        print OUT "$sub1\t$profile\n";
}               
close IN;
close OUT;

