import re
import os
import sys
from Bio import SeqIO

sys.argv.pop(0)
readfile1,readfile2,outfile1,outfile2,barcode1,barcode2 = sys.argv

outpath = os.path.dirname(outfile1)
os.system('mkdir -p %s'%outpath)

out1 = open(outfile1,'w')
out2 = open(outfile2,'w')
reads2 = SeqIO.parse(open(readfile2),'fastq')
for read1 in SeqIO.parse(open(readfile1),'fastq'):
    read2 = reads2.next()
    pat1 = '^%s'%barcode1
    pat2 = '^%s'%barcode2
    if re.search(pat1,str(read1.seq)) and re.search(pat2,str(read2.seq)):
        read1 = read1[len(barcode1):]
        read2 = read2[len(barcode2):]
    else:
        continue
    out1.write(read1.format('fastq'))
    out2.write(read2.format('fastq'))
