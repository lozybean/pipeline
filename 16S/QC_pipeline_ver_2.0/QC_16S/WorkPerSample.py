from __future__ import division
import os
import sys
from Bio import SeqIO
from tempelates import pandaseq_cmd
from settings import get_primer,get_reads

class WorkPerSample(object):

    def __init__(self,work_path,compact,sample_name,lib_method,data_type):

        self.work_times = 0  # rework times 
        self.result = {}
    
        self.compact = compact
        self.sample_name = sample_name
        self.lib_method = lib_method
        self.data_type = data_type
        # get path
        self.path = {   'QC'    :   '%s/QC'%work_path,
                        'split' :   '%s/Split'%work_path,
                    }
        self.path['compact'] = '%s/%s'%(self.path['QC'],self.compact)
        self.path['sample'] = '%s/%s_%s'%(self.path['compact'],self.sample_name,lib_method)
        try:
            self.check_path()
        except:
            sys.stderr.write('## Permisson ERROR!\t#some problem accured when create path!\n')

        #get read
        raw_reads_path = '%s/%s/%s'%(self.path['split'],self.compact,self.sample_name)
        (self.read1,self.read2) = get_reads(raw_reads_path,self.lib_method)

        #get primer
        self.f_primer,self.r_primer = get_primer(lib_method,data_type)

    def check_path(self):
        for _path in self.path.itervalues():
            if not os.path.isdir(_path):
                os.makedirs(_path)

    def pandaseq(self):
        self.result['pandaseq_log'] = '%s/pandaseq.log'%self.path['sample']
        self.result['pandaseq'] = '%s/pandaseq.fq'%self.path['sample']
        dict = { 'read1':self.read1,'read2':self.read2,'f_primer':self.f_primer,'r_primer':self.r_primer,'log_file':self.result['pandaseq_log'],'out_file':self.result['pandaseq'] }
        cmd = pandaseq_cmd.get(dict)
        try:
            os.system(cmd)
        except:
            sys.stderr.write('## Pandaseq ERROR!\t#No pandaseq resulting!\n')

    ###  set some monkey patching.
    def __N_count(self):
        N_count = 0;
        for char in self.seq:
            if char == 'N':
                N_count += 1
        return N_count
    def __Q_ave(self):
        Q_sum = 0
        for qlist in  self.letter_annotations.itervalues():
            for q in qlist:
                Q_sum += q
            Q_ave = Q_sum / len(self)
            return Q_ave
    from Bio.SeqRecord import SeqRecord
    SeqRecord.Q_ave = __Q_ave
    SeqRecord.N_count = __N_count
    ###

    def QC(self):
        self.result['QC_stat'] = '%s/high_quality.stat'%self.path['sample']
        self.result['high_quality'] = '%s/high_quality.fq'%self.path['sample']
        out_stat = open(self.result['QC_stat'],'w')
        out = open(self.result['high_quality'],'w')

        count = 0
        high_count = 0    
        for record in SeqIO.parse(open(self.result['pandaseq']),'fastq'):
            count += 1
            if record.Q_ave() < 20:
                continue
            if len(record) < 220 or len(record) > 500:
                continue
            out.write(record.format('fastq'))
            high_count += 1
        high_ratio = high_count / count * 100
        out_stat.write('%s\t%s\t%s\t%2.2f%%\n'%(self.data_type,count,high_count,high_ratio))

        out_stat.close()
        out.close()
