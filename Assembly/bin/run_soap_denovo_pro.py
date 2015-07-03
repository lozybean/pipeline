from __future__ import division
import os 
import sys
import re
import templates
def geterr():
    sys.stderr.write('usage python run_soap_denovo_pro.py [pro] workdir kmer sample_list\n');
    sys.stderr.write('sample_list include:\nsample_name\tinsert_size(only need if pro)\tread1\tread2\tsingle_reads(if use)\n')
    sys.exit();

def mkdirs(work_dir,kmer):
    sub_dirs =  ['ass_result','ass_log','cfg','cmd','cmd_log']
    dirs = ['%s/%s'%(work_dir,sub_dir) for sub_dir in sub_dirs]
    for dir in dirs:
        if not os.path.isdir(dir):
            os.makedirs(dir)
    return dirs
def parse_insert(list):
    for line in open(list):
        tabs = line.strip().split('\t')
        yield (tabs)
def write_cfg(cfg_dir,sample_name,cfg_str):
    cfg_file = '%s/%s.cfg'%(cfg_dir,sample_name)
    cfg = open(cfg_file,'w')
    cfg.write(cfg_str)
    cfg.close()
    return cfg_file
def write_ass_cmd(ass_dir,sample_name,kmer,cfg_file,ass_log_dir,cmd_dir,cmd_log_dir):
    ass_out_pre = '%s/%s_K_%s'%(ass_dir,sample_name,kmer)
    ass_log = '%s/%s_K_%s.log'%(ass_log_dir,sample_name,kmer)
    cmd_str = templates.SOAPdenovo_template%{'cfgfile':cfg_file,'out_pre':ass_out_pre,'kmer':kmer,'ass_log':ass_log}
    cmd_file = '%s/%s.cmd'%(cmd_dir,sample_name)
    cmd_log_pre = '%s/%s'%(cmd_log_dir,sample_name)
    cmd = open(cmd_file,'w')
    cmd.write(cmd_str)
    cmd.close()
    return cmd_file,cmd_log_pre
def work_ass(work_dir,kmer,sample_list,if_pro):
    (ass_dir,ass_log_dir,cfg_dir,cmd_dir,cmd_log_dir) = mkdirs(work_dir,kmer);
    shell = open('%s/assembly_k_%s.qsub'%(work_dir,kmer),'w')
    for tabs in parse_insert(sample_list):
        if len(tabs) == 5:
            (sample_name,insert_size,read1,read2,reads) = tabs
            cfgtemplate = templates.cfgtemplate_pro_with_single
            cfg_str = cfgtemplate%{'read1':read1,'read2':read2,'reads':reads,'insert_size':insert_size}
        elif len(tabs) ==4:
            if if_pro:
                (sample_name,insert_size,read1,read2) = tabs
                cfgtemplate = templates.cfgtemplate_pro
                cfg_str = cfgtemplate%{'read1':read1,'read2':read2,'insert_size':insert_size}
            else:
                (sample_name,read1,read2,reads) = tabs
                cfgtemplate = templates.cfgtemplate_with_single
                cfg_str = cfgtemplate%{'read1':read1,'read2':read2,'reads':reads}
        elif len(tabs) == 3:
            (sample_name,read1,read2) = tabs
            cfgtemplate = templates.cfgtemplate
            cfg_str = cfgtemplate%{'read1':read1,'read2':read2}
        vf = os.path.getsize(read1) / 1024 / 1024 / 1024 * 10
        if vf < 50:
            queue = "all.q,neo.q"
        else:
            queue = "neo.q"
        vf = "%.1fG"%vf
        cfg_file = write_cfg(cfg_dir,sample_name,cfg_str)
        cmd_file,cmd_log_pre = write_ass_cmd(ass_dir,sample_name,kmer,cfg_file,ass_log_dir,cmd_dir,cmd_log_dir)
        qsub_str = templates.qsub_template%{'vf':vf,'queue':queue,'cmd_log_pre':cmd_log_pre,'cmd_file':cmd_file}
        shell.write(qsub_str)
def main(argv):
    work_dir,kmer,sample_list = argv
    work_dir = os.path.abspath(work_dir)
    work_dir = '%s/pre_K_%s'%(work_dir,kmer)
    work_ass(work_dir,kmer,sample_list,False)
def main_pro(argv):
    work_dir,kmer,sample_list = argv
    work_dir = os.path.abspath(work_dir)
    work_dir = '%s/K_%s'%(work_dir,kmer)
    work_ass(work_dir,kmer,sample_list,True)

if __name__ == '__main__':
    sys.argv.pop(0);
    if len(sys.argv) < 3:
        geterr()
    if len(sys.argv) == 4:
        if sys.argv.pop(0) != 'pro':
            geterr()
        else:
            main_pro(sys.argv)
    elif len(sys.argv) == 3:
        main(sys.argv)
