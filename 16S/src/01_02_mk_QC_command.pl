#!/usr/bin/perl
use warnings;
use strict;
use FindBin qw($Bin $Script);
use Cwd;


die "$0 <pandaseq.list> <average_quality_value_cutoff_system+Qvalue> <max_N> <min_sequence_length> <max_sequence_lengh> <output_dir> <which_perl> <project_ID> <node_group>" unless @ARGV == 9;

my $work_dir = $ARGV[5];

my $pwd =getcwd(); 
my $changeid_dir = "$pwd/01_02_QC_change_id.pl";
-f "$pwd/01_02_QC_change_id.pl" || die "script, $changeid_dir, doesn't exist, have you copied the scripts directory to the current work directory?\n";
-e -d $work_dir || mkdir $work_dir;
-e -d "$work_dir/cmd" || mkdir "$work_dir/cmd";
-e -d "$work_dir/qsub_directory" || mkdir "$work_dir/qsub_directory";

open LIST, "$ARGV[0]" or die $!;
open QSUB, ">$work_dir/../../01_02_pandaseq_concatenated_sequence_QC.qsub" or die $!;
print QSUB "[[ -d $work_dir/qsub_directory ]] && rm -f $work_dir/qsub_directory/*\n";
open OUT, ">$work_dir/../../01_pandaseq_QC/02_pandaseq_concatenated_sequence_QC.list" or die $!;
while(my $dir = <LIST>){
    chomp($dir);
    my $fq = $dir;
    $fq =~ s/.*\/([^\/]+)\.fq$/$1/;
    my $fqorigninal = $fq;
    $fq =~ s/^([0-9]+)$/SSS$1/;
    
    
    open CMD, ">$work_dir/cmd/$fq.command" or die $!;
    print CMD "$ARGV[6] $changeid_dir $dir $ARGV[1] $ARGV[2] $ARGV[3] $ARGV[4] $work_dir/$fqorigninal.fna\n";
    #$0 <concatenated.fq> <average_quality_value_cutoff_system+Qvalue> <max_N> <min_length> <max_length> <output>
    close CMD;
    
    print OUT "$work_dir/$fqorigninal.fna\n";
    print QSUB "qsub -cwd -l vf=5G -o $work_dir/qsub_directory -e $work_dir/qsub_directory -N $ARGV[7] -q $ARGV[8] $work_dir/cmd/$fq.command\n";
}
close OUT;
close QSUB;
close LIST;
