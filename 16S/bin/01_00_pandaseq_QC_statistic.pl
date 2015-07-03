#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin $Script);
use lib "$Bin/../lib";
use File::Basename qw(basename dirname);
use Cwd 'abs_path';

die "usage:perl $0 config_file" unless @ARGV==1;

my $config_file = shift @ARGV;
my $pwd = getcwd();
open COMMAND, $config_file or die $!;
my %commands;
while(<COMMAND>){
    chomp;
    unless(/^$/ or /^#/){
       my @line = split /\s+/;
       unless(@line == 2){
           die "check your config file, line $. seems to be bizzare.";
       }
       $commands{$line[0]} = $line[1];
    }
}
close COMMAND;

my $work_dir = $commands{'work_directory'};
-e -d "$work_dir/01_pandaseq_QC" or mkdir "$work_dir/01_pandaseq_QC";
-e -d "$work_dir/qsub_directory" || mkdir "$work_dir/qsub_directory";

##pandaseq
-f "$Bin/../src/01_01_pandaseq_concatenate_each_sample.pl" or die "$Bin/../src/scripts/bin/01_01_pandaseq_concatenate_each_sample.pl\ndoesn't exist, did you copied the scripts directory?\n";
if($commands{'miseq_pe_list'} eq "NON"){
	-f "$work_dir/00_split_library/00_split_file.list" or die "the default, $work_dir/00_split_library/00_split_file.list, doesn't exist\n";
	$commands{'miseq_pe_list'} = "$work_dir/00_split_library/00_split_file.list";
}else{
	-f $commands{'miseq_pe_list'} or die "the miqseq_pe_list you have given doesn't exist\n";
}
system("$commands{'perl'} $Bin/../src/01_01_pandaseq_concatenate_each_sample.pl $commands{'miseq_pe_list'} $commands{'quality_system'} $work_dir/01_pandaseq_QC/01_pandaseq $work_dir/01_01_pandaseq.qsub $work_dir/01_pandaseq_QC/01_pandaseq.list $commands{pandaseq} $commands{'forwardprimer'} $commands{'reverseprimer'} $commands{'project_ID'} $commands{'node_group'}");


## QC
-f "$Bin/../src/01_02_mk_QC_command.pl" or die "$Bin/../src/01_02_mk_QC_command.pl\ndoesn't exist, did you copied the scripts directory?\n";
system("$commands{'perl'} $Bin/../src/01_02_mk_QC_command.pl $work_dir/01_pandaseq_QC/01_pandaseq.list $commands{'average_quality_cutoff'} $commands{'max_N'} $commands{'min_length'} $commands{'max_length'} $work_dir/01_pandaseq_QC/02_QC $commands{'perl'} $commands{'project_ID'} $commands{'node_group'}");

## statistic and cat all sequences together
-f "$Bin/../src/01_03_mk_statistic_command.pl" or die "$Bin/../src/01_03_mk_statistic_command.pl\ndoesn't exist, did you copied the scripts directory?\n";
-f "$Bin/../src/01_03_statistic.pl" or die "$Bin/../src/01_03_statistic.pl\ndoesn't exist, did you copied the scripts directory?\n";
-e -d "$work_dir/01_pandaseq_QC/03_statistic" or mkdir "$work_dir/01_pandaseq_QC/03_statistic";
-e -d "$work_dir/01_pandaseq_QC/03_statistic/cmd" or mkdir "$work_dir/01_pandaseq_QC/03_statistic/cmd";

my $command=<<EOF;
-f "$work_dir/01_pandaseq_QC/02_pandaseq_concatenated_sequence_QC.list" or die "final clean data list, $work_dir/01_pandaseq_QC/02_pandaseq_concatenated_sequence_QC.list, doesn't exist\\n";
open LIST, "$work_dir/01_pandaseq_QC/02_pandaseq_concatenated_sequence_QC.list" or die \$!;
open CMD, ">$work_dir/01_pandaseq_QC/03_statistic/cmd/01_03_statistic.cmd" or die \$!;
open CAT, ">$work_dir/01_pandaseq_QC/03_statistic/cmd/01_03_cat.cmd";
my \$cmd = "cat ";
while(<LIST>){
	chomp;
	\$cmd .= "\$_ ";
}
\$cmd .= "> $work_dir/together.fna";


print CAT "\$cmd\\n";
print CMD "$commands{'perl'} $Bin/../src/01_03_mk_statistic_command.pl $commands{'miseq_pe_list'} $work_dir/01_pandaseq_QC/01_pandaseq.list $work_dir/01_pandaseq_QC/02_pandaseq_concatenated_sequence_QC.list $work_dir/01_pandaseq_QC/03_statistic $commands{'perl'}  $commands{'project_ID'} $commands{'node_group'} $Bin/../src\n";

close CMD;
close CAT;

EOF

open PERL, ">$work_dir/01_pandaseq_QC/03_statistic/cmd/03_cat_statistic.pl" or die $!;
print PERL $command;
close PERL;

open LINUX, ">$work_dir/01_pandaseq_QC/03_statistic/cmd/linux.sh";
print LINUX "sh $Bin/../src/wait_for_execution.sh $commands{'project_ID'} $work_dir\n";
close LINUX;

open QSUB, ">$work_dir/01_03_statistic.qsub" or die $!;
print QSUB "[[ -d $work_dir/qsub_directory ]] && rm -f $work_dir/qsub_directory/*\n";
print QSUB "$commands{'perl'} $work_dir/01_pandaseq_QC/03_statistic/cmd/03_cat_statistic.pl\n";
print QSUB "sh $work_dir/01_pandaseq_QC/03_statistic/cmd/01_03_statistic.cmd\n";
print QSUB "sh $work_dir/01_pandaseq_QC/03_statistic.qsub\n";
print QSUB "qsub -cwd -l vf=2G -o $work_dir/qsub_directory -e $work_dir/qsub_directory -N $commands{'project_ID'} -q $commands{'node_group'} $work_dir/01_pandaseq_QC/03_statistic/cmd/01_03_cat.cmd\n";
print QSUB "qsub -cwd -l vf=1G -o $work_dir/qsub_directory -e $work_dir/qsub_directory -N $commands{'project_ID'} -q $commands{'node_group'} $work_dir/01_pandaseq_QC/03_statistic/cmd/linux.sh\n";
close QSUB;



