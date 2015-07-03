import re
import os
import sys
from Bio import SeqIO

def sampleMerge(file_path,outhandle):
    reads_num = {}
    for f in os.popen('ls %s/*.fq'%file_path):
        f = f.strip()
        f_base = os.path.basename(f)
        sample = re.search('(\S+)\.fq',f_base).group(1)
        if not reads_num.has_key(sample):
            reads_num[sample] = 0
        for record in SeqIO.parse(open(f),'fastq'):
            reads_num[sample] += 1
            outhandle.write('>%s_%s\n%s\n'%(sample,reads_num[sample],str(record.seq)))
def togetherMerge(file_list,outhandle,stathandle):
    reads_num = {}
    for f in file_list:
        f = f.strip()
        f_base = os.path.basename(f)
        for record in SeqIO.parse(open(f),'fasta'):
            sample = re.search('(\S+)_',record.id).group(1)
            if not reads_num.has_key(sample):
                reads_num[sample] = 0
            reads_num[sample] += 1
            outhandle.write('>%s_%s\n%s\n'%(sample,reads_num[sample],str(record.seq)))
    for sample,num in reads_num.iteritems():
        stathandle.write('%s\t%s\n'%(sample,num))

if __name__ == '__main__':
    cwd = os.getcwd()
    sys.argv.pop(0)
    if len(sys.argv) < 1:
        sys.stderr.write('usage: python merge.py command\n\n[command] can be one of the followed list:\nsample_merge\ntogether_merge\n')
        sys.exit()
    command = sys.argv.pop(0)
    if command == 'sample_merge':
        if len(sys.argv) != 1 :
            sys.stderr.write('usage python merge.py sample_merge data_type\n\n[data_type] can be one of the followed list:\n16S\nITS\n')
            sys.exit()
        data_type, = sys.argv
        file_path = '%s/01_QC/02_high_quality'%cwd
        outhandle = open('%s.together.fna'%data_type,'w')
        sampleMerge(file_path,outhandle)
    if command == 'together_merge':
        if len(sys.argv) < 2 :
            sys.stderr.write('usage python merge.py together_merge data_type filelist\n\n[data_type] can be one of the followed list:\n16S\nITS\n[filelist] is the list of the file intend to intend to merge, a file per line\n')
            sys.exit()
        data_type = sys.argv.pop(0)
        file_list = sys.argv
        outhandle = open('%s.together.fna'%data_type,'w')
        stathandle = open('reads_stat.xls','w')
        togetherMerge(file_list,outhandle,stathandle)
