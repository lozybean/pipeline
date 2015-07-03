config_01_pickotu_template='''#######Adjust the parameters according to your project
fna_anly        %(fna_file)s
################make otu table
usearch /data_center_01/home/NEOLINE/wuchunyan/software/usearch7.0.1090_i86linux32
fasta_number    /data_center_01/home/NEOLINE/wuleyun/wuly/python_module/16s/fasta_number.py
uc2otutab       /data_center_01/pipeline/16s_pipeline/bin/01_uc2otutab.pl
otus2fa /data_center_01/pipeline/16s_pipeline/bin/01_otus2fa.pl
sumOTUPerSample /data_center_01/pipeline/16s_pipeline/bin/01_sumOTUPerSample.pl
###############
perl    /usr/bin/perl
python  %(python)s
############tar
md5sum  /usr/bin/md5sum
###reference data base
rdp_gold_fa     /data_center_01/home/NEOLINE/wuchunyan/database/rdp_gold.fa
'''
config_02_alpha_div_template = '''#######Adjust the parameters according to your project
gnum    %(gnum)s
group   %(group_file)s
all     %(reads_cutoff_num)s
alpha_rarefaction_min_all       10
apha_rarefaction_step_number_all        200
col_by_group    N
##### alpha diversity
pick_rep_set    /home/snowflake/local/bin/pick_rep_set.py
align_seqs      /home/snowflake/local/bin/align_seqs.py
assign_taxonomy /home/snowflake/local/bin/assign_taxonomy.py
filter_alignment        /home/snowflake/local/bin/filter_alignment.py
make_phylogeny  /home/snowflake/local/bin/make_phylogeny.py
make_otu_table  /home/snowflake/local/bin/make_otu_table.py
multiple_rarefactions   /home/snowflake/local/bin/scripts/multiple_rarefactions.py
alpha_diversity /home/snowflake/local/bin/alpha_diversity.py
collate_alpha   /home/snowflake/local/bin/collate_alpha.py
alpha_rare_curve        /data_center_01/pipeline/16s_pipeline/bin/02_alpha_rare_curve.pl
alpha_metric    chao1,observed_species,PD_whole_tree,shannon,simpson,goods_coverage
alpha   chao1.txt observed_species.txt PD_whole_tree.txt shannon.txt simpson.txt goods_coverage.txt
#### align sequence method
assign_taxonomy_method  rdp
align_seqs_method       pynast
###############
perl    /usr/bin/perl
python  %(python)s
###reference data base
pynast_template_alignment_fp    /data_center_01/soft/greengenes/core_set_aligned.fasta.imputed
lane_mask_fp    /data_center_01/soft/greengenes/lanemask_in_1s_and_0s
assign_taxonomy_reference_seqs_fp       /data_center_01/soft/greengenes/gg_12_10_otus/rep_set/97_otus.fasta
assign_taxonomy_id_to_taxonomy_fp       /data_center_01/soft/greengenes/gg_12_10_otus/taxonomy/97_otu_taxonomy.txt
'''
config_03_tax_div_template = '''#######Adjust the parameters according to your project
fna_anly        /data_center_01/pipeline/16s_pipeline/together.fna
gnum    %(gnum)s
group   %(group_file)s
downsize        %(reads_cutoff_num)s
alpha_rarefaction_min_downsize  11
apha_rarefaction_step_number_downsize   23
################downsize
sample_downsize /data_center_01/pipeline/16s_pipeline/bin/03_sample_downsize.pl
sumOTUPerSample /data_center_01/pipeline/16s_pipeline/bin/01_sumOTUPerSample.pl
otus2fa /data_center_01/pipeline/16s_pipeline/bin/01_otus2fa.pl
###############otu
pick_rep_set    /home/snowflake/local/bin/pick_rep_set.py
assign_taxonomy /home/snowflake/local/bin/assign_taxonomy.py
make_otu_table  /home/snowflake/local/bin/make_otu_table.py
summarize_taxa  /home/snowflake/local/bin/scripts/summarize_taxa.py
biom    /home/snowflake/local/bin/biom
venn    /data_center_01/pipeline/16s_pipeline/bin/03_venn.pl
stars   /data_center_01/pipeline/16s_pipeline/bin/03_tax_stars.pl
otu_tax_sample_bar      /data_center_01/pipeline/16s_pipeline/bin/03_otu_tax_sample_bar.pl
otu_tax_group_bar       /data_center_01/pipeline/16s_pipeline/bin/03_otu_tax_group_bar.pl
core_otu        /data_center_01/pipeline/16s_pipeline/bin/03_core_otu.pl
get_otu_uniform /data_center_01/pipeline/16s_pipeline/bin/03_get_otu_uniform.pl
otu_pca /data_center_01/pipeline/16s_pipeline/bin/03_otu_pca.pl
otu_statistics  /data_center_01/pipeline/16s_pipeline/bin/03_otu_statistics.pl
tax_heatmap     /data_center_01/pipeline/16s_pipeline/bin/03_tax_heatmap.pl
##### alpha diversity
align_seqs      /home/snowflake/local/bin/align_seqs.py
filter_alignment        /home/snowflake/local/bin/filter_alignment.py
make_phylogeny  /home/snowflake/local/bin/make_phylogeny.py
multiple_rarefactions   /home/snowflake/local/bin/scripts/multiple_rarefactions.py
alpha_diversity /home/snowflake/local/bin/alpha_diversity.py
collate_alpha   /home/snowflake/local/bin/collate_alpha.py
alpha_metric    chao1,observed_species,PD_whole_tree,shannon,simpson,goods_coverage
alpha   chao1.txt observed_species.txt PD_whole_tree.txt shannon.txt simpson.txt goods_coverage.txt
alpha_diff      /data_center_01/pipeline/16s_pipeline/bin/04_alpha_diff.pl
###################beta
group2mapfile   /data_center_01/pipeline/16s_pipeline/bin/04_group2mapfile.pl
beta_diversity_through_plots    /home/snowflake/local/bin/beta_diversity_through_plots.py
Draw_beta_heatmap       /data_center_01/pipeline/16s_pipeline/bin/04_Draw_beta_heatmap.pl
beta_boxplot    /data_center_01/pipeline/16s_pipeline/bin/04_beta_boxplot.pl
beta_pca        /data_center_01/pipeline/16s_pipeline/bin/04_beta_pca.pl
################diff taxa
otu_transL      /data_center_01/pipeline/16s_pipeline/bin/05_otu_transL.pl
otu_alllevel    /data_center_01/pipeline/16s_pipeline/bin/05_otu_alllevel.pl
tax_diff        /data_center_01/pipeline/16s_pipeline/bin/05_tax_diff.pl
otu_diff_statistics     /data_center_01/pipeline/16s_pipeline/bin/05_otu_diff_statistics.pl
tax_marker_boxplot      /data_center_01/pipeline/16s_pipeline/bin/05_tax_marker_boxplot.pl
marker.tax      /data_center_01/pipeline/16s_pipeline/bin/05_marker.tax.pl
pca_diff        /data_center_01/pipeline/16s_pipeline/bin/05_pca_diff.pl
diff_tax_heatmap        /data_center_01/pipeline/16s_pipeline/bin/05_diff_tax_heatmap.pl
tax_qcutoff     0.05
color1_num      10
color2_num      900
tax_profile_list        otu_table_all.trans.txt otu_table_L6.txt
#### align sequence method
assign_taxonomy_method  rdp
align_seqs_method       pynast
###############
perl    /usr/bin/perl
python  %(python)s
###reference data base
pynast_template_alignment_fp    /data_center_01/soft/greengenes/core_set_aligned.fasta.imputed
lane_mask_fp    /data_center_01/soft/greengenes/lanemask_in_1s_and_0s
assign_taxonomy_reference_seqs_fp       /data_center_01/soft/greengenes/gg_12_10_otus/rep_set/97_otus.fasta
assign_taxonomy_id_to_taxonomy_fp       /data_center_01/soft/greengenes/gg_12_10_otus/taxonomy/97_otu_taxonomy.txt
'''
