template = '''compact='%compact'
type='%(data_type)s'
# 16S  or  ITS
lib_method='%(lib_method)s'
# Self or  HXT
sam_barcode_file='%(sam_barcode_file)s'
# which sam_barcode_file in split_path
# determined by your barcode
split_path='%(work_path)s'
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
'''

import os
import sys
import re
import run_pandaseq

def main(work_path):
    split_path = '%s/Split'
    for sam_barcode_file in os.popen('ls %s/sam_barcode.*'%split_path):
        sam_barcode_file = sam_barcode_file.strip()
        if re.search('sam_barcode.l',sam_barcode_file):
            


if __name__ == '__main__':
    sys.argv.pop(0)
    if len(sys.argv) != 1:
        sys.stderr.write('Usage: python run_pipeline.py work_path')
        sys.exit()
    work_path = sys.argv.pop(0)
    primer = run_pandaseq.primer
    main(work_path)
