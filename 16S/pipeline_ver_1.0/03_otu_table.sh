#source $config_path/03_otu_table_config.sh
sub_dir=$work_dir/03_otu_table
mkdir -p $sub_dir

suffix=downsize_$minimum
otu_downsize=$sub_dir/otus_$suffix.txt
seq_downsize=$sub_dir/seqs_$suffix.fa
ass_tax_outdir=$sub_dir/$ass_tax_method\_assigned_taxonomy
otu_biom=$sub_dir/otu_table.biom
otu_txt=$sub_dir/otu_table.txt
otu_uniform=$sub_dir/otu_table_profile.txt
wf_taxa_outdir=$sub_dir/wf_taxa_summary
sample_bar_outdir=$wf_taxa_outdir/bar_plot
group_bar_outdir=$wf_taxa_outdir/bar_plot_group

mkdir -p $sample_bar_outdir
mkdir -p $group_bar_outdir

echo "\
[ -f $otu_txt ] && rm $otu_txt
[ -f $sub_dir/otu_table_summary.txt ] && rm $sub_dir/otu_table_summary.txt
$sample_downsize_script $otu_all $minimum Y $otu_downsize
$otus2fa_script $otu_downsize $seqs_all $seq_downsize
pick_rep_set.py -i $otu_downsize -f $seq_downsize -o $sub_dir/rep_set.fna -l $sub_dir/pick_rep_set_log -m $pick_rep_method " > $sub_dir/work.sh

if [ $ITS_or_16S = '16S' ]; then
    echo "\assign_taxonomy.py -i $sub_dir/rep_set.fna -m $ass_tax_method -r $gg_ref -t $gg_tax -o $ass_tax_outdir" >> $sub_dir/work.sh
elif [ $ITS_or_16S = 'ITS' ]; then
    echo "\
mkdir -p $ass_tax_outdir
$java -Xmx1g -jar $RDPtools -g fungalits_unite -c 0.8 -o $ass_tax_outdir/rep_set_tax_assignments_classifier.txt $sub_dir/rep_set.fna
$transform_rdp_result2qiimeform_script $ass_tax_outdir/rep_set_tax_assignments_classifier.txt 0.8 $ass_tax_outdir/rep_set_tax_assignments.txt ITS " >> $sub_dir/work.sh
else
    echo "the data type must be 16S or ITS ! "
    exit
fi

echo \
"make_otu_table.py -i $otu_downsize -t $ass_tax_outdir/rep_set_tax_assignments.txt -o $otu_biom
summarize_taxa.py -i $otu_biom -o $wf_taxa_outdir
biom summarize-table -i $otu_biom -o $sub_dir/otu_table_summary.txt
biom convert -i $otu_biom -o $otu_txt --to-tsv
$script_03_core_otu $otu_txt $ass_tax_outdir/rep_set_tax_assignments.txt
$script_03_get_otu_uniform $otu_txt
$script_03_otu_pca $otu_uniform $group_file
$script_03_otu_statistics $ass_tax_outdir/rep_set_tax_assignments.txt $otu_downsize
$script_03_tax_heatmap $wf_taxa_outdir/otu_table_L6.txt $group_file
$script_03_venn -otu $otu_txt -group $group_file -gnum $group_num
$script_03_tax_stars $wf_taxa_outdir/otu_table_L6.txt $group_file
cp $wf_taxa_outdir/*.txt $sample_bar_outdir
cp $wf_taxa_outdir/*.txt $group_bar_outdir
for i in 2 3 4 5 6
do
	$script_03_otu_tax_sample_bar -input $wf_taxa_outdir/otu_table_L\$i.txt -sample $group_file -prefix $sample_bar_outdir/otu_table_L\$i -level \$i
	$script_03_otu_tax_group_bar -input $wf_taxa_outdir/otu_table_L\$i.txt -group $group_file -prefix $group_bar_outdir/otu_table_group_L\$i -level \$i
done " >>$sub_dir/work.sh

[ -f $sub_dir/work.e ] && rm $sub_dir/work.e
[ -f $sub_dir/work.o ] && rm $sub_dir/work.o

if [ -z $job_name ];then
	echo "qsub -cwd -l vf=10G -q all.q -e $sub_dir/work.e -o $sub_dir/work.o $sub_dir/work.sh" >$work_dir/03_otu_table.qsub
else
	echo "qsub -cwd -l vf=10G -q all.q -N $job_name\_03 -e $sub_dir/work.e -o $sub_dir/work.o $sub_dir/work.sh" >$work_dir/03_otu_table.qsub
fi
