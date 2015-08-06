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


awk '{print $7}' $pick_otu_dir/sumOTUPerSample.txt | sort -n | head -n 2 |tail -n 1 > /tmp/file
while read out
do
    minimum=$out
done < /tmp/file

otu_table_dir=$work_dir/03_otu_table
rep_set=$otu_table_dir/rep_set.fna
otu_biom=$otu_table_dir/otu_table.biom

