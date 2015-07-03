import os
cwd = os.getcwd()
sh = open('QC.sh','w')
for file in os.popen('ls %s/01_QC/01_pandaseq'%cwd):
    in_file = '%s/01_QC/01_pandaseq/%s'%(cwd,file.strip())
    os.system('mkdir -p %s/01_QC/02_high_quality'%cwd)
    out_file = '%s/01_QC/02_high_quality/%s'%(cwd,file.strip())
    out_stat = out_file + '.stat'
    sh.write('python /data_center_01/home/NEOLINE/liangzebin/pipeline/16S/preparatory/QC.py %s %s %s\n'%(in_file,out_file,out_stat))
