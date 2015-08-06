#source $config_path/01_pick_otu_config.sh

sub_dir=$work_dir/01_pick_otu
mkdir -p $sub_dir
single_path=$sub_dir/single
mkdir -p $single_path

derep_fa=$single_path/derep.fa

echo \
"$get_single_read_script -input $fna_file -out $single_path
ln -s $derep_fa $sub_dir/derep.fa
$usearch -sortbysize $derep_fa -output $sub_dir/sorted.fa -minsize 2
$usearch -cluster_otus $sub_dir/sorted.fa -otus $sub_dir/cluster_otus.fa 
$fasta_number_script $sub_dir/cluster_otus.fa denovo >$sub_dir/otus.fa  
$usearch -usearch_global $fna_file -db $sub_dir/otus.fa -strand plus -id 0.97 -uc $sub_dir/map.uc
$uc2otutab_script $sub_dir/map.uc $sub_dir/otus_all.txt
$otus2fa_script $sub_dir/otus_all.txt $fna_file $sub_dir/seqs_all.fa
$sumOTUPerSample_script $fna_file $derep_fa $sub_dir/otus_all.txt $sub_dir/sumOTUPerSample.txt" >$sub_dir/work.sh

[ -f $sub_dir/work.e ] && rm $sub_dir/work.e
[ -f $sub_dir/work.o ] && rm $sub_dir/work.o

if [ -z $job_name ];then
	echo "qsub -cwd -l vf=10G -q all.q -e $sub_dir/work.e -o $sub_dir/work.o $sub_dir/work.sh" >$work_dir/01_pick_otu.qsub
else 
	echo "qsub -cwd -l vf=10G -q all.q -N $job_name\_01 -e $sub_dir/work.e -o $sub_dir/work.o $sub_dir/work.sh" >$work_dir/01_pick_otu.qsub
fi
