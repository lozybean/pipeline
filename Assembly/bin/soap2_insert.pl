#!/usr/bin/perl
# Orginal author unknow, modify by liuwenbin, to add --prefix <str> --nodraw
#  --prefix    outfile prefix
#  --nodraw    noto draw insert distribution figure
#  also gzip form reads are allowed
#  Updata: 2011-12-22
use strict;
use warnings;
use PerlIO::gzip;
use Getopt::Long;
my ($prefix,$nodraw,$reverse); #add revrse parameter by lihang
GetOptions("prefix:s"=>\$prefix,"nodraw"=>\$nodraw,"R"=>\$reverse);
my $usage=<<USAGE;
	Usage:  $0 <soap2_result_file1> [soap2_result_file2] ...
	Sample: ./soap2_insert.pl ./sample.soap ./sample.single
	Input:  soap2 result files including pair-end and single-end files.
	Output: ./*.insert ./*.insert.pdf 
USAGE

die $usage unless (@ARGV);

my @input = @ARGV;
chomp @input;
$input[0] =~ /([^\/]+)$/;
$prefix ||= $1;
my $out = "$prefix.insert";

my $total_map_reads = 0;
my $total_single = 0;
my $total_repeat_pair = 0;
my $total_uniq_pair = 0;
my $total_uniq_low_pair = 0;
my $total_uniq_normal_pair = 0;

my %insert;
my $insert;
foreach my $input (@input) {
	($input =~ /\.gz$/) ? (open(IN, "<:gzip",$input) || die"$!,\n") : (open(IN,$input) || die"$!,\n");
	while (<IN>) {
		$total_map_reads+=2;
		my $line1 = $_;
		if (eof IN) {
			$total_map_reads--;
			last;
		}
		my $line2 = <IN>;
		my ($id1, $n1, $len1, $f1, $chr1, $x1, $m1) = (split "\t", $line1)[0,3,5,6,7,8,-2];
		my ($id2, $n2, $len2, $f2, $chr2, $x2, $m2) = (split "\t", $line2)[0,3,5,6,7,8,-2];
		$id1 =~ s/\/[12]$//;
		$id2 =~ s/\/[12]$//;
		if ($id1 ne $id2){ #single
			seek (IN, -length($line2),1);
			$total_map_reads--;
		}
#		elsif ($m1 ne "${len1}M" or $m2 ne "${len2}M") { #trim
#		}
		elsif ($chr1 ne $chr2) { #single
		}
		elsif ($n1!=1 or $n2!=1) { #repeat
			$total_repeat_pair++;
		}
		elsif ($f1 eq '+' && $f2 eq '-') {
#			$insert = $x2 - $x1 + $len2;
			$insert = $x2 - $x1;
            ($insert > 0) ? ($insert += $len2) : ($insert > -150) ? ($insert = $len1 - $insert) : ($insert -= $len1);
			$reverse && $insert>0 && next;
			$insert{$insert}++;
		}
		elsif ($f2 eq '+' && $f1 eq '-') {
#			$insert = $x1 - $x2 + $len1;
			$insert = $x1 - $x2;
            ($insert > 0) ? ($insert += $len1) : ($insert > -150) ? ($insert = $len2 - $insert) : ($insert -= $len2);
			$reverse && $insert>0 && next;
			$insert{$insert}++;
		}
	}
	close IN;
}


my $max_y = 0;
my $max_x = 0;
while (my ($k, $v) = each %insert) {
	next if $k < 200;
	if ($max_y < $v) {
		$max_y = $v;
		$max_x = $k;
	}
}
my $cutoff = $max_y / 1000;
$cutoff = 0 if $cutoff<3;

my @insert;
my @count;
my @cumul;
foreach (sort {$a<=>$b} keys %insert) {
	if ($insert{$_} < $cutoff){
		$total_uniq_low_pair += $insert{$_};
	}
	else {
		$total_uniq_normal_pair += $insert{$_};
		push @insert, $_;
		push @count,  $insert{$_};
		push @cumul,  $total_uniq_normal_pair;
	}
}

#my $half = $total_uniq_normal_pair/2;
#my $median;
#for (my $i=0; $i<@insert; $i++) {
#	if ($cumul[$i]>=$half) {
#		$median = $insert[$i];
#		last;
#	}
#}
my $median = $max_x;

my ($Lsd, $Rsd, $Lc, $Rc);
for (my $i=0; $i<@insert; $i++) {
	my $diff = $insert[$i] - $median;
	if ($diff < 0) {
		$Lsd += $count[$i] * $diff * $diff;
		$Lc += $count[$i];
	}
	elsif ($diff > 0) {
		$Rsd += $count[$i] * $diff * $diff;
		$Rc += $count[$i];
	}
}
my ($oLsd,$oRsd) = ($Lsd,$Rsd);
$Lsd = sprintf "%d", sqrt($Lsd/$Lc);
$Rsd = sprintf "%d", sqrt($Rsd/$Rc);
if($nodraw){
    my $libname = ($input[0] =~ /L\d+_([^_]+)_[12]/) ? $1 : 'NA';
    print join("\t",$libname,$median,$oLsd,$Lc,$oRsd,$Rc,$Lsd,$Rsd),"\n";
    exit;
}

$total_uniq_pair = $total_uniq_low_pair + $total_uniq_normal_pair;
$total_single = $total_map_reads - $total_repeat_pair * 2 - $total_uniq_pair * 2;

open OUT, ">$out";
print OUT "#          Mapped reads: $total_map_reads\n";
print OUT "#          Single reads: $total_single\n";
print OUT "#           Repeat pair: $total_repeat_pair\n";
print OUT "#             Uniq pair: $total_uniq_pair\n";
print OUT "#    low frequency pair: $total_uniq_low_pair\n";
print OUT "# normal frequency pair: $total_uniq_normal_pair\n";
print OUT "#                  Peak: $median\n";
print OUT "#                    SD: -$Lsd/+$Rsd\n";

for (my $i=0; $i<@insert; $i++) {
        if($insert[$i]>-10000&&$insert[$i]<2000)
        {
	   print OUT "$insert[$i]\t$count[$i]\n";
        }
}
close OUT;

my $gnuplot = find_gnuplot ();
my $set_plot = set_plot ($gnuplot);

my $plot = "$gnuplot <<END\n";
$plot .= $set_plot;
$plot .= "set output '$out.ps'\n";
$plot .= "plot '$out' u 1:2 w l\n";
$plot .= "END\n";
system "$plot";
system "convert ps:$out.ps $out.pdf";
unlink "$out.ps";

sub set_plot {
	my $gnuplot = shift;
	my $version = `$gnuplot -V`;
	$version or die "Error: cannot execute $gnuplot";
	my $set_plot;
	if ($version =~ /gnuplot 4\.4/ || $version =~ /gnuplot 4\.0/) {
		$set_plot  = "set terminal postscript portrait color\n";
		$set_plot .= "set size 0.914, 0.58\n";
#		$set_plot .= "set size 0.914, 0.64\n";
	}
	else {
		$set_plot = "set terminal postscript portrait color size 6.4, 6.4\n";
	}
	$set_plot .= "set bmargin 10\n";
	$set_plot .= "set grid\n";
	$set_plot .= "set title 'Distribution of insert size'\n";
	$set_plot .= "set label 1 '         Mapped reads: $total_map_reads'\n";
	$set_plot .= "set label 2 '         Single reads: $total_single'\n";
	$set_plot .= "set label 3 '          Repeat pair: $total_repeat_pair'\n";
	$set_plot .= "set label 4 '            Uniq pair: $total_uniq_pair'\n";
	$set_plot .= "set label 5 '   low frequency pair: $total_uniq_low_pair'\n";
	$set_plot .= "set label 6 'normal frequency pair: $total_uniq_normal_pair'\n";
	$set_plot .= "set label 7 '                 Peak: $median'\n";
	$set_plot .= "set label 8 '                   SD: -$Lsd/+$Rsd'\n";
	$set_plot .= "set label 1 at graph 0.05, -0.20 font \"Mono,12\"\n";
	$set_plot .= "set label 2 at graph 0.05, -0.25 font \"Mono,12\"\n";
	$set_plot .= "set label 3 at graph 0.05, -0.30 font \"Mono,12\"\n";
	$set_plot .= "set label 4 at graph 0.05, -0.35 font \"Mono,12\"\n";
	$set_plot .= "set label 5 at graph 0.05, -0.40 font \"Mono,12\"\n";
	$set_plot .= "set label 6 at graph 0.05, -0.45 font \"Mono,12\"\n";
	$set_plot .= "set label 7 at graph 0.05, -0.50 font \"Mono,12\"\n";
	$set_plot .= "set label 8 at graph 0.05, -0.55 font \"Mono,12\"\n";
	$set_plot .= "set xlabel 'Insert size'\n";
	$set_plot .= "set ylabel '# Pair reads'\n";
#	$set_plot .= "set xrange [0:]\n";
	$set_plot .= "set yrange [0:]\n";
	$set_plot .= "set key off\n";
	return $set_plot;
}

sub find_gnuplot {
#	my $gnuplot = "/opt/blc/genome/bin/gnuplot";
    my $gnuplot = "/usr/bin/gnuplot";
    (-s $gnuplot) || ($gnuplot = "/opt/blc/genome/bin/gnuplot");
	$gnuplot = "gnuplot" unless (-e $gnuplot);
	return $gnuplot;
}
