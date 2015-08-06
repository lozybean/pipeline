#source $config_path/04_diversity_analysis_config.sh
alpha_sub_dir=$work_dir/04_diversity_analysis/alpha_diff
mkdir -p $alpha_sub_dir

wf_arare_outdir=$alpha_sub_dir/wf_arare_$minimum
alpha_div_collated_outdir=$wf_arare_outdir/alpha_div_collated


echo "\
cp $work_dir/04_diversity_analysis/rep_phylo.tre $alpha_sub_dir/
mkdir -p $wf_arare_outdir
multiple_rarefactions.py -i $otu_biom $multiple_rarefactions_argv -x $minimum -o $wf_arare_outdir/rarefaction
alpha_diversity.py -i $wf_arare_outdir/rarefaction -o $wf_arare_outdir/alpha_div --metrics $alpha_metrics -t $alpha_sub_dir/rep_phylo.tre
collate_alpha.py -i $wf_arare_outdir/alpha_div -o $alpha_div_collated_outdir
for alpha in $alphas
do
	$script_04_alpha_diff -alpha $alpha_div_collated_outdir/\$alpha.txt -group $group_file -gnum $group_num
done
if [ -f $alpha_div_collated_outdir/alpha_all.txt ];then
	rm $alpha_div_collated_outdir/alpha_all.txt
fi
head -n 1 $alpha_div_collated_outdir/\$alpha.txt >$alpha_div_collated_outdir/alpha_all.txt
tail -n 1 $alpha_div_collated_outdir/*.w.txt >>$alpha_div_collated_outdir/alpha_all.txt
awk '{for(j=1;j<=NF;j++)a[j]=sprintf(\"%s%s\\t\",a[j],\$j)}END{for(j=1;j<=NF;j++)printf \"%s\\n\",a[j]}' $alpha_div_collated_outdir/alpha_all.txt >$alpha_div_collated_outdir/alpha_statistics.txt
if [ -f $alpha_div_collated_outdir/alpha.markers.txt ];then
	rm $alpha_div_collated_outdir/alpha.markers.txt
fi
head -n 1 $alpha_div_collated_outdir/\$alpha.marker.txt >$alpha_div_collated_outdir/alpha.markers.txt
tail -n 1 $alpha_div_collated_outdir/*.marker.txt >>$alpha_div_collated_outdir/alpha.markers.txt" >$alpha_sub_dir/work.sh

[ -f $alpha_sub_dir/work.e ] && rm $alpha_sub_dir/work.e
[ -f $alpha_sub_dir/work.o ] && rm $alpha_sub_dir/work.o

if [ -z $job_name ];then
	echo -e "qsub -cwd -l vf=10G -q all.q -e $alpha_sub_dir/work.e -o $alpha_sub_dir/work.o $alpha_sub_dir/work.sh" >$work_dir/04_diversity_analysis/04_alpha_diversity_analysis.qsub
else
	echo -e "qsub -cwd -l vf=10G -q all.q -N $job_name\_04 -e $alpha_sub_dir/work.e -o $alpha_sub_dir/work.o $alpha_sub_dir/work.sh" >$work_dir/04_diversity_analysis/04_alpha_diversity_analysis.qsub
fi
