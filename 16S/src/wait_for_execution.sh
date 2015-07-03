#!/bin/bash
#! project_ID
#! pwd

line=$(qstat | grep $1 | wc -l)

while [ $line -gt 1 ]
do
sleep 10
line=$(qstat | grep $1 | wc -l)
done

cat $2/01_pandaseq_QC/03_statistic/*.statistic | awk NR%2==0 | sort -k1n > $2/statistic.tab 
