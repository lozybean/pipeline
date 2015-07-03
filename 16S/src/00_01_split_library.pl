##this version allows the primer have totally 2 sum-ups of mismatch, indel, gap; and detect whether missing-left-one barcode or adding-left-one  marches. however, the missing one
## or adding one case, no N is allowed for match.
#!/usr/bin/perl
use strict;
use warnings;
#use experimental;
die "$0 <sample_info.list> <forward_primer> <reverse_primer> <rawdata_dir> <output_dir>" unless @ARGV == 5;
-e -d "$ARGV[3]" || mkdir "$ARGV[3]";
-e -d "$ARGV[4]" || mkdir "$ARGV[4]";

#my @barcode_seq = keys %seq_primer;

open INFO, "$ARGV[0]" or die $!;
my %file_group;
my %barcode_primer_sample;
my $lengthbarcode;
my %barcode_seq;
my %lessone;
my %moreone;
while(my $line = <INFO>){
    chomp($line);
    next if($line =~ /^#/);
    my @line = split /\t/, $line;
    $line[1] =~ tr/atcg/ATCG/;
    $line[2] =~ tr/atcg/ATCG/;
    $barcode_seq{$line[1]} = 1;
    $barcode_seq{$line[2]} = 1;
    
    unless(defined $lengthbarcode){
        $lengthbarcode = length($line[1]);
    }
    
    my $lessone1 = substr($line[1], 1, ($lengthbarcode -1));
    if(exists $lessone{$lessone1}){
        unless($lessone{$lessone1} eq $line[1]){
            print "warnings: barcodes $lessone{$lessone1} and $line[1] only differ at the first nt, the less one test will alway use $lessone{$lessone1}\n";
        }
    }else{
        $lessone{$lessone1} = $line[1];
    }
    
    my $lessone2 = substr($line[2], 1, ($lengthbarcode -1));
    if(exists $lessone{$lessone2}){
        unless($lessone{$lessone2} eq $line[2]){
            print "warnings: barcodes $lessone{$lessone2} and $line[2] only differ at the first nt, the less one test will alway use $lessone{$lessone2}\n";
        }
    }else{
        $lessone{$lessone2} = $line[2];
    }
    
    foreach my $letter ("A", "T", "C", "G", "N"){
        $moreone{"${letter}$line[1]"} = $line[1];
        $moreone{"${letter}$line[2]"} = $line[2];
    }
    
    if(exists $file_group{"$line[4]\t$line[5]"}){
        unless($line[3] eq $file_group{"$line[4]\t$line[5]"}){
            die "line $. seems to have wrong group\n";
        }
    }else{
        $file_group{"$line[4]\t$line[5]"} = $line[3];
    }

    if(exists $barcode_primer_sample{"$line[1]\t$line[2]\t$line[3]"}){
        die "line $. has info , $line[1..3], which fail to decide a sample, namely appears two times\n";
    }
    $barcode_primer_sample{"$line[1]\t$line[2]\t$line[3]"} = $line[6];
}
close INFO;
my @barcode_seq = keys %barcode_seq;

my $forwardprimer = &regtransform($ARGV[1]);


my $reverseprimer = &regtransform($ARGV[2]);

open OUTLIST, ">$ARGV[4]/01_split_file.list" or die $!;
open UNFQ1, ">$ARGV[4]/unused_with_primer.1.fq" or die $!;
open UNFQ2, ">$ARGV[4]/unused_with_primer.2.fq" or die $!;
open NON1, ">$ARGV[4]/unused_no_primer.1.fq" or die $!;
open NON2, ">$ARGV[4]/unused_no_primer.2.fq" or die $!;
while( my ($files, $group) = each %file_group){
    my ($pe1, $pe2) = split "\t", $files;
    my %filehandles;
    
    open PE1, "$ARGV[3]/$pe1" or die $!;
    open PE2, "$ARGV[3]/$pe2" or die $!;
    
    while(my $line1_1 = <PE1>){
        my $line2_1 = <PE2>;
        
        my $line1_2 = <PE1>;
        my $line2_2 = <PE2>;
        
        my $line1_3 = <PE1>;
        my $line2_3 = <PE2>;
            
        my $line1_4 = <PE1>;
        my $line2_4 = <PE2>;
        
        my $forward = 1;
        
        my $potential_primer1 = substr($line1_2, $lengthbarcode, 30);
        my $potential_primer2 = substr($line2_2, $lengthbarcode, 30);
        
        if($potential_primer1 =~ /$forwardprimer/ or $potential_primer2 =~ /$reverseprimer/ or &insert_gap_mismatch($potential_primer1, $forwardprimer, 2) or &insert_gap_mismatch($potential_primer2, $reverseprimer, 2)){
            
        }elsif($potential_primer1 =~ /$reverseprimer/ or $potential_primer2 =~ /$forwardprimer/  or &insert_gap_mismatch($potential_primer1, $reverseprimer, 2) or &insert_gap_mismatch($potential_primer2, $forwardprimer, 2)){
            $forward = 0;
        }else{
            print NON1 "${line1_1}${line1_2}${line1_3}${line1_4}";
            print NON2 "${line2_1}${line2_2}${line2_3}${line2_4}";
            #print "primer:\n$line1_1\n";
            next;
        }
        
        if($forward == 0){
            my ($line_1, $line_2, $line_3, $line_4) = ($line1_1, $line1_2, $line1_3, $line1_4);
            ($line1_1, $line1_2, $line1_3, $line1_4) = ($line2_1, $line2_2, $line2_3, $line2_4);
            ($line2_1, $line2_2, $line2_3, $line2_4) = ($line_1, $line_2, $line_3, $line_4);
        }
        
        my ($potential_barcode1, $potential_barcode2);
        $potential_barcode1 = substr($line1_2, 0, $lengthbarcode);
        $potential_barcode2 = substr($line2_2, 0, $lengthbarcode);
        
        $potential_barcode1 =~ s/N/\[ATCG\]/;
        $potential_barcode2 =~ s/N/\[ATCG\]/;

        if(@barcode_seq ~~ /($potential_barcode1)/){
            $potential_barcode1 = $1;  
        }else{
            my $original_barcode1 = substr($line1_2, 0, ($lengthbarcode + 1));
            if(exists $moreone{$original_barcode1}){
                $potential_barcode1 = $moreone{$original_barcode1};
            }else{
                $original_barcode1 = substr($line1_2, 0, ($lengthbarcode - 1));
                if(exists $lessone{$original_barcode1}){
                    $potential_barcode1 = $lessone{$original_barcode1};
                }else{
                    print UNFQ1 "${line1_1}${line1_2}${line1_3}${line1_4}";
                    print UNFQ2 "${line2_1}${line2_2}${line2_3}${line2_4}";
                    next;
                }
            }
        }
        
        if(@barcode_seq ~~ /($potential_barcode2)/){
            $potential_barcode2 = $1;
        }else{
            my $original_barcode2 = substr($line2_2, 0, ($lengthbarcode + 1));
            if(exists $moreone{$original_barcode2}){
                $potential_barcode2 = $moreone{$original_barcode2};
            }else{
                $original_barcode2 = substr($line2_2, 0, ($lengthbarcode - 1));
                if(exists $lessone{$original_barcode2}){
                    $potential_barcode2 = $lessone{$original_barcode2};
                }else{
                    print UNFQ1 "${line1_1}${line1_2}${line1_3}${line1_4}";
                    print UNFQ2 "${line2_1}${line2_2}${line2_3}${line2_4}";
                    next;
                }
            }
        }

        if(exists $barcode_primer_sample{"${potential_barcode1}\t${potential_barcode2}\t$group"}){
            unless(exists $filehandles{$barcode_primer_sample{"${potential_barcode1}\t${potential_barcode2}\t$group"}."1"}){
                open $filehandles{$barcode_primer_sample{"${potential_barcode1}\t${potential_barcode2}\t$group"}."1"}, ">$ARGV[4]/".$barcode_primer_sample{${potential_barcode1}."\t".${potential_barcode2}."\t".$group}.".1.fq" or die $!;
                open $filehandles{$barcode_primer_sample{"${potential_barcode1}\t${potential_barcode2}\t$group"}."2"}, ">$ARGV[4]/".$barcode_primer_sample{${potential_barcode1}."\t".${potential_barcode2}."\t".$group}.".2.fq" or die $!;
                print OUTLIST "$ARGV[4]/".$barcode_primer_sample{${potential_barcode1}."\t".${potential_barcode2}."\t".$group}.".1.fq\n";
                print OUTLIST "$ARGV[4]/".$barcode_primer_sample{${potential_barcode1}."\t".${potential_barcode2}."\t".$group}.".2.fq\n";
            }
            
            $filehandles{$barcode_primer_sample{"${potential_barcode1}\t${potential_barcode2}\t$group"}."1"}->print("${line1_1}${line1_2}${line1_3}${line1_4}");
            $filehandles{$barcode_primer_sample{"${potential_barcode1}\t${potential_barcode2}\t$group"}."2"}->print("${line2_1}${line2_2}${line2_3}${line2_4}");
        }else{
            print UNFQ1 "${line1_1}${line1_2}${line1_3}${line1_4}";
            print UNFQ2 "${line2_1}${line2_2}${line2_3}${line2_4}";
        }
    }
    close PE1;
    close PE2;
}
close UNFQ1;
close UNFQ2;
close OUTLIST;

sub regtransform{
    my $primer = $_[0];
    $primer =~ s/A/\[A\]/g;
    $primer =~ s/T/\[T\]/g;
    $primer =~ s/G/\[G\]/g;
    $primer =~ s/C/\[C\]/g;
    
    $primer=~ s/V/\[ACG\]/g;
    $primer=~ s/D/\[ATG\]/g;
    $primer=~ s/B/\[CTG\]/g;
    $primer=~ s/H/\[ATC\]/g;
    $primer=~ s/W/\[AT\]/g;
    $primer=~ s/S/\[CG\]/g;
    $primer=~ s/K/\[GT\]/g;
    $primer=~ s/M/\[AC\]/g;
    $primer=~ s/Y/\[CT\]/g;
    $primer=~ s/R/\[AG\]/g;
    
    $primer=~ s/N/\[ATCG\]/g;
    #$primer=~ s/\]/N\]/g;
    return $primer;
}

sub gap{
    my $query = $_[0];
    my $maxgapnumber = $_[2];
    $maxgapnumber--;
    
    my @maxind = ($_[1] =~ /\[[A-Z]+?\]/g);
    #print "@maxind-----------\n";
    my @subseq;

    foreach my $ind (0..($#maxind)){
        my $primer = $_[1];

        $primer =~ s/^((\[[A-Z]+\]){$ind})\[[A-Z]+\]/$1/;
        #print $primer, "---$maxgapnumber\n";
        if($query =~ /($primer)/){
            #print $1, "\n";
            return 1;
        }else{
            push @subseq, $primer;
        }
    }
    

    while($maxgapnumber-- > 0){
        my @subseqtmp;
        foreach my $primer (@subseq){
            my @maxind1 = ($primer =~ /\[[A-Z]+?\]/g);
            #print "@maxind1-----------\n";

        
            foreach my $ind (0..($#maxind1)){
                my $primertmp = $primer;
        
                $primertmp =~ s/^((\[[A-Z]+\]){$ind})\[[A-Z]+\]/$1/;
                #print $primertmp, "---$maxgapnumber\n";
                if($query =~ /($primertmp)/){
                    #print $1, "\n";
                    return 1;
                }else{
                    push @subseqtmp, $primertmp;
                }
            }
        }
        @subseq = @subseqtmp;
    }   
    
    return 0;
}


sub insert{
    my $query = $_[0];
    my $maxgapnumber = $_[2];
    $maxgapnumber--;
    
    my @maxind = ($_[1] =~ /\[[A-Z]+?\]/g);
    #print "@maxind-----------\n";
    my @subseq;

    foreach my $ind (1..($#maxind)){
        my $primer = $_[1];

        $primer =~ s/^((\[[A-Z]+\]){$ind})/$1\[ATCGN\]/;
        #print $primer, "---$maxgapnumber\n";
        if($query =~ /($primer)/){
            #print $1, "\n";
            return 1;
        }else{
            push @subseq, $primer;
        }
    }
    

    while($maxgapnumber-- > 0){
        my @subseqtmp;
        foreach my $primer (@subseq){
            my @maxind1 = ($primer =~ /\[[A-Z]+?\]/g);
            #print "@maxind1-----------\n";

        
            foreach my $ind (1..($#maxind1)){
                my $primertmp = $primer;
        
                $primertmp =~ s/^((\[[A-Z]+\]){$ind})/$1\[ATCGN\]/;
                #print $primertmp, "---$maxgapnumber\n";
                if($query =~ /($primertmp)/){
                    #print $1, "\n";
                    return 1;
                }else{
                    push @subseqtmp, $primertmp;
                }
            }
        }
        @subseq = @subseqtmp;
    }   
    
    return 0;
}

sub insert_gap{
    my $query = $_[0];
    my $maxgapnumber = $_[2];
    $maxgapnumber--;
    
    my @maxind = ($_[1] =~ /\[[A-Z]+?\]/g);
    #print "@maxind-----------\n";
    my @subseq;

    foreach my $ind (1..($#maxind)){
        my $primer = $_[1];

        $primer =~ s/^((\[[A-Z]+\]){$ind})/$1\[ATCGN\]/;
        #print $primer, "---$maxgapnumber\n";
        if($query =~ /($primer)/){
            #print $1, "\n";
            return 1;
        }else{
            push @subseq, $primer;
        }
    }
    
    foreach my $ind (0..($#maxind)){
        my $primer = $_[1];

        $primer =~ s/^((\[[A-Z]+\]){$ind})\[[A-Z]+\]/$1/;
        #print $primer, "---$maxgapnumber\n";
        if($query =~ /($primer)/){
            #print $1, "\n";
            return 1;
        }else{
            push @subseq, $primer;
        }
    }
    

    while($maxgapnumber-- > 0){
        my @subseqtmp;
        foreach my $primer (@subseq){
            my @maxind1 = ($primer =~ /\[[A-Z]+?\]/g);
            #print "@maxind1-----------\n";

        
            foreach my $ind (1..($#maxind1)){
                my $primertmp = $primer;
        
                $primertmp =~ s/^((\[[A-Z]+\]){$ind})/$1\[ATCGN\]/;
                #print $primertmp, "---$maxgapnumber\n";
                if($query =~ /($primertmp)/){
                    #print $1, "\n";
                    return 1;
                }else{
                    push @subseqtmp, $primertmp;
                }
            }
            
            foreach my $ind (0..($#maxind1)){
                my $primertmp = $primer;
        
                $primertmp =~ s/^((\[[A-Z]+\]){$ind})\[[A-Z]+\]/$1/;
                #print $primertmp, "---$maxgapnumber\n";
                if($query =~ /($primertmp)/){
                    #print $1, "\n";
                    return 1;
                }else{
                    push @subseqtmp, $primertmp;
                }
            }
        }
        @subseq = @subseqtmp;
    }   
    
    return 0;
}


sub insert_gap_mismatch{
    my $query = $_[0];
    my $maxgapnumber = $_[2];
    $maxgapnumber--;
    
    my @maxind = ($_[1] =~ /\[[A-Z]+?\]/g);
    #print "@maxind-----------\n";
    my @subseq;
    #relative to primer, insert
    foreach my $ind (1..($#maxind)){
        my $primer = $_[1];

        $primer =~ s/^((\[[A-Z]+\]){$ind})/$1\[ATCGN\]/;
        #print $primer, "---$maxgapnumber\n";
        if($query =~ /($primer)/){
            #print $1, "\n";
            return 1;
        }else{
            push @subseq, $primer;
        }
    }
    
    #gap
    foreach my $ind (0..($#maxind)){
        my $primer = $_[1];

        $primer =~ s/^((\[[A-Z]+\]){$ind})\[[A-Z]+\]/$1/;
        #print $primer, "---$maxgapnumber\n";
        if($query =~ /($primer)/){
            #print $1, "\n";
            return 1;
        }else{
            push @subseq, $primer;
        }
    }
    
    #mismatch
    foreach my $ind (0..($#maxind)){
        my $primer = $_[1];

        $primer =~ s/^((\[[A-Z]+\]){$ind})\[[A-Z]+\]/$1\[ATCGN\]/;
        #print $primer, "---$maxgapnumber\n";
        if($query =~ /($primer)/){
            #print $1, "\n";
            return 1;
        }else{
            push @subseq, $primer;
        }
    }
    

    while($maxgapnumber-- > 0){
        my @subseqtmp;
        foreach my $primer (@subseq){
            my @maxind1 = ($primer =~ /\[[A-Z]+?\]/g);
            #print "@maxind1-----------\n";

        
            foreach my $ind (1..($#maxind1)){
                my $primertmp = $primer;
        
                $primertmp =~ s/^((\[[A-Z]+\]){$ind})/$1\[ATCGN\]/;
                #print $primertmp, "---$maxgapnumber\n";
                if($query =~ /($primertmp)/){
                    #print $1, "\n";
                    return 1;
                }else{
                    push @subseqtmp, $primertmp;
                }
            }
            
            foreach my $ind (0..($#maxind1)){
                my $primertmp = $primer;
        
                $primertmp =~ s/^((\[[A-Z]+\]){$ind})\[[A-Z]+\]/$1/;
                #print $primertmp, "---$maxgapnumber\n";
                if($query =~ /($primertmp)/){
                    #print $1, "\n";
                    return 1;
                }else{
                    push @subseqtmp, $primertmp;
                }
            }
            
            foreach my $ind (0..($#maxind1)){
                my $primertmp = $primer;
        
                $primertmp =~ s/^((\[[A-Z]+\]){$ind})\[[A-Z]+\]/$1\[ATCGN\]/;
                #print $primertmp, "---$maxgapnumber\n";
                if($query =~ /($primertmp)/){
                    #print $1, "\n";
                    return 1;
                }else{
                    push @subseqtmp, $primertmp;
                }
            }
        }
        @subseq = @subseqtmp;
    }   
    
    return 0;

}

