import os
import sys
from QC_16S.Pipeline import Pipeline
from QC_16S.WorkStat import WorkStat
from QC_16S.Merge import Merge
#from QC_16S.WorkPerSample import WorkPerSample

def main(work_path,concurrency):

    pipeline = Pipeline(work_path,concurrency)
    canceled = not pipeline.total()
    if canceled:
        return False
#    sample_work = WorkPerSample(work_path,compact,sample_name,lib_method,data_type)

    stat = WorkStat(work_path,concurrency)
    stat.total()

    merge = Merge(work_path,concurrency)
    merge.merge()

if __name__ == '__main__':
    sys.argv.pop(0)
    if len(sys.argv) < 1:
        sys.stderr.write('Usage: python run_pipeline.py work_path [process_num] \n process_num default is cpu_count\n')
        sys.exit()
    work_path = sys.argv.pop(0)
    work_path = os.path.abspath(work_path)
    sys.stderr.write('Workdir is %s,pipeline begin\n'%work_path)
    if len(sys.argv) != 0:
        concurrency = int(sys.argv.pop(0))
    else:
        concurrency = cpu_count()

    main(work_path,concurrency)
