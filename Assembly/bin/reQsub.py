import re
import os
import sys

def getCompletedSet(log_path):
    completed_set = set()
    for log in os.popen('ls %s/*.log'%log_path):
        log = log.strip()
        sample = re.search('\S+\/Sample_(\S+)_K_(\d+).log',log).group(1)
        if re.search('^Time for the whole pipeline:',os.popen('tail -n 1 %s'%log).read()):
            completed_set.add(sample)
    return completed_set

def makeReQsubShell(out,ori_shell,completed_set):
    for shell in open(ori_shell):
        sample = re.search('K_\d+_Sample_(\S+).sh$',shell.strip()).group(1)
        if sample in completed_set:
            continue
        out.write(shell)

if __name__ == '__main__':
    sys.argv.pop(0)
    if len(sys.argv) != 2:
        raise ValueError,'usage: python reQsub.py in_shell out_shell'
    in_file,out_file = sys.argv
    cwd = os.getcwd()
    log_path = '%s/ass_log'%cwd
    cs = getCompletedSet(log_path)
    out = open(out_file,'w')
    makeReQsubShell(out,in_file,cs)
