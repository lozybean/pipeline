import re
import sys
import os
primer = {
    'HXT': {
        '16S':{
            'forward':'CCTACGGGNGGCWGCAG',
            'reverse':'GACTACHVGGGTATCTAATCC',
        },
        'ITS':{
            'forward':'GCATCGATGAAGAACGCAGC',
            'reverse':'TCCTCCGCTTATTGATATGC',
        },
    },
    'Self': {
        '16S':{
            'forward':'GGACTACHVGGGTWTCTAAT',
            'reverse':'ACTCCTACGGGAGGCAGCAG',
        },
        'ITS':{
            'forward':'TCCTCCGCTTATTGATATGC',
            'reverse':'GCATCGATGAAGAACGCAGC',
        },
    },
}
'''
primer = {
    '1':{
        'forward':'CCTACGGGNGGCWGCAG',
        'reverse':'GACTACHVGGGTATCTAATCC',
    },
    '2':{
        'forward':'ACTCCTACGGGAGGCAGCAG',
        'reverse':'GGACTACHVGGGTWTCTAAT',
    },
}
'''
def getHash():
    sample_hash = {}
    for file in os.popen('ls %s/01_QC/00_rmAdaptor/*.fq'%cwd):
        sample = re.search('(\S+)\.\d+\.fq',file.strip()).group(1)
        sample_hash[os.path.basename(sample)] = {
            'read1':'%s.1.fq'%sample,
            'read2':'%s.2.fq'%sample,
        }
    return sample_hash

def getSh(sample_hash,lib_method,data_type):
    for sample in sorted(sample_hash.iterkeys()):
        read1 = sample_hash[sample]['read1']
        read2 = sample_hash[sample]['read2']
        os.system('mkdir -p %s/01_QC/01_pandaseq'%cwd)
        os.system('mkdir -p %s/01_QC/01_pandaseq_log'%cwd)
        fa_out = '%s/01_QC/01_pandaseq/%s.fq'%(cwd,sample)
        log_out = '%s/01_QC/01_pandaseq_log/%s.log'%(cwd,sample)
        print data_type
        sh_handle.write('pandaseq -F -f %s -r %s -w %s -p %s -q %s -g %s -l 220 -L 500\n'%(read1,read2,fa_out,primer[lib_method][data_type]['forward'],primer[lib_method][data_type]['reverse'],log_out))

if __name__ == '__main__':
    cwd = os.getcwd()
    sys.argv.pop(0)
    if len(sys.argv) != 2:
        sys.stderr.write('usage: python run_pandaseq.py lib_method data_type\n\nlib_method is one of the folowed list:\nHXT\nSelf\n\ndata_type is one of the followed list:\n16S\nITS\n\n')
        sys.exit()
    lib_method,data_type = sys.argv
    sh_handle = open('pandaseq.sh','w')
    sample_hash = getHash()
    getSh(sample_hash,lib_method,data_type)
