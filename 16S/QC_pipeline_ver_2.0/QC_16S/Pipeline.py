import os
import re
import sys
from WorkPerSample import WorkPerSample
from multiprocessing import Process,JoinableQueue,Queue
from settings import get_lib_method

class Pipeline(object):

    def __init__(self,work_path='./',concurrency=5):
        work_path = os.path.abspath(work_path)
        self.work_path = work_path
        self.concurrency = concurrency
        self.path = {   'QC'    :   '%s/QC'%work_path,
                        'split' :   '%s/Split'%work_path,
                    }
        self.jobs = JoinableQueue()
        self.processes = []
        self.sam_barcode_files = map( lambda s:s.strip(), os.popen('ls %s/sam_barcode.*'%self.path['split']).readlines() )

    def _create_samples(self):
        for sam_barcode_file in self.sam_barcode_files:
            lib_method = get_lib_method(sam_barcode_file)
            if lib_method == None:
                continue
            sys.stdout.write('sam_barcode_file: %s          ... ok\n'%sam_barcode_file)
            for line in open(sam_barcode_file):
                (compact,sample_name,barcode_info,data_type) = re.split('\s+',line.strip())
                sample = WorkPerSample(self.work_path,compact,sample_name,lib_method,data_type)
                yield sample
                
    def add_jobs(self):
        job_num = 0
        for sample in self._create_samples():
            self.jobs.put(sample)
            job_num += 1
#            sys.stdout.write('The job is pushed into the queue,with compact:%s sample_name:%s\n'%(sample.compact,sample.sample_name))
#        sys.stdout.write('\n### All %s jobs have been pushed into the queue ###\n'%job_num)

    def create_process(self):
        sys.stdout.write('\nBegin create jobs with %s Process\n'%self.concurrency)
        for _ in range(self.concurrency):
            process = Process(target=self.worker)
            process.daemon = True
            process.start()
            self.processes.append(process)

    def worker(self):
        while True:
            try:
                sample = self.jobs.get()
                try:
                    sample.pandaseq()
                    sample.QC()
                    sys.stdout.write('Process %s is finished doing with compact:%s sample_name:%s\n'%(os.getpid(),sample.compact,sample.sample_name))
                except:
                    sample.work_times += 1
                    work_time = 5 - sample.work_times
                    if work_time > 0:
                        sys.stderr.write('Process %s is FIALED !!! %s/%s will be redo %s times!\n'%(os.getpid(),sample.compact,sample.sample_name,work_time))
                        self.jobs.put(sample)
                    else:
                        sys.stderr.write('Process %s is FIALED !!! More Than 5 times Redo, %s/%s may be some problem!\n'%(os.getpid(),sample.compact,sample.sample_name))
            finally:
                self.jobs.task_done()

    def total(self):
        self.add_jobs()
        self.create_process()
        canceled = False
        try:
            self.jobs.join()
        except KeyboardInterrupt:
            sys.stderr.write('cancelling ... \n')
            canceled = True
        return not canceled
   
