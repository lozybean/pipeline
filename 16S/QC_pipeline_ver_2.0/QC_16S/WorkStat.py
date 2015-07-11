from __future__ import division
import re
import os
import sys
import threading
from settings import get_lib_method,get_reads,get_unaligned

class WorkStat(object):    


    def __init__(self,work_path,concurrency=5):
        self.path = {}
        self.path['QC'] = '%s/QC'%work_path
        self.path['split'] = '%s/Split'%work_path
        self.total_reads = {}
        self.getSampleStruct()
        self.concurrency = concurrency
        self.__active_threads = set()

    def statPerCompact(self):
        for compact in os.listdir(self.path['QC']):
            compact_dir = '%s/%s'%(self.path['QC'],compact)
            if not os.path.isdir(compact_dir):
                continue
            sys.stderr.write('Begin stat compact: %s\n'%compact)
            self.reads_stat(compact)

    ## do per compact stat
    @staticmethod
    def parse_stat_file(compact_dir):
        for f in os.popen('ls %s/*/*.stat'%compact_dir):
            stat_file = f.strip()
            (sample_name,lib_method) = re.search('%s\/(\S+)_(\S+)\/high_quality\.stat'%compact_dir,stat_file).groups()
            yield stat_file,sample_name,lib_method
    @staticmethod
    def parse_stat(stat_file):
        tabs = os.popen('cat %s'%stat_file).read().strip().split('\t')
        yield tabs
    def reads_stat(self,compact):
        compact_dir = '%s/%s'%(self.path['QC'],compact)
        out = open('%s/reads_stat.xls'%compact_dir,'w')
        sample_reads = {}
        for stat_file,sample_name,lib_method in self.parse_stat_file(compact_dir):
            for tabs in self.parse_stat(stat_file):
                if lib_method not in sample_reads:
                    sample_reads[lib_method] = {}
                sample_reads[lib_method][sample_name] = tabs
        out.write('sample_name\tsample_type\tlib_method\traw_reads\tpandaseq_reads\tHQ_reads\tHQ_ratio\n')
        for lib_method,subitem in sample_reads.iteritems():
            for sample_name,tabs in subitem.iteritems():
                if len(tabs) < 4:
                    continue
                (data_type,pandaseq_reads,HQ_reads,HQ_ratio) = tabs
                self.sample_struct[compact][data_type][lib_method][sample_name]={
                            'pandaseq_reads'     :   pandaseq_reads,
                            'HQ_reads'      :   HQ_reads,
                            'HQ_ratio'      :   HQ_ratio,
                        }
                tabs = MyList(tabs)
                out.write('%s\t%s\n'%(sample_name,str(tabs)))
        out.close()
    ##
    @staticmethod
    def get_fq_num(fq_file):
        wc_out = os.popen('wc -l %s'%fq_file).read().strip()
        reads_num = int(re.search('^(\d+)',wc_out).group(1)) / 4
        return int(reads_num)

    def stat_raw_reads(self,compact,data_type,lib_method,sample_name):
        raw_path = '%s/%s/%s'%(self.path['split'],compact,sample_name)
        (read_file,read_file2) = get_reads(raw_path,lib_method)
        reads_num =  self.get_fq_num(read_file)
        self.sample_struct[compact][data_type][lib_method][sample_name]['raw_reads'] = reads_num
        self.total_reads[lib_method] += reads_num

    def statAll(self):
        out = open('%s/reads_stat.xls'%self.path['QC'],'w')
        out.write('compact\tsample_name\tdata_type\tlib_method\traw_reads\tpandaseq_reads\tHQ_reads\tHQ_ratio\tTotal_ratio\n')
        for compact,data_type_hash in self.sample_struct.iteritems():
            for data_type,lib_method_hash in data_type_hash.iteritems():
                for lib_method,sampleinfo in lib_method_hash.iteritems():
                    for sample,infos in sampleinfo.iteritems():
                        t = threading.Thread(target=self.stat_raw_reads,args=(compact,data_type,lib_method,sample))
                        self.__active_threads.add(t)
                        t.start()
                        while True:
                            if threading.activeCount() < self.concurrency:
                                break
        for t in threading.enumerate():
            if t in self.__active_threads:
                t.join()
        sort_sample_file = '%s/sam_barcode.all'%self.path['split']
        for line in  open(sort_sample_file):
            (compact,sample_name,barcode_info,data_type,lib_method) = re.split( '\s+', line.strip() )
            key_list = [compact,data_type,lib_method,sample_name]
            if not self.check_keys( key_list , self.sample_struct ):
                out.write('%s\t%s\t%s\t%s\t%s\t%s\n'%(compact,sample_name,data_type,lib_method,'None'))
                continue
            item = self.sample_struct[compact][data_type][lib_method][sample_name]
            t_ratio = int(item['HQ_reads']) / int(item['raw_reads']) * 100
            out_str = str(MyList((item['raw_reads'],item['pandaseq_reads'],item['HQ_reads'],item['HQ_ratio'])))
            out.write('%s\t%s\t%s\t%s\t%s\t%2.2f%%\n'%(compact,sample_name,data_type,lib_method,out_str,t_ratio))
        out.close()

    def statUnaligned(self):
        out = open('%s/unaligned_stat.txt'%self.path['QC'],'w')
        out.write('Unaligned_file\treads_num\n')
        unalign_path = '%s/Unalign'%self.path['split']
        for file_name,file in get_unaligned(unalign_path):
            reads_num = self.get_fq_num(file)
            out.write('%s\t%s\n'%(file_name,reads_num))
        out.write('\n\nlib_method\ttotal_reads\n')
        for lib_method,reads_num in self.total_reads.iteritems():
            out.write('%s\t%s\n'%(lib_method,reads_num))
        out.close()


    @staticmethod
    def check_keys(key_list,dict):
        dict = dict
        key = key_list.pop(0)
        while len(key_list) > 0:
            if key not in dict:
                return False
            dict = dict[key]
            key = key_list.pop(0)
        return True
    
    def getSampleStruct(self):
        self.sample_struct = {}
        for line in open('%s/sam_barcode.all'%self.path['split']):
            compact,sample_name,barcode_info,data_type,lib_method = re.split('\s+',line.strip())
            if compact not in self.sample_struct:
                self.sample_struct[compact] = {}
            if data_type not in self.sample_struct[compact]:
                self.sample_struct[compact][data_type] = {}
            if lib_method not in self.sample_struct[compact][data_type]:
                self.sample_struct[compact][data_type][lib_method] = {}
            if sample_name not in self.sample_struct[compact][data_type][lib_method]:
                self.sample_struct[compact][data_type][lib_method][sample_name] = {                           
                            'pandaseq_reads'     :   0,
                            'HQ_reads'      :   0,
                            'HQ_ratio'      :   0,
                            'raw_reads'    :   0,
}
            if lib_method not in self.total_reads:
                self.total_reads[lib_method] = 0

    def total(self):
        self.statPerCompact()
        self.statAll()
        self.statUnaligned()

class MyList(list):
    def __str__(self):
        out_str = ''
        for item in self:
            out_str += str(item)
            out_str += '\t'
        return out_str
    
