from __future__ import division
import sys
import types
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
def Q_ave(self):
    Q_sum = 0
    for qlist in  self.letter_annotations.itervalues():
        for q in qlist:
            Q_sum += q
        Q_ave = Q_sum / len(self)
        return Q_ave

def main(file,out_file,out_stat_file):
    SeqRecord.Q_ave = Q_ave
    out_stat = open(out_stat_file,'w')
    out = open(out_file,'w')

    count = 0
    for record in SeqIO.parse(open(file),'fastq'):
        if record.Q_ave() < 20:
            continue
        if len(record) < 220 or len(record) > 500 :
            continue
        out.write(record.format('fastq'))
        count += 1

    out_stat.write('%s\n'%count)

if __name__ == '__main__':
    sys.argv.pop(0)
    if len(sys.argv) != 3:
        sys.stderr.write('python QC.py in_file out_file out_stat_file')
        sys.exit()
    file,out_file,out_stat_file = sys.argv
    main(file,out_file,out_stat_file)

