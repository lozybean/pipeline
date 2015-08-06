#source $config_path/02_alpha_rare_curve_config.sh
sub_dir=$work_dir/02_alpha_rare_curve
mkdir -p $sub_dir

#pick_rep_set
pick_rep_log=$sub_dir/pick_rep_set_log
rep_set=$sub_dir/rep_set.fna
#pick_rep_set.py -i $otu_all -f $seqs_all -o $rep_set -l $pick_rep_log -m $pick_rep_method

#assign_taxonomy
ass_tax_outdir=$sub_dir/$ass_tax_method\_assigned_taxonomy
#assign_taxonomy.py -i $rep_set -m $ass_tax_method -r $gg_ref -t $gg_tax -o $ass_tax_outdir 

#make_otu_table
otu_biom=$sub_dir/otu_table.biom
#make_otu_table.py -i $otu_all -t $ass_tax_outdir/rep_set_tax_assignments.txt -o $otu_biom

#align_seqs
align_seq_outdir=$sub_dir/pynast_alignment
#align_seqs.py -i $rep_set -m $align_seq_method -t $gg_imputed -o $align_seq_outdir

#filter_alignment
filter_alignment_outdir=$sub_dir/filtered_alignment 
#filter_alignment.py -i $align_seq_outdir/rep_set_aligned.fasta -m $gg_lanemask -o $filter_alignment_outdir

#make_phylogeny
phylogeny=$sub_dir/rep_phylo.tre
#make_phylogeny.py -i $filter_alignment_outdir/rep_set_aligned_pfiltered.fasta -o $phylogeny 

#multiple_rarefactions
multiple_rarefactions_dir=$sub_dir/multiple_rarefactions
alpha_collated_dir=$multiple_rarefactions_dir/alpha_div_collated
#mkdir -p $multiple_rarefactions_dir
#multiple_rarefactions.py -i $otu_biom $multiple_rarefactions_argv -o $multiple_rarefactions_dir/rarefaction
#alpha_diversity.py -i $multiple_rarefactions_dir/rarefaction -o $multiple_rarefactions_dir/alpha_div --metrics $alpha_metrics -t $phylogeny
#collate_alpha.py -i $multiple_rarefactions_dir/alpha_div -o $alpha_collated_dir

alphas=${alpha_metrics//,/ }

echo \
"pick_rep_set.py -i $otu_all -f $seqs_all -o $rep_set -l $pick_rep_log -m $pick_rep_method
assign_taxonomy.py -i $rep_set -m $ass_tax_method -r $gg_ref -t $gg_tax -o $ass_tax_outdir
make_otu_table.py -i $otu_all -t $ass_tax_outdir/rep_set_tax_assignments.txt -o $otu_biom
align_seqs.py -i $rep_set -m $align_seq_method -t $gg_imputed -o $align_seq_outdir
filter_alignment.py -i $align_seq_outdir/rep_set_aligned.fasta -m $gg_lanemask -o $filter_alignment_outdir
make_phylogeny.py -i $filter_alignment_outdir/rep_set_aligned_pfiltered.fasta -o $phylogeny
mkdir -p $multiple_rarefactions_dir
multiple_rarefactions.py -i $otu_biom $multiple_rarefactions_argv -x $maximum -o $multiple_rarefactions_dir/rarefaction
alpha_diversity.py -i $multiple_rarefactions_dir/rarefaction -o $multiple_rarefactions_dir/alpha_div --metrics $alpha_metrics -t $phylogeny
collate_alpha.py -i $multiple_rarefactions_dir/alpha_div -o $alpha_collated_dir
for i in $alphas
do
	$alpha_rare_curve_script $alpha_collated_dir/\$i.txt $group_file N
done">$sub_dir/work.sh

[ -f $sub_dir/work.e ] && rm $sub_dir/work.e
[ -f $sub_dir/work.o ] && rm $sub_dir/work.o

if [ -z $job_name ];then
	echo "qsub -cwd -l vf=10G -q all.q -e $sub_dir/work.e -o $sub_dir/work.o $sub_dir/work.sh" >$work_dir/02_alpha_rare_curve.qsub
else
	echo "qsub -cwd -l vf=10G -q all.q -N $job_name\_02 -e $sub_dir/work.e -o $sub_dir/work.o $sub_dir/work.sh" >$work_dir/02_alpha_rare_curve.qsub
fi
