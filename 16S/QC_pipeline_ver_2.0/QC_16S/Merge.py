import os
import re
import threading
from Bio import SeqIO
from settings import rename


class MergePerCompact(object):
    def __init__(self,compact_path,data_type):
        self.id = {}
        self.path = compact_path
        self.data_type = data_type
        self.handle = open('%s/%s.together.fna'%(self.path,self.data_type),'w')

    def merge(self):
        for sample in os.listdir(self.path):
            sample_dir = '%s/%s'%(self.path,sample)
            if not os.path.isdir(sample_dir):
                continue
            hq_file = '%s/%s/high_quality.fq'%(self.path,sample)
            sample,lib_method = re.search('(\S+)_(\S+)',sample).groups()
            sample = rename(sample,self.data_type)
            if sample not in self.id:
                self.id[sample] = 1
            for record in SeqIO.parse(open(hq_file),'fastq'):
                self.handle.write('>%s_%s\n%s\n'%(sample,self.id[sample],str(record.seq)))
                self.id[sample] += 1

    def release(self):
        stderr.write('Merge complete!\t%s\n'%self.compact_path)
        self.handle.close()

class Merge(object):
    def __init__(self,work_path,concurrency):
        self.concurrency = concurrency
        self.path = {}
        self.path['QC'] = '%s/QC'%work_path
        self.path['split'] =  '%s/Split'%work_path
        self.get_data_type()
        self.active_threads = set()

    def get_compacts(self):
        for compact,data_type in self.compact_data_type.iteritems():
            compact_path = '%s/%s'%(self.path['QC'],compact)
            yield compact_path,data_type

    def get_data_type(self):
        self.compact_data_type = {}
        sam_barcode_file = '%s/sam_barcode.all'%self.path['split']
        for line in open(sam_barcode_file):
            (compact,sample_name,barcode_info,data_type,lib_method) = re.split('\s+',line.strip())
            compact_path = '%s/%s'%(self.path['QC'],compact)
            if compact not in self.compact_data_type:
                self.compact_data_type[compact] = data_type 
            elif self.compact_data_type[compact] != data_type:
                stderr.write('The compact %s has two diffrent data_type!'%compact)

    @staticmethod
    def worker(job):
        job.merge()
        job.release()

    def merge(self):
        for compact_path,data_type in self.get_compacts():
            job = MergePerCompact(compact_path,data_type)
            t = threading.Thread(target=self.worker,args=(job,))
            self.active_threads.add(t)
            t.start()
            while True:
                if threading.activeCount() < self.concurrency:
                    break
        for t in threading.enumerate():
            if t in self.active_threads:
                t.join()
    



