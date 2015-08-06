if [ -z $work_dir ];then
   	echo 'you must set the work_dir'
	exit
fi
if [ -z $fna_file ];then
	echo 'you must set the fna file'
	exit
fi
if [ -z $group_file ];then
	echo 'you must set the group file'
	exit
fi

pick_otu_dir=$work_dir/01_pick_otu
otu_all=$pick_otu_dir/otus_all.txt
seqs_all=$pick_otu_dir/seqs_all.fa

alpha_metrics="chao1,observed_species,PD_whole_tree,shannon,simpson,goods_coverage"
alphas=${alpha_metrics//,/ }

awk '{print $2}' $pick_otu_dir/sumOTUPerSample.txt | sort -n | tail -n 1 > /tmp/file
while read out
do
	maximum=$out
done < /tmp/file

awk '{print $7}' $pick_otu_dir/sumOTUPerSample.txt | sort -n | head -n 2 |tail -n 1 > /tmp/file
while read out
do
	minimum=$out
done < /tmp/file

multiple_rarefactions_argv=" -m 10 -s 4000 "
pick_rep_method=most_abundant
ass_tax_method=rdp
align_seq_method=muscle


