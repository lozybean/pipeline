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
if [ -z $group_num ];then
    echo 'you must set the group num'
    exit
fi

pick_otu_dir=$work_dir/01_pick_otu
otu_all=$pick_otu_dir/otus_all.txt
seqs_all=$pick_otu_dir/seqs_all.fa

awk '{print $7}' $pick_otu_dir/sumOTUPerSample.txt | sort -n | head -n 2 |tail -n 1 > /tmp/file
while read out
do
		minimum=$out
done < /tmp/file
