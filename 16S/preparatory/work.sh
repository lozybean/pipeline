compact='RY2014L22F03-1'
type='16S'
# 16S  or  ITS
lib_method='HXT'
# Self or  HXT
sam_barcode_file='sam_barcode.s6'
# which sam_barcode_file in split_path
# determined by your barcode
split_path='/data_center_01/DNA_Data/data1/original_data/raw_reads/MiSeq/PE300_20150617/s241g01014_LYQ_20150617_3samples/Split'
# split_path

if [ ! -L rawData_$type ];then
	ln -s $split_path/$compact rawData_$type
fi
cp rawData_$type/../$sam_barcode_file ./

python /data_center_01/home/NEOLINE/liangzebin/pipeline/16S/preparatory/run_rmAdaptor.py $compact $sam_barcode_file $lib_method $type
sh rmAdaptor.sh

python /data_center_01/home/NEOLINE/liangzebin/pipeline/16S/preparatory/run_pandaseq.py $lib_method $type
sh pandaseq.sh

python /data_center_01/home/NEOLINE/liangzebin/pipeline/16S/preparatory/run_QC.py
sh QC.sh

python /data_center_01/home/NEOLINE/liangzebin/pipeline/16S/preparatory/reads_stat.py

#python /data_center_01/home/NEOLINE/liangzebin/pipeline/16S/preparatory/merge.py sample_merge 16S
