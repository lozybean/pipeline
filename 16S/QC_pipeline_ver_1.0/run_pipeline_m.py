#!/usr/bin/env python
import os
import sys
import re
import time
import collections
from multiprocessing import Process,JoinableQueue,Queue,cpu_count
from threading import Thread
from settings import primer,pandaseq_soft
from programs import *

Result = collections.namedtuple("Result","compact sample_name HQ_fq")
repushed_times = {}

def parse_sam_barcode_file(sam_barcode_file):
    for line in open(sam_barcode_file):
        yield re.split('\s+',line.strip())

def proc(compact,sample_name,work_path,lib_method,data_type):
    #return Result(compact,sample_name,'temp')
    split_path = '%s/Split'%work_path
    QC_path = '%s/QC'%work_path
    compact_path = '%s/%s'%(QC_path,compact)
    if not os.path.exists(compact_path):
        os.makedirs(compact_path)
    sample_path = '%s/%s'%(compact_path,sample_name)
    if not os.path.exists(sample_path):
        os.makedirs(sample_path)
    original_path = '%s/%s/%s'%(split_path,compact,sample_name)
    (read1,read2) = os.popen('ls %s/*'%original_path).read().strip().split('\n')
    pandaseq_fq = '%s/pandaseq.fq'%sample_path
    pandaseq_log = '%s/pandaseq.log'%sample_path
    pandaseq(pandaseq_soft,read1,read2,pandaseq_fq,primer[lib_method][data_type]['forward'],primer[lib_method][data_type]['reverse'],pandaseq_log)
    high_quality_fq = '%s/high_quality.fq'%sample_path
    high_quality_log = '%s/high_quality.stat'%sample_path
    QC(pandaseq_fq,high_quality_fq,high_quality_log,data_type)
    return Result(compact,sample_name,high_quality_fq)

def worker(work_path,jobs,results):
    global repushed_times
    while True:
        try:
            compact,sample_name,lib_method,data_type = jobs.get()
            try:
                result = proc(compact,sample_name,work_path,lib_method,data_type)
                sys.stderr.write( 'Process %s is finished doing with compact:%s sample_name:%s\n'%(os.getpid(),compact,sample_name) )
                results.put(result)
            except:
                sys.stderr.write('Process %s is FIALED !!! %s/%s may be some problem!\n'%(os.getpid(),compact,sample_name))
                if compact not in repushed_times:
                    repushed_times[compact] = {}
                if sample_name not in repushed_times[compact]:
                    repushed_times[compact][sample_name] = 0
                if repushed_times[compact][sample_name] < 5:
                    jobs.put((compact,sample_name,lib_method,data_type))
                    repushed_times[compact][sample_name] += 1
                    sys.stderr.write('The job is repushed into the queue,with compact:%s sample_name:%s\n'%(compact,sample_name))
                else:
                    sys.stderr.write('The job is repushed more than 5 times,stopped! compact:%s sample_name:%s\n'%(compact,sample_name))
        finally:
            jobs.task_done()

def add_jobs(work_path,sam_barcode_file_list,jobs):
    job_num = 0
    data_type_hash = {}
    for todo,sam_barcode_file in enumerate(sam_barcode_file_list):
        sam_barcode_file = sam_barcode_file.strip()
        if not os.path.isfile(sam_barcode_file):
            continue
        lib_method = get_lib_method(sam_barcode_file)
        if lib_method is None:
            continue
        print 'sam_barcode_file loading: %s             ......  ok\n'%sam_barcode_file
        for compact,sample_name,barcode_info,data_type in parse_sam_barcode_file(sam_barcode_file):
            if not data_type_hash.has_key(compact):
                data_type_hash[compact] = {}
            if not data_type_hash[compact].has_key(data_type):
                data_type_hash[compact][data_type] = []
            data_type_hash[compact][data_type].append(sample_name)
            jobs.put((compact,sample_name,lib_method,data_type))
            job_num += 1
            sys.stderr.write('The job is pushed into the queue,with compact:%s sample_name:%s\n'%(compact,sample_name))
    sys.stderr.write('\n### All %s jobs have been pushed into the queue ###\n'%job_num)
    return data_type_hash

def create_processes(concurrency,jobs,work_path,results):
    print '\nBegin create jobs with %s Process...\n'%concurrency
    for _ in range(concurrency):
        process = Process(target=worker,args=(work_path,jobs,results))
        process.daemon = True
        process.start()

def main(work_path,sam_barcode_file_list):
    global concurrency
    split_path = '%s/Split'%work_path
    QC_path = '%s/QC'%work_path
    jobs = JoinableQueue()
    results = Queue()

    canceled = False
    data_type_hash = add_jobs(split_path,sam_barcode_file_list,jobs)
    create_processes(concurrency,jobs,work_path,results)
    try:
        jobs.join()
    except KeyboardInterrupt:
        sys.stderr.write('cancelling ...\n')
        canceled = True
    finally: 
        job_num = 0
        finished_hash = {}
        while not results.empty():
            result = results.get_nowait()
            job_num += 1
            if not finished_hash.has_key(result.compact):
                finished_hash[result.compact] = []
            finished_hash[result.compact].append(result.sample_name)
        sys.stderr.write('all %s work finished!\n\n'%job_num)
        log_out = open('%s/work.log'%QC_path,'w')
        for compact,sample_list in finished_hash.iteritems():
            for sample_name in sample_list:
                log_out.write('%s\t%s has been finished\n'%(compact,sample_name))
        log_out.close()    
    if canceled:
        return False

    for compact in os.listdir(QC_path):
        compact_dir = '%s/%s'%(QC_path,compact)
        if not os.path.isdir(compact_dir):
            continue
        sys.stderr.write('Begin stat compact: %s\n'%compact)
        reads_stat(compact_dir)
    sys.stderr.write('All campact stat finished!\n\n')
    
    reads_stat_all(work_path,split_path)
    
    return True
    merge_threads = set()
    for compact,subitem in data_type_hash.iteritems():
        compact_dir = '%s/%s'%(QC_path,compact)
        for data_type,sample_list in subitem.iteritems():
            merged_file = '%s/%s/%s.together.fna'%(QC_path,compact,data_type)
            t = Thread(target=sampleMerge,args=(sample_list,data_type,compact_dir,merged_file))
            merge_threads.add(t)
            t.start()
            while True:
                if threading.activeCount() < concurrency:
                    break
    for t in threading.enumerate():
        if t in merge_threads:
            t.join()

    sys.stderr.write('\n All pipeline is done ! \n')


if __name__ == '__main__':
    sys.argv.pop(0)
    if len(sys.argv) < 1:
        sys.stderr.write('Usage: python run_pipeline.py work_path [process_num] \n process_num default is cpu_count\n')
        sys.exit()
    work_path = sys.argv.pop(0)
    work_path = os.path.abspath(work_path)
    sys.stderr.write('Workdir is %s,pipeline begin\n'%work_path)
    sam_barcode_file_list = os.popen('ls %s/Split/sam_barcode.*'%work_path).read().strip().split('\n')
    if len(sys.argv) != 0:
        concurrency = int(sys.argv.pop(0))
    else:
        concurrency = cpu_count()

    main(work_path,sam_barcode_file_list)
