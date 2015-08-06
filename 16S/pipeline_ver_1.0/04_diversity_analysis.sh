#source $config_path/04_diversity_analysis_config.sh
sub_dir=$work_dir/04_diversity_analysis
mkdir -p $sub_dir

if [ $ITS_or_16S = '16S' ]; then
    echo \
"align_seqs.py -i $rep_set -m $align_seq_method -t $gg_imputed -o $sub_dir/pynast_alignment
filter_alignment.py -i $sub_dir/pynast_alignment/rep_set_aligned.fasta -m $gg_lanemask -o $sub_dir/filtered_alignment
make_phylogeny.py -i $sub_dir/filtered_alignment/rep_set_aligned_pfiltered.fasta -o $sub_dir/rep_phylo.tre" >$sub_dir/work.sh
elif [ $ITS_or_16S = 'ITS' ]; then
    echo \
"align_seqs.py -i $rep_set -m $align_seq_method -o $sub_dir/$align_seq_method\_alignment
make_phylogeny.py -i $sub_dir/$align_seq_method\_alignment/rep_set_aligned_pfiltered.fasta -o $sub_dir/rep_phylo.tre" >$sub_dir/work.sh
else
    echo "the data type must be 16S or ITS ! "
    exit
fi


source $pipeline_path/04_alpha_diversity_analysis.sh
source $pipeline_path/04_beta_diversity_analysis.sh

if [ -z $job_name ];then
	echo "\
make_tree=\`qsub -cwd -l vf=10G -q all.q -e $sub_dir/work.e -o $sub_dir/work.o -terse $sub_dir/work.sh\`
alpha_div=\`qsub -cwd -l vf=10G -q all.q -e $alpha_sub_dir/work.e -o $alpha_sub_dir/work.o -terse -hold_jid \$make_tree $alpha_sub_dir/work.sh\`
beta_div=\`qsub -cwd -l vf=10G -q all.q -e $beta_sub_dir/work.e -o $beta_sub_dir/work.o -terse -hold_jid \$make_tree $beta_sub_dir/work.sh\`" >$work_dir/04_diversity_analysis.qsub
else
    echo "\
make_tree=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_04 -e $sub_dir/work.e -o $sub_dir/work.o -terse $sub_dir/work.sh\`
alpha_div=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_04 -e $alpha_sub_dir/work.e -o $alpha_sub_dir/work.o -terse -hold_jid \$make_tree $alpha_sub_dir/work.sh\`
beta_div=\`qsub -cwd -l vf=10G -q all.q -N $job_name\_04 -e $beta_sub_dir/work.e  -o $beta_sub_dir/work.o  -terse -hold_jid \$make_tree $beta_sub_dir/work.sh\`" >$work_dir/04_diversity_analysis.qsub
fi

