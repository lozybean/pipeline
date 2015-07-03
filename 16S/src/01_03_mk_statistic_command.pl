#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

die "<miseq_pe.list> <pandaseq.list> <03_pandaseq_concatenated_sequence_QC.list> <output_dir> <which_perl> <project_ID> <node_group> <scripts_dir>" unless @ARGV == 8;
my $pwd = getcwd();
my $scripts_dir = $ARGV[7];
-e -d $ARGV[3] || mkdir $ARGV[3];
-e -d "$ARGV[3]/cmd" || mkdir "$ARGV[3]/cmd";

open MISEQ, "$ARGV[0]" or die $!;
my %path;
while(<MISEQ>){
    chomp;
    my $sname = $_;
    $sname =~ s/.*\/([^\/]+)(?:_|\.)[12]\.fq$/$1/;
    
    if(exists $path{$sname}){
        push @{$path{$sname}}, $_;
    }else{
        $path{$sname} = [$_];
    }
}
close MISEQ;

open PANDA, "$ARGV[1]" or die $!;
while(<PANDA>){
    chomp;
    my $sname = $_;
    $sname =~ s/.*\/([^\/]+)\.fq$/$1/;
    
    if(exists $path{$sname}){
        push @{$path{$sname}}, $_;
    }else{
        die "we extracted a sample name, $sname, from $_.\nHowever, this name doesn't exist?\n";
    }
}
close PANDA;

open QC, "$ARGV[2]" or die $!;
while(<QC>){
    chomp;
    my $sname = $_;
    $sname =~ s/.*\/([^\/]+)\.fna$/$1/;
    
    if(exists $path{$sname}){
        push @{$path{$sname}}, $_;
    }else{
        die "we extracted a sample name, $sname, from $_.\nHowever, this name doesn't exist?\n";
    }
}
close QC;

open QSUB, ">$pwd/01_pandaseq_QC/03_statistic.qsub" or die $!;
print QSUB "[[ -d $pwd/qsub_directory ]] && rm -f $pwd/qsub_directory/*\n";
open LIST, ">$pwd/01_pandaseq_QC/03_statistic.list" or die $!;
-e -d "$pwd/qsub_directory" || mkdir "$pwd/qsub_directory";
foreach my $sample (keys %path){
    my @dir = @{$path{$sample}};
    if(@dir != 4){
        die "sample $sample has only:\n", (join "\n", @dir), "\n";
    }
    my $dir = join " ", @dir;
    open OUT, ">$ARGV[3]/cmd/s$sample.command" or die $!;
    print OUT "$ARGV[4] $scripts_dir/01_03_statistic.pl $dir $ARGV[3] $sample.statistic\n";
    #$0 <pe1> <pe2> <concatenated_sequence.fq> <fna> <output_dir> <output>
    close OUT;
    
    print QSUB "qsub -cwd -l vf=5G -o $pwd/qsub_directory -e $pwd/qsub_directory -N $ARGV[5] -q $ARGV[6] $ARGV[3]/cmd/s$sample.command\n";
    
    print LIST "$ARGV[3]/$sample.statistic\n";
}
close LIST;
close QSUB;



