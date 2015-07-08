import os
import re
import sys
from templates import read_temp,insert_temp

def parse_insert(file):
    for line in open(file):
        if re.search('#\s+Peak:',line):
            insert = re.search('#\s+Peak:\s+(\d+)',line).group(1)
            return int(insert)

def main(dirs,if_pro):
    if if_pro:
        (sample_list,insert_dir,reads_dir) = dirs
        out = open('sample_with_insert.list','w')
    else:
        (sample_list,reads_dir) = dirs
        out = open('sample_without_insert.list','w')
    for sample in open(sample_list):
        sample = sample.strip()
        read1 = read_temp%{'path':reads_dir,'sample':sample,'type':'1'}
        read2 = read_temp%{'path':reads_dir,'sample':sample,'type':'2'}
        reads = read_temp%{'path':reads_dir,'sample':sample,'type':'single'}
        if if_pro:
            insert_file = insert_temp%{'path':insert_dir,'sample':sample}
            insert = parse_insert(insert_file)
            out.write('%s\t%s\t%s\t%s\t%s\n'%(sample,insert,read1,read2,reads))
        else:
            out.write('%s\t%s\t%s\t%s\n'%(sample,read1,read2,reads))

def geterr():
    sys.stderr.wrte('usage: python get_sample_list.py [pro] sample_list insert_dir reads_dir\n')

if __name__ == '__main__':
    script = sys.argv.pop(0)
    if len(sys.argv) == 4:
        if sys.argv.pop(0) == 'pro':
            sample_list,insert_dir,reads_dir = sys.argv
            insert_dir = os.path.abspath(insert_dir)
            reads_dir = os.path.abspath(reads_dir)
            main((sample_list,insert_dir,reads_dir),True)
        else:
            geterr()
    elif len(sys.argv) == 2: 
        sample_list,reads_dir = sys.argv
        insert_dir = os.path.abspath(insert_dir)
        reads_dir = os.path.abspath(reads_dir)
        main((sample_list,reads_dir),False)
    else:
        geterr()
