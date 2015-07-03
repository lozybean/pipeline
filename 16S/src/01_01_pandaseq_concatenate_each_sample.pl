#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

die "$0 <miseq_pe_list> <quality_system> <output_dir> <output_pandaseq_command_qsub> <output_pandaseq_output_list> <which_pandaseq> <forward_primer> <reverse_primer> <project_ID> <node_group>" unless @ARGV == 10;

my $work_dir = $ARGV[2];

-e -d $work_dir || mkdir $work_dir;
-e -d "$work_dir/cmd" || mkdir "$work_dir/cmd";
-e -d "$work_dir/qsub_directory" || mkdir "$work_dir/qsub_directory";

my ($sname1, $sname2);

open LIST, "$ARGV[0]" or die $!;
open QSUB, ">$ARGV[3]" or die $!;
print QSUB "[[ -d $work_dir/qsub_directory ]] && rm -f $work_dir/qsub_directory/*\n";
open OUTLIST, ">$ARGV[4]" or die $!;
while(my $dir1 = <LIST>){
    chomp($dir1);
    if($dir1 =~ /\/([^\/]+)(?:_|\.)[12]\.fq$/g){
        $sname1 = $1;
    }else{
        die "failed to find the sample name of pe1: $dir1\n";
    }
    
    my $dir2 = <LIST>;
    
    chomp($dir2);
    if($dir2 =~ /\/([^\/]+)(?:_|\.)[12]\.fq$/g){
        $sname2 = $1;
    }else{
        die "failed to find the sample name of pe2: $dir2\n";
    }
    
    unless($sname1 eq $sname2){
        die "sample names are different:\n$dir1\n$dir2\n";
    }
    
    open CMD, ">$work_dir/cmd/sample_$sname1.cmd" or die $!;
    my $cmd = "$ARGV[5] -f $dir1 -r $dir2 -p $ARGV[6] -q $ARGV[7] -F -T 3";
    if($ARGV[1] == 64){
        $cmd .= " -6"
    }elsif($ARGV[1] != 33){
        die "they quality system $ARGV[1] doesn't exist, the allowed quality system are either 64 or 33\n";
    }
    $cmd .= " -w $work_dir/$sname1.fq -g $work_dir/$sname1.log\n";
    print CMD $cmd;
    close CMD;
    print QSUB "qsub -cwd -l vf=5G -o $work_dir/qsub_directory -e $work_dir/qsub_directory -N $ARGV[8] -q $ARGV[9] $work_dir/cmd/sample_$sname1.cmd\n";
    print OUTLIST "$work_dir/$sname1.fq\n";
}
close OUTLIST;
close QSUB;
close LIST;






