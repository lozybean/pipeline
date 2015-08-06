## notice
# please copy this config to your current path 
# fill the dependency config of your project [ fill and check for the 6 configurations ]
# run ' nohup sh pipeline.qsub & ' in your work path with be running over steps using default settings
# if you want to run step-by-step, just run ' sh  xx_xxx.qsub ' 
# if you just want to run some steps, you have to confirm the settings

#Dependency Config [must be setted!]
job_name=
group_num=
ITS_or_16S=
work_dir=$(pwd)
fna_file=$work_dir/$ITS_or_16S\_together.fna
group_file=$work_dir/group.txt

if [ -z $ITS_or_16S ] && [ $ITS_or_16S != '16S' ] && [ $ITS_or_16S != 'ITS' ]  ;then
	echo 'you have to confirm the data type [ 16S or ITS ]'
	exit
fi

#{{{
echo "\
job_name=$job_name
work_dir=$work_dir
group_num=$group_num
ITS_or_16S=$ITS_or_16S
fna_file=$fna_file
group_file=$group_file

# importing pipeline default settings ... 
pipeline_path=/data_center_01/home/NEOLINE/liangzebin/pipeline/16S/pipeline_ver_1.0
source \$pipeline_path/all_config.sh
# if you want to change something, copy the configurations you want to change and change it after this line 

##  defualt settings will be source at first, if you want to change some settings, uncommet it and change it

# +++++++++++++++                01_pick_otu                 +++++++++++++++++++++ #

source \$config_path/01_pick_otu_config.sh
source \$pipeline_path/01_pick_otu.sh
sh1=\$work_dir/01_pick_otu/work
pick_otu_summary=\$work_dir/01_pick_otu/sumOTUPerSample.txt " >$work_dir/before_pick_otu_config.sh 

echo "\
# +++++++++++++++            02_alpha_rare_curve             +++++++++++++++++++++ #
source \$config_path/02_alpha_rare_curve_config.sh								

#pick_otu_dir=\$work_dir/01_pick_otu  [ not in used ]
#otu_all=\$pick_otu_dir/otus_all.txt
#seqs_all=\$pick_otu_dir/seqs_all.fa
#alpha_metrics="chao1,observed_species,PD_whole_tree,shannon,simpson,goods_coverage"
#multiple_rarefactions_argv=" -m 10 -s 4000 "

#awk '{print \$2}' \$pick_otu_dir/sumOTUPerSample.txt | sort -n | tail -n 1 > /tmp/file
#while read out
#do
#    maximum=\$out
#done < /tmp/file


#gg_ref=/data_center_01/soft/greengenes/gg_12_10_otus/rep_set/97_otus.fasta
#gg_tax=/data_center_01/soft/greengenes/gg_12_10_otus/taxonomy/97_otu_taxonomy.txt
#gg_imputed=/data_center_01/soft/greengenes/core_set_aligned.fasta.imputed
#gg_lanemask=/data_center_01/soft/greengenes/lanemask_in_1s_and_0s

source \$pipeline_path/02_alpha_rare_curve.sh									
sh2=\$work_dir/02_alpha_rare_curve/work											

# ++++++++++++++++		       03_otu_table                  +++++++++++++++++++++ #
source \$config_path/03_otu_table_config.sh									

#pick_otu_dir=\$work_dir/01_pick_otu [ not in used ]
#otu_all=\$pick_otu_dir/otus_all.txt
#seqs_all=\$pick_otu_dir/seqs_all.fa

#awk '{print \$7}' \$pick_otu_dir/sumOTUPerSample.txt | sort -n | head -n 2 |tail -n 1 > /tmp/file
#while read out
#do
#    minimum=\$out
#done < /tmp/file

source \$pipeline_path/03_otu_table.sh
sh3=\$work_dir/03_otu_table/work

# ++++++++++++++++        04_diversity_analysis              +++++++++++++++++++ #
source \$config_path/04_diversity_analysis_config.sh
#otu_table_dir=\$work_dir/03_otu_table [ not in used ] 
#rep_set=\$otu_table_dir/rep_set.fna
#otu_biom=\$otu_table_dir/otu_table.biom
#alpha_metrics="chao1,observed_species,PD_whole_tree,shannon,simpson,goods_coverage"
#alphas=\${alpha_metrics//,/ }
#multiple_rarefactions_argv=" -m 45 -s 1500 "

#awk '{print \$7}' \$pick_otu_dir/sumOTUPerSample.txt | sort -n | head -n 2 |tail -n 1 > /tmp/file
#while read out
#do
#   minimum=\$out
#done < /tmp/file

source \$pipeline_path/04_diversity_analysis.sh
sh4_1=\$work_dir/04_diversity_analysis/work
sh4_2=\$work_dir/04_diversity_analysis/alpha_diff/work
sh4_3=\$work_dir/04_diversity_analysis/beta_diff/work

# +++++++++++++++         05_diff_taxa_analysis              +++++++++++++++++++ #
source \$config_path/05_diff_taxa_analysis_config.sh
#otu_table_dir=\$work_dir/03_otu_table [ not in used ] 
#wf_taxa_outdir=\$otu_table_dir/wf_taxa_summary
#otu_table_profile=\$otu_table_dir/otu_table_profile.txt
#rep_set_tax_assignments=\$otu_table_dir/rep_set_tax_assignments.txt

source \$pipeline_path/05_diff_taxa_analysis.sh
sh5=\$work_dir/05_diff_taxa_analysis/work  " >$work_dir/after_pick_otu_config.sh

echo "\
source $work_dir/before_pick_otu_config.sh
qsub1=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_01 -e \$sh1.e -o \$sh1.o -terse \$sh1.sh\`
while [ ! -s \$pick_otu_summary ];
do
        sleep 1m
		echo 'waiting for picking otu  ...'
done
source $work_dir/after_pick_otu_config.sh
qsub2=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_02 -e \$sh2.e -o \$sh2.o -terse -hold_jid \$qsub1 \$sh2.sh\`
qsub3=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_03 -e \$sh3.e -o \$sh3.o -terse -hold_jid \$qsub1 \$sh3.sh\`
qsub4_1=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_04 -e \$sh4_1.e -o \$sh4_1.o -terse -hold_jid \$qsub3 \$sh4_1.sh\`
qsub4_2=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_04 -e \$sh4_2.e -o \$sh4_2.o -terse -hold_jid \$qsub4_1 \$sh4_2.sh\`
qsub4_3=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_04 -e \$sh4_3.e -o \$sh4_3.o -terse -hold_jid \$qsub4_1 \$sh4_3.sh\`
qsub5=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_05 -e \$sh5.e -o \$sh5.o -terse -hold_jid \$qsub3 \$sh5.sh\`">$work_dir/pipeline.qsub
#}}}
