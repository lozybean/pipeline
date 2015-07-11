from __future__ import division
from threading import Thread,Lock
from multiprocessing import cpu_count
import threading
import sys
import os
import re
import types
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
def fq_reads_num(fq_file):
    wc_out = os.popen('wc -l %s'%fq_file).read().strip()
    result = int(re.search('^(\d+)',wc_out).group(1)) / 4
    return int(result)
def N_count(self):
    N_count = 0;
    for char in self.seq:
        if char == 'N':
            N_count += 1
    return N_count
def Q_ave(self):
    Q_sum = 0
    for qlist in  self.letter_annotations.itervalues():
        for q in qlist:
            Q_sum += q
        Q_ave = Q_sum / len(self)
        return Q_ave

def QC(file,out_file,out_stat_file,data_type):
    SeqRecord.Q_ave = Q_ave
    out_stat = open(out_stat_file,'w')
    out = open(out_file,'w')

    count = 0
    high_count = 0
    for record in SeqIO.parse(open(file),'fastq'):
        count += 1
        if record.Q_ave() < 20:
            continue
        if len(record) < 220 or len(record) > 500:
            continue
        out.write(record.format('fastq'))
        high_count += 1
    high_ratio = high_count / count * 100
    out_stat.write('%s\t%s\t%s\t%2.2f%%\n'%(data_type,count,high_count,high_ratio))

class MyList(list):
    def __str__(self):
        out_str = ''
        for item in self:
            out_str += item
            out_str += '\t'
        return out_str.strip()

def parse_stat(stat_file):
    tabs = os.popen('cat %s'%stat_file).read().strip().split('\t')
    yield tabs

def parse_stat_files(compact_path):
    for f in os.popen('ls %s/*/*.stat'%compact_path):
        stat_file = f.strip()
        sample_name =  re.search('%s\/(\S+)\/high_quality\.stat'%compact_path,stat_file).group(1)
        yield stat_file,sample_name

def reads_stat(compact_path):
    out = open('%s/reads_stat.xls'%compact_path,'w')
    sample_reads = {}
    for stat_file,sample_name in parse_stat_files(compact_path):
        for tabs in parse_stat(stat_file):
            sample_reads[sample_name] = tabs

    out.write('sample_name\tsample_type\traw_reads\tHQ_reads\tHQ_ratio\n')
    for sample,tabs in sample_reads.iteritems():
        tabs = MyList(tabs)
        out.write('%s\t%s\n'%(sample,str(tabs)))
    out.close()
class SubThread():
    ret = {}
    def raw_stat_thread(self,fq_file,lock,compact,sample_name,tabs):
        global total_reads
#    sys.stderr.write('thread %s stat with %s %s\n'%(threading.currentThread().ident,compact,sample_name))
        raw_reads = fq_reads_num(fq_file)
        lock.acquire()
        total_reads += raw_reads
        data_type = tabs.pop(0)
        try:
            ratio = int(tabs[1]) / raw_reads * 100
            tabs = str(MyList(tabs))
            if not SubThread.ret.has_key(compact):
                SubThread.ret[compact] = {}
            if not SubThread.ret[compact].has_key(data_type):
                SubThread.ret[compact][data_type] = {}
            if not SubThread.ret[compact][data_type].has_key(sample_name):
                SubThread.ret[compact][data_type][sample_name] = ''
            SubThread.ret[compact][data_type][sample_name] = '%s\t%s\t%2.2f%%'%(raw_reads,tabs,ratio)
#        out.write('%s\t%s\t%s\t%s\t%s\t%2.2f%%\n'%(compact,sample_name,data_type,raw_reads,tabs,ratio))
        except:
            pass
        finally:
            lock.release()
            return 
#    sys.stderr.write('thread %s finished doing with %s %s\n'%(threading.currentThread().ident,compact,sample_name))

total_reads = 0

def parse_sort_all_sample(file):
    for line in open(file):
        tabs = re.split('\s+',line.strip())
        yield tabs

def reads_stat_all(work_path,original_path):
    global total_reads
    QC_path = '%s/QC'%work_path
    sys.stderr.write('\nmerge stat is begin ... \n')
    out = open('%s/reads_stat.xls'%QC_path,'w')
    compact_hash = {}
    for f in os.listdir(QC_path):
        compact = f.strip()
        compact_path = '%s/%s'%(QC_path,compact)
        if not os.path.isdir(compact_path):
            continue
        if not compact_hash.has_key(compact):
            compact_hash[compact] = {}
        for stat_file,sample_name in parse_stat_files(compact_path):
            for tabs in parse_stat(stat_file):
                compact_hash[compact][sample_name] = tabs
    out.write('compact\tsample_name\tdata_type\traw_reads\tpandaseq_reads\tHQ_reads\tratio\n')
    lock = Lock()
    active_threads = set()
    for compact,sample in compact_hash.iteritems():
        sys.stderr.write('doing with %s stat\n'%compact)
        for sample_name,tabs in sample.iteritems():
            original_fq = os.popen('ls %s/%s/%s/*'%(original_path,compact,sample_name)).read().strip().split('\n').pop(0)
            obj = SubThread()
            t = Thread(target=obj.raw_stat_thread,args=(original_fq,lock,compact,sample_name,tabs))
            active_threads.add(t)
            t.start()
            while True:
                if threading.activeCount() < cpu_count():
                    break
#    out.flush()
    for t in threading.enumerate():
        if t in active_threads:
            sys.stderr.write('thread %s  is still alive, wait ...\n'%t.ident)
            t.join()
            
    out_hash = SubThread.ret
    del SubThread.ret
    
    sort_sample_file = '%s/Split/sam_barcode.all'%work_path
    for (compact,sample_name,barcode_info,data_type) in parse_sort_all_sample(sort_sample_file):
        if ( compact not in out_hash ) or (data_type not in out_hash[compact]) or (sample_name not in out_hash[compact][data_type]):
            out.write('%s\t%s\t%s\t%s\n'%(compact,sample_name,data_type,'None'))
            continue
        out.write('%s\t%s\t%s\t%s\n'%(compact,sample_name,data_type,out_hash[compact][data_type][sample_name]))

    sys.stderr.write('Unaligned stating ...\n')
    out.write('\n###\n')
    unalign_fq = os.popen('ls %s/Unalign/*'%original_path).read().strip().split('\n').pop(0)
    unalign_reads = fq_reads_num(unalign_fq)
    total_reads += unalign_reads
    ratio = unalign_reads / total_reads * 100
    out.write('Unalign\t%s\t%2.2f%%\n'%(unalign_reads,ratio))
    out.close()
    sys.stderr.write('merge stat is all finished!\n\n')

def pandaseq(pandaseq_soft,read1,read2,fa_out,f_primer,r_primer,log_out):
    cmd = '%s -F -f %s -r %s -w %s -p %s -q %s -g %s -l 220 -L 500'%(pandaseq_soft,read1,read2,fa_out,f_primer,r_primer,log_out)
    os.system(cmd)

def sampleMerge(sample_list,data_type,file_path,outfile):
    outhandle = open(outfile,'w')
#    sys.stderr.write('Begin merge into %s\n'%file_path)
    reads_num = {}
    f_template = '%s/%s/high_quality.fq'
    for sample in sample_list:
        f = f_template%(file_path,sample)
        sample = re.sub('[-_]','.',sample)
        sample = '%s%s'%(data_type,sample)
        if not reads_num.has_key(sample):
            reads_num[sample] = 0
        for record in SeqIO.parse(open(f),'fastq'):
            reads_num[sample] += 1
            outhandle.write('>%s_%s\n%s\n'%(sample,reads_num[sample],str(record.seq)))
    outhandle.close()
    sys.stderr.write('merge file: %s is finished\n'%outfile)

def get_lib_method(file):
    file = os.path.basename(file)
    if re.match('^sam_barcode.l$',file):
        lib_method = 'Self'
    elif re.match('^sam_barcode.s\d+$',file):
        lib_method = 'HXT'
    else:
        lib_method = None
    return lib_method
