import sys
import os
import re
from templates import soap_build_index_template,soap_template,insert_template

def parse_reads(file):
    for line in open(file):
        tabs = re.split('\s+',line.strip())
        if len(tabs) == 3:
            (sample,read1,read2) = tabs
        elif len(tabs) ==4:
            (sample,read1,read2,reads) = tabs
        yield (sample,read1,read2)
def mkdirs(work_dir):
    sub_dirs = ['soap/insert','soap/index','soap/result','soap/cmd','soap/log']
    dirs = ['%s/%s'%(work_dir,sub_dir) for sub_dir in sub_dirs]
    for dir in dirs:
        if not os.path.isdir(dir):
            os.makedirs(dir)
    return dirs

def main(work_dir,sample_list,kmer):
    qsub = open('%s/soap2_insert.qsub'%work_dir,'w')

    insert_dir,index_dir,soap_result_dir,cmd_dir,log_dir = mkdirs(work_dir)
    for sample,read1,read2 in parse_reads(sample_list):

        ass_seq = '%s/ass_result/%s_K_%s.scafSeq'%(work_dir,sample,kmer)
        index_file = '%s/%s'%(index_dir,sample)
        index = '%s.index'%index_file

        cmd_file = '%s/%s.cmd'%(cmd_dir,sample)
        cmd = open(cmd_file,'w')

        cmd_str = soap_build_index_template%{'index':index_file,'ori_file':ass_seq}
        cmd.write(cmd_str)

        pe = '%s/%s.pe'%(soap_result_dir,sample)
        se = '%s/%s.se'%(soap_result_dir,sample)
        cmd_str = soap_template%{'fq1':read1,'fq2':read2,'index':index,'pe':pe,'se':se}
        cmd.write(cmd_str)

        cmd_str = insert_template%{'insert_out':insert_dir,'pe':pe}
        cmd.write(cmd_str)
        
        cmd.close()

        log_pre = '%s/%s'%(log_dir,sample)
        log_e = '%s.e'%log_pre
        log_o = '%s.o'%log_pre
        qsub.write('qsub -cwd -l vf=10G -q all.q -e %s -o %s %s\n'%(log_e,log_o,cmd_file))
        
if __name__ == '__main__':
    sys.argv.pop(0)
    work_dir,kmer,sample_list = sys.argv
    work_dir = os.path.abspath(work_dir)
    work_dir = '%s/pre_K_%s'%(work_dir,kmer)
    main(work_dir,sample_list,kmer)
