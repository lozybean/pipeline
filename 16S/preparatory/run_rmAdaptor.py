import re
import os
import sys

cwd = os.getcwd()

barcode = {
    'HXT':{
        'forward_primer':'CCTACGGGNGGCWGCAG',
        'reverse_primer':'GACTACHVGGGTATCTAATCC',
        'forward':[None,'ATCACG','CGATGT','TTAGGC','TGACCA','ACAGTG','GCCAAT','CAGATC','ACTTGA','GATCAG','TAGCTT','GGCTAC','CTTGTA'],
        'reverse':[None,'ATCACG','CGATGT','TTAGGC','TGACCA','ACAGTG','GCCAAT','CAGATC','ACTTGA','GATCAG','TAGCTT','GGCTAC','CTTGTA'],
    },
    'Self':{
        'reverse':[None,'CCTAAACTACGG','TGCAGATCCAAC','CCATCACATAGG','GTGGTATGGGAG','ACTTTAAGGGTG','GAGCAACATCCT',
                        'TGTTGCGTTTCT','ATGTCCGACCAA','AGGTACGCAATT','GTTACGTGGTTG','TACCGCCTCGGA','CGTAAGATGCCT',
                        'ACAGCCACCCAT','TGTCTCGCAAGC','GAGGAGTAAAGC','TACCGGCTTGCA','ATCTAGTGGCAA','CCAGGGACTTCT',
                        'CACCTTACCTTA','ATAGTTAGGGCT','GCACTTCATTTC','TTAACTGGAAGC','CGCGGTTACTAA','GAGACTATATGC',],
        'forward':[None,'CCTAAACTACGG','TGCAGATCCAAC','CCATCACATAGG','GTGGTATGGGAG','ACTTTAAGGGTG','GAGCAACATCCT',
                        'TGTTGCGTTTCT','ATGTCCGACCAA','AGGTACGCAATT','GTTACGTGGTTG','TACCGCCTCGGA','CGTAAGATGCCT',
                        'ACAGCCACCCAT','TGTCTCGCAAGC','GAGGAGTAAAGC','TACCGGCTTGCA','ATCTAGTGGCAA','CCAGGGACTTCT',
                        'CACCTTACCTTA','ATAGTTAGGGCT','GCACTTCATTTC','TTAACTGGAAGC','CGCGGTTACTAA','GAGACTATATGC',], 
    },
}
def getBarcode(compact,lib_method,file):
    barcode = {}
    for line in open(file):
        tabs = line.strip().split('\t')
        if not re.search(compact,tabs[0]):
            continue
        sample = tabs[1]
        sample = re.sub('[-_]','.',sample)
        barcode[sample] = {}
        if lib_method == 'Self':
            barcode[sample]['forward'] = int(re.search('R(\d+)',tabs[2]).group(1))
            barcode[sample]['reverse'] = int(re.search('F(\d+)',tabs[2]).group(1))
        elif lib_method == 'HXT':
            barcode[sample]['forward'] = int(re.search('F(\d+)',tabs[2]).group(1))
            barcode[sample]['reverse'] = int(re.search('R(\d+)',tabs[2]).group(1))
        else:
            raise ValueError,'The lib_method must be HXT or Self!'
    return barcode

def getSh(data_type,lib_method,barcode_num,sh_handle):
    for sample in os.listdir('%s/rawData_%s'%(cwd,data_type)):
        sample = sample.strip()
        if not barcode_num.has_key(sample):
            continue
        (read1,read2) = os.popen('ls %s/rawData_%s/%s/*'%(cwd,data_type,sample))
        read1 = read1.strip()
        read2 = read2.strip()
        sample_out = re.sub('[-_]','.',sample)
        read1_out = '%s/01_QC/00_rmAdaptor/%s%s.1.fq'%(cwd,data_type,sample_out)
        read2_out = '%s/01_QC/00_rmAdaptor/%s%s.2.fq'%(cwd,data_type,sample_out)
        barcode_f = barcode[lib_method]['forward'][barcode_num[sample_out]['forward']]
        barcode_r = barcode[lib_method]['reverse'][barcode_num[sample_out]['reverse']]
        sh_handle.write('python /data_center_01/home/NEOLINE/liangzebin/pipeline/16S/preparatory/rmAdaptor.py %s %s %s %s %s %s\n'%(read1,read2,read1_out,read2_out,barcode_f,barcode_r))

if __name__ == '__main__':
    sys.argv.pop(0)
    if len(sys.argv) != 4:
        sys.stderr.write('usage: python compact sam_barcode_file run_pandaseq.py lib_method data_type\n\nthe sam_barcode_file is in the rawdata path ,select a matched barcode and copy it\n\nlib_method is one of the folowed list:\nHXT\nSelf\n\ndata_type is one of the followed list:\n16S\nITS\n\n')
        sys.exit()
    compact,sam_barcode_file,lib_method,data_type = sys.argv
    sh_handle = open('rmAdaptor.sh','w')
    barcode_num = getBarcode(compact,lib_method,sam_barcode_file)
    getSh(data_type,lib_method,barcode_num,sh_handle)

