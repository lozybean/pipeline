#include <cstdio>
#include <cstdlib>
#include <string>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <getopt.h>
using namespace std;

string adpt1 = "AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT";
string adpt2 = "TTACTATGCCGCTGGTGGCTCTAGATGTGAGAAAGGGATGTGCTGCGAGAAGGCTAGA";
string adpt3 = "GATCGGAAGAGCACACGTCTGAACTCCAGTCACATCACGATCTCGTATGCCGTCTTCTGCTTG";
string adpt4 = "CTAGCCTTCTCGTGTGCAGACTTGAGGTCAGTGTAGTGCTAGAGCATACGGCAGAAGACGAAC";

int seed_len = 10, max_mis = 3, min_match = 20; 

string seq1 = "",seq2= "";



void usage ()
{
	cout << "\nUsage: filter_data [options] <read_1.fq> <read_2.fq> <adapt_1.list> <adapt_2.list> \n"
	<< "  -a <string>  adapter sequence at 5' , default " << adpt1 << "\n"
	<< "  -b <string>  adapter sequence at 5' reverse complement,  default " << adpt2 << "\n"
	<< "  -c <string>  adapter sequence at 3' , default " << adpt3 << "\n"
	<< "  -d <string>  adapter sequence at 3' reverse complement,  default " << adpt4 << "\n"
	<< "  -s <int>  the length of the seed, default " << seed_len << "\n"
	<< "  -m <int>  allow the max mis num, default " << max_mis << "\n"
	<< "  -M <int>  if match over min_match , then consider it is an adpter,  default" << min_match << "\n";
	
	exit(1);
}


int find_seed(string *seq,string *adpt);

struct alignment {
	int total_len;
	int total_mis;
	int total_gap;
	int read_start;
	int read_end;
	int adpt_start;
	int adpt_end;
	float mis_rate;
};
alignment get_alignment (string *read, int read_pos, string *adpt, int adapt_pos, int seed_len, int max_mis);
int adpt_pos = 0, seq_pos = 0;

int main(int argc, char *argv[])
{
	
	
	if (argc < 4)
	{
		usage();
	}
	
	int c;
	while ((c=getopt(argc,argv,"a:b:c:d:s:m:M:")) != -1)
	{
		switch (c)
		{
			case 'a' : adpt1 = atoi(optarg); break;
			case 'b' : adpt2 = atoi(optarg); break;
			case 'c' : adpt3 = atoi(optarg); break;
			case 'd' : adpt4 = atoi(optarg); break;
			case 's' : seed_len = atoi(optarg);break;
			case 'm' : max_mis = atoi(optarg);break;
			case 'M' : min_match = atoi(optarg); break;
			default  : cout<<"error:"<<(char)c<<endl;usage();
		
		}
	}
	string seq1_file = argv[optind++];
	string seq2_file = argv[optind++];
	string list1_file = argv[optind++];
	string list2_file = argv[optind++];
	
	ofstream listfile1 ( list1_file.c_str() );
	if ( ! listfile1 )
	{
		cerr << "fail to create list1 file" << list1_file << endl;
		exit(1);
	}
	ofstream listfile2 ( list2_file.c_str() );
	if ( ! listfile1 )
	{
		cerr << "fail to create list2 file" << list2_file << endl;
		exit(1);
	}
	
	ifstream infile1;
	infile1.open( seq1_file.c_str() );
	if ( ! infile1 )
	{      
		cerr << "fail to open input file" << seq1_file << endl;
	}
	ifstream infile2;
	infile2.open( seq2_file.c_str() );
	if ( ! infile2 )
	{    
		cerr << "fail to open input file" << seq2_file << endl;
	}
	
	
	string textLine;
	string id1,id2;	
	while ( getline( infile1, textLine, '\n' ) )
	{
		if ( textLine[0] == '@' )
		{
			id1 = textLine;
			getline ( infile1, seq1, '\n');
			getline ( infile1, textLine, '\n');
			getline ( infile1, textLine, '\n');
			
			getline( infile2, id2, '\n' );
			getline( infile2, seq2, '\n' );
			getline( infile2, textLine, '\n' );
			getline( infile2, textLine, '\n' );
			
			int adpt1_len = adpt1.length();
			int adpt2_len = adpt2.length();
			int adpt3_len = adpt3.length();
			int adpt4_len = adpt4.length();
			int seq1_len = seq1.length();
			int seq2_len = seq2.length();
			
			int flag = 0;
	
			alignment alignment;
			adpt_pos = 0, seq_pos = 0;
			
			
			if ( find_seed(&seq1, &adpt1) ) 
			{
				alignment = get_alignment(&seq1, seq_pos, &adpt1, adpt_pos, seed_len, max_mis);
				if (alignment.total_len>=min_match) {
					listfile1 << id1 <<  "\t1\t"<< seq_pos<<"\t"<<adpt_pos<<"\t"  << alignment.adpt_start << "\t" <<alignment.adpt_end << "\t" << alignment.read_start << "\t" << alignment.read_end << endl;
					flag = 1;
				}
			}
			if ( !flag && find_seed(&seq1, &adpt2) )
			{
			 	alignment = get_alignment(&seq1, seq_pos, &adpt2, adpt_pos, seed_len, max_mis);
				if (alignment.total_len>=min_match) {
					listfile1 << id1 << "\t2\t"<< seq_pos<<"\t"<<adpt_pos<<"\t"  << alignment.adpt_start << "\t" <<alignment.adpt_end << "\t" << alignment.read_start << "\t" << alignment.read_end << endl;
					flag = 1;
				}			
			}
			if ( !flag && find_seed(&seq1, &adpt3) )
			{
			 	alignment = get_alignment(&seq1, seq_pos, &adpt3, adpt_pos, seed_len, max_mis);
				if (alignment.total_len>=min_match) {
					listfile1 << id1 << "\t3\t"<< seq_pos<<"\t"<<adpt_pos<<"\t"  << alignment.adpt_start << "\t" <<alignment.adpt_end << "\t" << alignment.read_start << "\t" << alignment.read_end << endl;
					flag = 1;
				}			
			}
			if ( !flag && find_seed(&seq1, &adpt4) )
			{
			 	alignment = get_alignment(&seq1, seq_pos, &adpt4, adpt_pos, seed_len, max_mis);
				if (alignment.total_len>=min_match) {
					listfile1 << id1 << "\t4\t"<< seq_pos<<"\t"<<adpt_pos<<"\t"  << alignment.adpt_start << "\t" <<alignment.adpt_end << "\t" << alignment.read_start << "\t" << alignment.read_end << endl;
					flag = 1;
				}			
			}
			
			flag = 0;
			if ( find_seed(&seq2, &adpt1) ) 
			{
				alignment = get_alignment(&seq2, seq_pos, &adpt1, adpt_pos, seed_len, max_mis);
				if (alignment.total_len>=min_match) {
					listfile2 << id2  <<  "\t1\t"<< seq_pos<<"\t"<<adpt_pos<<"\t"  << alignment.adpt_start << "\t" <<alignment.adpt_end << "\t" << alignment.read_start << "\t" << alignment.read_end << endl;
					flag = 1;
				}
			}
			if ( !flag && find_seed(&seq2, &adpt2) )
			{
			 	alignment = get_alignment(&seq2, seq_pos, &adpt2, adpt_pos, seed_len, max_mis);
				if (alignment.total_len>=min_match) {
					listfile2 << id2 << "\t2\t"<< seq_pos<<"\t"<<adpt_pos<<"\t"  << alignment.adpt_start << "\t" <<alignment.adpt_end << "\t" << alignment.read_start << "\t" << alignment.read_end << endl;
					flag = 1;
				}			
			}
			if ( !flag && find_seed(&seq2, &adpt3) )
			{
			 	alignment = get_alignment(&seq2, seq_pos, &adpt3, adpt_pos, seed_len, max_mis);
				if (alignment.total_len>=min_match) {
					listfile2 << id2 << "\t3\t"<< seq_pos<<"\t"<<adpt_pos<<"\t"  << alignment.adpt_start << "\t" <<alignment.adpt_end << "\t" << alignment.read_start << "\t" << alignment.read_end << endl;
					flag = 1;
				}			
			}
			if ( !flag && find_seed(&seq2, &adpt4) )
			{
			 	alignment = get_alignment(&seq2, seq_pos, &adpt4, adpt_pos, seed_len, max_mis);
				if (alignment.total_len>=min_match) {
					listfile2 << id2 << "\t4\t"<< seq_pos<<"\t"<<adpt_pos<<"\t"  << alignment.adpt_start << "\t" <<alignment.adpt_end << "\t" << alignment.read_start << "\t" << alignment.read_end << endl;
					flag = 1;
				}			
			}
		} 
	}

}
int find_seed(string *seq, string *adpt)
{
	int find = 0;
	int adpt_len = adpt->length();
	int seq_len = seq->length();
	
	for (adpt_pos=0; adpt_pos<=adpt_len-seed_len; adpt_pos++) {
		for (seq_pos=0; seq_pos<=seq_len-seed_len; seq_pos++) {
			find = 1;
			for (int i=0; i<seed_len; i++) {
				if ((*adpt)[adpt_pos+i] != (*seq)[seq_pos+i]) {
				find = 0;
				break;
				}
			}
			if (find) {
				return find;
			}
		}
		if (find) {
			return find;
		}
	}
	
	return find;	
}
alignment get_alignment(string *read, int read_pos, string *adpt, int adpt_pos, int seed_len, int max_mis) 
{

        int adpt_len=(*adpt).length();
        int read_len=(*read).length();
        alignment alignment;
        alignment.total_gap=0;

        max_mis<0?0:max_mis;

        int l_mis_num=0,r_mis_num=0;                                       
        int *l_mis,*r_mis;
        l_mis = new int [max_mis+2];                                      
        r_mis = new int [max_mis+2];
        for (int i=0; i<max_mis+2; i++) {
                l_mis[i]=0;
                r_mis[i]=0;
        }
        for(int i=1;;i++) {
                if (read_pos-i<0 || adpt_pos-i <0) {
                        l_mis_num++;
                        l_mis[l_mis_num]=i;
                        break;         
                }
                if ((*read)[read_pos-i] != (*adpt)[adpt_pos-i]) {
                        l_mis_num++;
                        l_mis[l_mis_num]=i;
                }                  
                if (l_mis_num>=max_mis+1) {
                        break;
                }               

        }
        for (;l_mis_num > 1 && l_mis[l_mis_num]==l_mis[l_mis_num-1]+1;) {
                l_mis_num--;
        }  


        for(int i=1;;i++) {
                if (read_pos+seed_len+i > read_len || adpt_pos+seed_len+i > adpt_len) {
                        r_mis_num++;
                        r_mis[r_mis_num]=i;
                        break;
                }  
                if ((*read)[read_pos+seed_len-1+i] != (*adpt)[adpt_pos+seed_len-1+i]) {
                        r_mis_num++;
                        r_mis[r_mis_num]=i;
                } 

                if (r_mis_num>=max_mis+1) {
                        break;
                }
        }
        for (;r_mis_num > 1 && r_mis[r_mis_num]==r_mis[r_mis_num-1]+1;) {
                r_mis_num--;
        }

        int max_len=0,match_len=0;
        int l_mis_id,r_mis_id,l_max_id,r_max_id;

        if (l_mis_num+r_mis_num <= max_mis+2) {
                l_mis_id=l_mis_num;
                r_mis_id=r_mis_num;
                max_len = l_mis[l_mis_id]-1+r_mis[r_mis_id]-1;
                l_max_id=l_mis_id-1;
                r_max_id=r_mis_id-1;
        }else{
                for (int i=l_mis_num;i>=1;i--){ 
                        l_mis_id = i;
                        r_mis_id = max_mis+2-i;
                        match_len=l_mis[l_mis_id]-1+r_mis[r_mis_id]-1;
                        if (match_len>=max_len) {
                        max_len=match_len;
                        l_max_id=l_mis_id-1;
                        r_max_id=r_mis_id-1;
                        }
                }
        }
        alignment.total_len=max_len+seed_len;  
        alignment.total_mis = l_max_id + r_max_id;
        alignment.read_start = read_pos-(l_mis[l_max_id+1]-1);
        alignment.read_end = alignment.read_start + alignment.total_len -1;
        alignment.adpt_start = adpt_pos-(l_mis[l_max_id+1]-1);
        alignment.adpt_end = alignment.adpt_start+alignment.total_len-1;
        alignment.mis_rate =((float) alignment.total_mis) /((float) alignment.total_len);
        delete l_mis;
        delete r_mis;
        return (alignment);
}
