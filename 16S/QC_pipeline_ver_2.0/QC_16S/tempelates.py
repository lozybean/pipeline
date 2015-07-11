from string import Template

class MyTemplate(Template):
    delimiter = '$'
    def get(self,d):
        return self.safe_substitute(d)

pandaseq_cmd = MyTemplate('pandaseq -F -f ${read1} -r ${read2} -w ${out_file} -p ${f_primer} -q ${r_primer} -g ${log_file} -l 220 -L 500')
