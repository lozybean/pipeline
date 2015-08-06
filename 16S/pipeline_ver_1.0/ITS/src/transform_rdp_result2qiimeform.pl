#!/usr/bin/env perl
use strict;
use warnings;

die "$0 <rdp_tax> <confidence_cutoff> <qiime.tax> <16s/ITS>" unless @ARGV == 4;
die "argument 4 must be either ITS or 16s/16S" unless($ARGV[3] eq "ITS" or $ARGV[3] eq "16S" or $ARGV[3] eq "16s");

my @tax_levels = ("domain", "phylum", "class", "order", "family", "genus", "species");
my @tax_levels_letter = ("k", "p", "c", "o", "f" , "g", "s");

open IN, "$ARGV[0]" or die $!;
open OUT, ">$ARGV[2]" or die $!;
while(<IN>){
    my @tax_letter = @tax_levels_letter;
    $_ =~ s/"|'//g;
    my @line = split /\s+/;
    my $otu = shift @line;
    my $conf;
    
    my @tax;
    if($line[0] eq "Root"){
        shift @line;
        shift @line;
        shift @line;
    }elsif($line[0] eq "-"){
    	shift @line;
        shift @line;
        shift @line;
        shift @line;
    }else{
    	die "this rdp output file has strange format, modify this script please\n";
    }


    while(@line > 0){
        my (@subtax, $tax, $level, $confidence);
        while($level = shift @line){
            if($level ~~ @tax_levels){
                $confidence = shift @line;
                last;
            }elsif($level =~ /^sub/){
                @subtax = ();
                shift @line;
                next;
            }else{
                push @subtax, $level;
            }
        }
        
        $tax = join "_", @subtax;
        $tax =~ s/\"//g;
        my $firstletter;
        if($level eq "domain"){
            $firstletter = "k"
        }else{
            $firstletter = substr($level, 0, 1);
        }
        
        if($firstletter eq $tax_letter[0]){
            shift @tax_letter;
        }else{
            while($firstletter ne $tax_letter[0] and @tax_letter > 0){
                my $letter = shift @tax_letter;
                push @tax, "${letter}__unidentified";
            }
            shift @tax_letter;
        }
        if($confidence >= $ARGV[1]){
            $tax = "${firstletter}__$tax";
            $conf = $confidence;
        }else{
            last;
        }
        push @tax, $tax;
    }
        

    
    my $middle = join "\;", @tax;
    print OUT "$otu\t$middle\t$conf\n";
}
close OUT;
close IN;


