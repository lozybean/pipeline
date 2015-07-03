import os
import re
import sys

def parseStat(stat_path):
    sample_reads = {}
    for f in os.popen('ls %s/*.stat'%stat_path):
        num = int(os.popen('cat %s'%f.strip()).read().strip())
        sample_name = re.search('(\S+)\.fq\.stat',f).group(1)
        sample_name = os.path.basename(sample_name)
        sample_reads[sample_name] = num
    return sample_reads

def put_xls(sample_reads,out):
    out.write('sample_name\treads_num\n')
    for sample,num in sample_reads.iteritems():
        out.write('%s\t%s\n'%(sample,num))

if __name__ == '__main__':
    cwd = os.getcwd()
    stat_path = '%s/01_QC/02_high_quality/'%cwd
    sample_reads = parseStat(stat_path)
    out = open('reads_stat.xls','w')
    put_xls(sample_reads,out)
