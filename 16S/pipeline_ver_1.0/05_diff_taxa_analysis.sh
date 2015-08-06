#source $config_path/05_diff_taxa_analysis_config.sh
subdir=$work_dir/05_diff_taxa_analysis
mkdir -p $subdir

echo "\
cp $wf_taxa_outdir/*txt $subdir/
cp $otu_table_profile $subdir/otu_table_otu.txt
$script_05_otu_transL $subdir/otu_table_L2.txt $subdir/otu_table_L1.txt
cat $subdir/otu_table_L1.txt $subdir/otu_table_L2.txt $subdir/otu_table_L3.txt $subdir/otu_table_L4.txt $subdir/otu_table_L5.txt $subdir/otu_table_L6.txt >$subdir/otu_table_all.txt
$script_05_otu_alllevel $subdir/otu_table_all.txt $group_file $subdir/otu_table_all.out.txt " >$subdir/prepare.sh

all_level_outdir=$subdir/tax_all_level
mkdir -p $all_level_outdir
echo "\
cp $subdir/otu_table_all.trans.txt $all_level_outdir
$script_05_tax_diff -profile $all_level_outdir/otu_table_all.trans.txt -group $group_file -gnum $group_num -qcutoff 0.05
$script_05_tax_marker_boxplot -input $all_level_outdir/otu_table_all.trans.txt -group $group_file -marker $all_level_outdir/otu_table_all.diff.marker.txt -prefix $all_level_outdir/otu_table_all.diff
$script_05_marker_tax $all_level_outdir/otu_table_all.diff.marker.for_draw.xls $all_level_outdir/otu_table_all.diff.marker.xls
$script_05_pca_diff -profile $all_level_outdir/otu_table_all.diff.marker.xls -group $group_file
$script_05_diff_tax_heatmap $all_level_outdir/otu_table_all.diff.marker.xls $group_file 10 900 " >$all_level_outdir/work.sh

genus_level_outdir=$subdir/tax_genus_level
mkdir -p $genus_level_outdir
echo "\
cp $subdir/otu_table_L6.txt $genus_level_outdir
$script_05_tax_diff -profile $genus_level_outdir/otu_table_L6.txt -group $group_file -gnum $group_num -qcutoff 0.05
$script_05_tax_marker_boxplot -input $genus_level_outdir/otu_table_L6.txt -group $group_file -marker $genus_level_outdir/otu_table_L6.diff.marker.txt -prefix $genus_level_outdir/otu_table_L6.diff
$script_05_marker_tax $genus_level_outdir/otu_table_L6.diff.marker.for_draw.xls $genus_level_outdir/otu_table_L6.diff.marker.xls
$script_05_pca_diff -profile $genus_level_outdir/otu_table_L6.diff.marker.xls -group $group_file
$script_05_diff_tax_heatmap $genus_level_outdir/otu_table_L6.diff.marker.xls $group_file 10 900 " >$genus_level_outdir/work.sh

otu_diff_outdir=$subdir/otu_diff
mkdir -p $otu_diff_outdir
echo "\
cp $subdir/otu_table_otu.txt $otu_diff_outdir/otu_table_otu.txt
$script_05_tax_diff -profile $otu_diff_outdir/otu_table_otu.txt -group $group_file -gnum $group_num -qcutoff 0.05
$script_05_otu_diff_statistics $otu_diff_outdir/otu_table_otu.diff.marker.txt $rep_set_tax_assignments 
$script_05_tax_marker_boxplot -input $otu_diff_outdir/otu_table_otu.txt -group $group_file -marker $otu_diff_outdir/otu_table_otu.diff.marker.txt -prefix $otu_diff_outdir/otu_table_otu.diff
$script_05_marker_tax $otu_diff_outdir/otu_table_otu.diff.marker.for_draw.xls $otu_diff_outdir/otu_table_otu.diff.marker.xls
$script_05_pca_diff -profile $otu_diff_outdir/otu_table_otu.diff.marker.xls -group $group_file
$script_05_diff_tax_heatmap $otu_diff_outdir/otu_table_otu.diff.marker.xls $group_file 10 900 " >$otu_diff_outdir/work.sh

echo "\
sh $subdir/prepare.sh
sh $all_level_outdir/work.sh
sh $genus_level_outdir/work.sh
sh $otu_diff_outdir/work.sh" >$subdir/work.sh

if [ -z $job_name ];then
	echo -e "qsub -cwd -l vf=10G -q all.q -e $subdir/work.e -o $subdir/work.o $subdir/work.sh" >$work_dir/05_diff_taxa_analysis.qsub
else
	echo -e "qsub -cwd -l vf=10G -q all.q -N $job_name\_05 -e $subdir/work.e -o $subdir/work.o $subdir/work.sh" >$work_dir/05_diff_taxa_analysis.qsub
fi
