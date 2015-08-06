#!/usr/bin/env perl
use strict;
use Getopt::Long;

my ($map,$weight,$unweight,$group,$dir,$help);

GetOptions (
	'm:s'	=>	\$map,
	'w:s'	=>	\$weight,
	'u:s'	=>	\$unweight,
	'g:s'	=>	\$group,
	'd:s'	=>	\$dir,
	'h:s'	=>	\$help,
);

sub usage {
	die "
Description:
	use to draw beta heatmap for 16S 454 project
	
Version:
	version1 2013-08-30
	
Author:
	huangyf\@genomics.org.cn
	
Usage:
	perl $0
	
	-m [s]	Mapping file
	-w [s]	weighted result of beta diversity
	-u [s]	Unweihted result of beta diversity
	-g [s]	Name of group colunm, T(Treatment), D(Description) or T,D
	-d [s]	Output directory
	-h [s]	Help message
	\n\n";
}

$dir ||= "./";

unless (defined $map && defined $group) {
	&usage;
	exit;
}

#------------------------------------------------------------------------
chomp (my $pwd = `pwd`);
$dir = ($dir eq "./") ? $pwd : ($dir =~ /^\//) ? $dir : $pwd."/".$dir;
system ( "mkdir $dir" ) unless ( -d $dir );

#-------------------------------------------------------------------------
my (@infile,$W_head);
if (defined $weight) {
	chomp ($W_head = `head -n 1 $weight`);
	push @infile, $weight;
}
if (defined $unweight) {
	push @infile, $unweight;
	chomp ($W_head = `head -n 1 $unweight`);
}

my $R_input;
foreach my $infile (@infile) {
	$R_input .= "\"$infile\",";
}
chop ($R_input);

my $lines = (split /\s+/,`wc -l $map`)[0];
my $sample_num = $lines - 1;
my $mfrow = ($sample_num > 10) ? "c(1,1)" : "c(2,2)";
my $R_pars = ($sample_num <= 10) ? "fontsize=7, cellwidth=15, cellheight=12" : ($sample_num>10 && $sample_num <=20) ? "cellwidth=15, cellheight=12" : "";
my $png_pars = ($sample_num <= 10) ? "width=400, height=400" : ($sample_num>10 && $sample_num <=20) ? "width=600, height=600" : "width=1000, height=1000";

#-------------------------------------- two groups ------------------------------------------
if ($group =~ /\,/) {
	my($t_g,$d_g) = &two_group($map,$group,$W_head);

my$Rscript = <<R;
library (NMF)
file <- c($R_input)
Group1 <- c($t_g)
Group2 <- c($d_g)
annotation <- data.frame(Group1,Group2)
pdf("$dir/Beta_diversity_heatmap.pdf")
#par(mfrow=$mfrow)
for (i in 1:length(file)) {
	infile <- read.table(file[i],header=T,check.names=F)
	
	if (grepl("unweighted",file[i]) == "TRUE") {
		main = "Unweighted UniFrac Distance"
	} else {
		main = "Weighted UniFrac Distance"
	}
	aheatmap(infile, Rowv=FALSE, Colv=TRUE, distfun="correlation", hclustfun="complete", annCol=annotation, main=main, $R_pars)
}
dev.off()

for(i in 1:length(file)) {
	infile <-read.table(file[i],header=T,check.names=F)
	if(grepl("unweighted",file[i]) == "TRUE") {
		main = "Unweighted UniFrac Distance"
		name = "unweighted"
	} else {
		main = "Weighted UniFrac Distance"
		name = "weighted"
	}
	png.name=paste("$dir/Beta_",name,"_diversity_heatmap.png",sep="")
	png(png.name,$png_pars,type="cairo")
	aheatmap(infile, Rowv=FALSE, Colv=TRUE, distfun="correlation", hclustfun="complete", annCol=annotation, main=main,$R_pars)
}
dev.off()
R
	open RS, ">$dir/Beta_diversity_heatmap.r" || die $!;
	print RS "$Rscript";
	close RS;
}

#------------------------------------- one group ---------------------------------------------
if ($group !~ /\,/) {
	my $t_g = &one_group($map,$group,$W_head);

my$Rscript = <<R;
library (NMF)
file <- c($R_input)
Group <- c($t_g)
annotation <- data.frame(Group)
pdf("$dir/Beta_diversity_heatmap.pdf")
#par(mfrow=$mfrow)
for (i in 1:length(file)) {
	infile <- read.table(file[i],header=T,check.names=F)
	
	if (grepl("unweighted",file[i]) == "TRUE") {
		main = "Unweighted Unifrac Distance"
	} else {
		main = "Weighted Unifrac Distance"
	}
	if (length(unique(Group)) >1) {	
		aheatmap(infile, Rowv=FALSE, Colv=TRUE, distfun="correlation", hclustfun="complete", annCol=annotation, main=main, $R_pars)
	} else {
		aheatmap(infile, Rowv=FALSE, Colv=TRUE, distfun="correlation", hclustfun="complete", main=main, $R_pars)
	}
}
dev.off()

for(i in 1:length(file)) {
	infile <-read.table(file[i],header=T,check.names=F)
	if(grepl("unweighted",file[i]) == "TRUE") {
		main = "Unweighted UniFrac Distance"
		name = "unweighted"
	} else {
		main = "Weighted UniFrac Distance"
		name = "weighted"
	}
	png.name=paste("$dir/Beta_",name,"_diversity_heatmap.png",sep="")
	png(png.name,$png_pars,type="cairo")
	if (length(unique(Group)) >1) { 
		aheatmap(infile, Rowv=FALSE, Colv=TRUE, distfun="correlation", hclustfun="complete", annCol=annotation, main=main,$R_pars)
	} else {
		aheatmap(infile, Rowv=FALSE, Colv=TRUE, distfun="correlation", hclustfun="complete", main=main, $R_pars)
	}
}
dev.off()
R
	open RS, ">$dir/Beta_diversity_heatmap.r";
	print RS "$Rscript";
	close RS;
}

`/data_center_01/home/NEOLINE/wuchunyan/software/R/R-3.0.1/bin/Rscript $dir/Beta_diversity_heatmap.r`;


#---------------------------------- sub programm 1-------------------------#
sub two_group {
	my ($map,$group,$W_head) = @_;
	my (%treat,%descrip,$sample_num);
	open MAP, $map || die "can not open: $map";
	chomp (my $M_head = <MAP>);
	my @M_head = split /\t/,$M_head;
	while (<MAP>) {
		chomp;
		$sample_num ++;
		my @array = split /\t/;
		my @group = split /\,/,$group;
		if ($group[0] eq "T") {
			$group[0] = "Treatment";
			$group[1] = "Description";
		}elsif ($group[0] eq "D") {
			$group[1] = "Treatment";
			$group[0] = "Description";
		}
		for (my $i =0; $i <= $#M_head; $i ++) {
				if ($M_head[$i] eq "$group[0]") {				
					$treat{$array[0]}{$array[$i]} = 1;
				} 
				if ($M_head[$i] eq "$group[1]") {
					$descrip{$array[0]}{$array[$i]} = 1;
			}
		}
	}
	close MAP;

	my @W_head = split /\t/,$W_head;
	my ($t_g,$d_g);
	for (my $i=0; $i<=$#W_head; $i++) {
		foreach my $g_name (keys %{$treat{$W_head[$i]}}) {
			if (exists $treat{$W_head[$i]}{$g_name}) {
				$t_g .= "\"$g_name\",";
			}
		}
		foreach my $g_name (keys %{$descrip{$W_head[$i]}}) {
			if (exists $descrip{$W_head[$i]}{$g_name}) {
				$d_g .= "\"$g_name\",";
			}
		}
	}
	
	chop ($t_g);
	chop ($d_g);
	return ($t_g,$d_g);
}

#------------------------------------------ sub programm 2 -------------------------------------#
sub one_group {
	my ($map,$group,$W_head) = @_;
	
	my (%treat,$sample_num);
	open MAP, $map || "can not open: $map";
	chomp (my $M_head = <MAP>);
	my @M_head = split /\t/,$M_head;
	while (<MAP>) {
		chomp;
		$sample_num ++;
		my @array = split /\t/;
		if ($group eq "T") {
			$group = "Treatment";
		} elsif ($group eq "D") {
			$group = "Description";
		}
		for (my $i =0; $i <= $#M_head; $i++) {
			if ($M_head[$i] eq "$group") {
				$treat{$array[0]}{$array[$i]} = 1;
			}
		}
	}
	close MAP;

	my @W_head = split /\t/,$W_head;
	my $t_g;
	for (my $i=0; $i<=$#W_head; $i++) {
		foreach my $g_name (keys %{$treat{$W_head[$i]}}) {
			if (exists $treat{$W_head[$i]}{$g_name}) {
				$t_g .= "\"$g_name\",";
			}
		}
	}

	chop ($t_g);
	return ($t_g);

}

#------------------------------------- THE END ---------------------------------------#
