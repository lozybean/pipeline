#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin $Script); 
use lib "$Bin/../lib";
use Cwd 'abs_path';
use PGAP qw(parse_config);

die "usage:perl $0 config_file(#which can be copied and changed at $Bin/../src)" unless @ARGV==1;

my ($script_file) = @ARGV

open COMMAND, $script_file or die $!;
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

-f "$Bin/../src/00_01_split_library.pl" or die "the script to split library doesn't exists or you didn't copy the 'scripts' directory?";
-e -d "$work_dir/00_split_library" or mkdir "$work_dir/00_split_library";
-e -d "$work_dir/qsub_directory" or mkdir "$work_dir/qsub_directory";
-e -d "$work_dir/00_split_library/cmd" or mkdir "$work_dir/00_split_library/cmd";
-e -d "$work_dir/qsub_directory" || mkdir "$work_dir/qsub_directory";
open QSUB, ">$work_dir/00_split_library.qsub" or die $!;
print QSUB "[[ -d $work_dir/qsub_directory ]] && rm -f $work_dir/qsub_directory/*\n";
open INFO, "$commands{'sampleinfo'}" or die $!;
open CLEAN, ">$work_dir/00_split_library/00_split_file.list" or die $!;
open MAP, ">$work_dir/mapfile.txt" or die $!;
print MAP "#SampleID\n";
my $group;
my %groups;
while(my $info = <INFO>){
	next if($info =~ /^#/ or $info =~ /^$/);

	chomp($info);
	my @info = split /\t/, $info;
	if($info[6] =~ /-/){
		die "sign '-' is not allowed in analysis name, or qiime script will produced errors.\n";
	}
	print CLEAN "$work_dir/00_split_library/$info[3]/$info[6].1.fq\n$work_dir/00_split_library/$info[3]/$info[6].2.fq\n";
	print MAP "$info[6]\n";
	unless(exists $groups{$info[3]}){
		open $groups{$info[3]}, ">$work_dir/00_split_library/$info[3].info.list";
		-e -d "$work_dir/00_split_library/$info[3]" || mkdir "$work_dir/00_split_library/$info[3]";
		open CMD, ">$work_dir/00_split_library/cmd/$info[3].cmd" or die $!;
		print CMD "$commands{'perl'} $Bin/../src/00_01_split_library.pl $work_dir/00_split_library/$info[3].info.list $commands{'forwardprimer'} $commands{'reverseprimer'} $commands{'rawdata'} $work_dir/00_split_library/$info[3]\n";
		close CMD;
		print QSUB "qsub -cwd -l vf=2G -o $work_dir/qsub_directory -e $work_dir/qsub_directory -N $commands{'project_ID'} -q $commands{'node_group'} $work_dir/00_split_library/cmd/$info[3].cmd\n";
	}
	
	$groups{$info[3]}->print("$info\n");

}
close MAP;
close CLEAN;
close QSUB;
close INFO;

