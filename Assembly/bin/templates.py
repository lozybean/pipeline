cfgtemplate_pro_with_single = '''max_rd_len=150
[LIB]
avg_ins=%(insert_size)s
asm_flags=3
rank=1
q1=%(read1)s
q2=%(read2)s
[LIB]
asm_flags=1
rank=1
q=%(reads)s
'''

cfgtemplate_pro = '''max_rd_len=150
[LIB]
avg_ins=%(insert_size)s
asm_flags=3
rank=1
q1=%(read1)s
q2=%(read2)s
'''

cfgtemplate_with_single = '''max_rd_len=150
[LIB]
avg_ins=500
asm_flags=3
rank=1
q1=%(read1)s
q2=%(read2)s
[LIB]
asm_flags=1
rank=1
q=%(reads)s
'''

cfgtemplate = '''max_rd_len=150
[LIB]
avg_ins=500
asm_flags=3
rank=1
q1=%(read1)s
q2=%(read2)s
'''

SOAPdenovo_template='''SOAPdenovo-63mer all -s %(cfgfile)s -o %(out_pre)s -K %(kmer)s -M 3 -d 1 -L 94 -F -u &>%(ass_log)s
'''

qsub_template='''qsub -cwd -l vf=%(vf)s -q %(queue)s -e %(cmd_log_pre)s.e -o %(cmd_log_pre)s.o %(cmd_file)s
'''

soap_build_index_template='''if [ ! -L %(index)s ];then ln -s %(ori_file)s %(index)s fi
2bwt-builder %(index)s
'''
soap_template='''/data_center_03/USER/lih/Pipeline/soap/soap2.21release/soap -a %(fq1)s -b %(fq2)s -D %(index)s.index -m 0 -x 1000 -o %(pe)s -2 %(se)s
'''
insert_template'''
/data_center_01/home/NEOLINE/liangzebin/pipeline/Assembly/bin/soap2_insert.pl --prefix %(insert_out)s %(pe)s
'''

read_temp = '''%(path)s/%(sample)s.rmHost.%(type)s.fq'''
insert_temp = '''%(path)s/%(sample)s.insert'''


