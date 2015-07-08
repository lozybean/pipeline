#include "filter_low_quality.h"
#include "filter_small_size.h"
#include <cstdio>
#include <cstdlib>
#include <string>
#include <zlib.h>
#include <iomanip>
using namespace std;

int Start_trim1 = 0;
int End_trim1 = 0;
int Start_trim2 = 0;
int End_trim2 = 0;

int N_num = 3;
float Qual_rate = 0.4;
int Qual_num = 40;
int Trim_3_Low = 0;
int Q_SHIFT = -64;
int Q_LOW = 20;
int PolyA = 0;

int Do_small_size = 0;
int Do_trim_lowq = 1;
int Do_trim_5_N = 0;
int insert_size=500;

int buffSize = 800000;
string* read1Buffer = NULL;
string* read2Buffer = NULL;

int IF_GZ = 0;
int IF_GZ_OUT = 1;

int Small_num = 0;
int filter_num = 0;
int read1_length = 0, read2_length = 0;
long long int count_raw_n = 0, count_raw_r = 0, count_clean_np = 0, count_clean_ns = 0, count_clean_rp = 0, count_clean_rs = 0;
long long int Read1_GC = 0, Read2_GC = 0, Read1_HignQual = 0, Read2_HignQual = 0;
long long int clean1_Q20 = 0, clean2_Q20 = 0;
void usage ()
{
	cout << "\nversion_3.0" 
			<<"\nUsage: filter_data [options] <read_1.fq> <read_2.fq> <outputprefix>\n"
			<< "  -a <int>  trimed length at 5' end  of read1, default " << Start_trim1 << "\n"
			<< "  -b <int>  trimed length at 3' end of read1, default " << End_trim1 << "\n"
			<< "  -c <int>  trimed length at 5' end of read2, default " << Start_trim2 << "\n"
			<< "  -d <int>  trimed length at 3' end of read2, default " <<End_trim2 << "\n"
			<< "  -q <int>  filter reads with low quality bases percent,set a cutoff, default " << Qual_num << "%\n"
			<< "  -e <int>  filter reads with low quality in the end,set a cutoff if necessary or will trim all the low bases in the end" << endl
			<< "  -N <int>  filter reads with N,set a cutoff, default " << N_num << "\n"
			<< "  -Q <int>  filter reads with the lowest quality " << Q_LOW << endl
			<< "  -A <int>  filter reads whit polyA, set a cutoff >=10" << endl
			<< "  -B <int>  set a buffSize , defualt " << buffSize <<endl
			<< "  -g        use .gz reads file, default no"	<< endl
			<< "  -o        do not use .gz output file, default yes" <<endl
			<< "  -x        do not trim 3' low quality, defualt do"	<< endl
			<< "  -w        do trim 5' N, defualt no" <<endl
			<< "  -y        use Q33 reads style, default 64 reads style" << endl
			<< "  -h        output help information\n" << endl;
	exit(1);
}

int main(int argc, char *argv[])
{
	if (argc<3)
	{
		usage();
	}
	int c;
	while ((c=getopt(argc,argv,"a:b:c:d:q:e:N:Q:A:B:goxwyh")) != -1)
	{
		switch (c)
		{
			case 'a' : Start_trim1 = atoi(optarg); break;
			case 'b' : End_trim1 = atoi(optarg); break;
			case 'c' : Start_trim2 = atoi(optarg); break;
			case 'd' : End_trim2 = atoi(optarg); break;
			case 'q' : Qual_num = atoi(optarg);break;
			case 'e' : Trim_3_Low = atoi(optarg);break;
			case 'N' : N_num = atoi(optarg); break;
			case 'Q' : Q_LOW = atoi(optarg);break;
			case 'A' : PolyA = atoi(optarg);break;
			case 'B' : buffSize = atoi(optarg);break;
			case 'g' : IF_GZ = 1;break;
			case 'o' : IF_GZ_OUT = 0;break;
			case 'x' : Do_trim_lowq = 0;break;
			case 'w' : Do_trim_5_N = 1;break;
			case 'y' : Q_SHIFT = -33; break;
			case 'h' : usage(); break;
			default  : cout<<"error:"<<(char)c<<endl;usage();
		
		}
	}
	Qual_rate=float(Qual_num)/100;
	if(PolyA>0 && PolyA<10) PolyA = 10;
	
	string seq1_file = argv[optind++]; 
	string seq2_file = argv[optind++];
	string out_pre = argv[optind++];
	string sta_file2 = out_pre + ".stat";

	string textLine;
	string id1="", id2="";
	string seq11 = "", seq22 = "", qual11 = "", qual22 = "";
	long Raw_reads = 0;
	long Raw_bases = 0;
	int Read_len1 = 0;
	int Read_len2 = 0;
	int Usable_len1 = 0;
	int Usable_len2 = 0;
	
		ofstream stafile2 ( sta_file2.c_str() );
		if ( ! stafile2 )
		{
			cerr << "fail to create stat2 file" << sta_file2 << endl;
			exit(1);
		}
		
		gzFile gzclean1,gzclean2,gzcleans;
		ofstream clean1,clean2,cleans;
	if(IF_GZ_OUT)
	{
		string seq1_clean = out_pre + ".clean.1.fq.gz";
		string seq2_clean = out_pre + ".clean.2.fq.gz";
		string single_clean = out_pre + ".clean.s.fq.gz";
		gzclean1 = gzopen (seq1_clean.c_str(), "w");
		if ( ! gzclean1 )
		{
			cerr << "fail to create read1 clean file" << seq1_clean << endl;
			exit(1);
		}
		gzclean2 = gzopen (seq2_clean.c_str(), "w");
		if ( ! gzclean2 )
		{
			cerr << "fail to create stat2 file" << seq2_clean << endl;
			exit(1);
		}
		gzcleans = gzopen (single_clean.c_str(), "w");
		if ( ! gzcleans)
		{
			cerr << "fail to create single clean file" << single_clean <<endl;		
			exit(1);
		}		
	}else{
                string seq1_clean = out_pre + ".clean.1.fq";
                string seq2_clean = out_pre + ".clean.2.fq";
                string single_clean = out_pre + ".clean.s.fq";	
		clean1.open ( seq1_clean.c_str() );
		if ( ! clean1 )
		{
			cerr << "fail to create read1 clean file" << seq1_clean <<endl;
		}
	
		clean2.open ( seq2_clean.c_str() );
		if ( ! clean2 )
		{
			cerr << "fail to create read2 clean file" << seq2_clean <<endl;
		}
	
		cleans.open ( single_clean.c_str() );
		if ( ! cleans)
		{
		cerr << "fail to create single clean file" << single_clean <<endl;		
		}
	}
	
	if(!IF_GZ)
	{
		ifstream infile1;
		ifstream infile2;
		seq11 = "";seq22 = "";
		infile1.open( seq1_file.c_str() );
		if ( ! infile1 )
		{	cerr << "fail to open input file" << seq1_file << endl;
		}

		infile2.open( seq2_file.c_str() );
		if ( ! infile2 )
		{	cerr << "fail to open input file" << seq2_file << endl;
		}

		while ( getline( infile1, textLine, '\n' ) )
		{	
				if ( textLine[0] == '@' )
				{
					id1 = textLine;
					getline( infile1, seq11, '\n' );
					getline( infile1, textLine, '\n' );
					getline( infile1, qual11, '\n' );
					
					Read_len1 = seq11.length();
					Usable_len1 = Read_len1 - Start_trim1 - End_trim1;

                                        for(int i=0;i<Read_len1;i++)
                                        {
                                                switch ( seq11[i] )
                                                {
                                                        case 'G': case 'C':
                                                                Read1_GC++;
                                                                break;
                                                }
                                                if ( qual11[i] + Q_SHIFT >= Q_LOW)
                                                {
                                                        Read1_HignQual++;
                                                }
                                        }

					getline( infile2, id2, '\n' );
					getline( infile2, seq22, '\n' );
					getline( infile2, textLine, '\n' );
					getline( infile2, qual22, '\n' );
					
					Read_len2 = seq22.length();
					Usable_len2 = Read_len2 - Start_trim2 - End_trim2;

                                        for(int i=0;i<Read_len2;i++)
                                        {
                                                switch ( seq22[i] )
                                                {
                                                        case 'G': case 'C':
                                                                Read2_GC++;
                                                                break;
                                                }
                                                if ( qual22[i] + Q_SHIFT >= Q_LOW)
                                                {
                                                        Read2_HignQual++;
                                                }
                                        }	

					Raw_reads++;
					Raw_bases += Read_len1;
					Raw_bases += Read_len2;
				} else {
					cerr << "format error" << endl;
				}
	
				if ( Start_trim1 > 0 || End_trim1 >0 || Start_trim2 >0 ||End_trim2>0){
					trim(seq11, seq22, qual11, qual22, Start_trim1, End_trim1, Start_trim2, End_trim2);
				}
				int p1,p2;
				
				p1 = filter_low_qual(seq11,qual11,clean1_Q20,N_num,Qual_rate,Q_SHIFT,Q_LOW,PolyA,Do_trim_lowq,Do_trim_5_N,Trim_3_Low);
				p2 = filter_low_qual(seq22,qual22,clean2_Q20,N_num,Qual_rate,Q_SHIFT,Q_LOW,PolyA,Do_trim_lowq,Do_trim_5_N,Trim_3_Low);
				
				int flag=3;
				
				if( (p1==0) && (p2==0) ){
					count_clean_rp++;
					count_clean_np += (seq11.length() + seq22.length());
					flag = 0;		
				}else if(p1==0){
					count_clean_rs++;
					count_clean_ns += seq11.length();
					flag = 1;
				}else if(p2==0){
					count_clean_rs++;
					count_clean_ns += seq22.length();
					flag = 2;
				}

				if(flag!=3){
					int nnn;
					nnn=id1.find(" ",25);
					if(nnn!=string::npos)id1=id1.substr(0,nnn);
					nnn=id2.find(" ",25);
					if(nnn!=string::npos)id2=id2.substr(0,nnn);
					nnn=id1.find("/1");
					if(nnn!=string::npos)id1=id1.substr(0,nnn);
					nnn=id2.find("/2");
					if(nnn!=string::npos)id2=id2.substr(0,nnn);				
				}

				if ( Do_small_size && filter_small_size(seq11,seq22) )
				{
					Small_num++;
				}else if(IF_GZ_OUT){
							if(flag==0){
							gzprintf(gzclean1,"%s/1\n%s\n+\n%s\n",id1.c_str(),seq11.c_str(),qual11.c_str());
							gzprintf(gzclean2,"%s/2\n%s\n+\n%s\n",id2.c_str(),seq22.c_str(),qual22.c_str());
							}else if(flag==1){
							gzprintf(gzcleans,"%s/1\n%s\n+\n%s\n",id1.c_str(),seq11.c_str(),qual11.c_str());
							}else if(flag==2){
							gzprintf(gzcleans,"%s/2\n%s\n+\n%s\n",id2.c_str(),seq22.c_str(),qual22.c_str());
							}
						}else{
							if(flag==0){
							clean1 << id1 << "/1" << endl << seq11 << endl << "+" << endl << qual11 << endl;
							clean2 << id2 << "/2" << endl << seq22 << endl << "+" << endl << qual22 << endl;
							}else if(flag==1){
							cleans << id1 << "/1" << endl << seq11 << endl << "+" << endl << qual11 << endl;
							}else if(flag==2){
							cleans << id2 << "/2" << endl << seq22 << endl << "+" << endl << qual22 << endl;	
							}
						}	
		}
		infile1.close();
		infile2.close();
	}
	else if(IF_GZ)
	{
		gzFile zip1,zip2;
		seq11 = "";seq22 = "";
		zip1=gzopen (seq1_file.c_str(), "r");
		if ( ! zip1 )
		{	cerr << "fail to open input file" << seq1_file << endl;
		}
		zip2=gzopen (seq2_file.c_str(), "r");	
		if ( ! zip2 )
		{	cerr << "fail to open input file" << seq1_file << endl;
		}

			int line_num=0;
			char c1,c2;
			while((c1=gzgetc(zip1)) != EOF &&(c2=gzgetc(zip2)) != EOF && line_num<2)
			{
				//              cout<<char(c)<<endl;
				if(char(c1) == '\n')
				{
					line_num++;
					if (line_num==2)
					{
						Read_len1 = seq11.length();
						Usable_len1 = Read_len1 - Start_trim1 - End_trim1;
					}
					seq11="";
					}
					else
					{
						seq11+=char(c1);
					}
					if(char(c2) == '\n')
					{
						if (line_num==2)
					{
						Read_len2 = seq22.length();
						Usable_len2 = Read_len2 - Start_trim2 - End_trim2;
					}
					seq22="";
				}
				else
				{
					seq22+=char(c2);
				}
			}	
		read1Buffer = new string[buffSize];
		read2Buffer = new string[buffSize];
		for (int k=0; k<buffSize; k++)
		{
			read1Buffer[k]="";
			read2Buffer[k]="";
		}
		cout<<"start to read fq.gz file"<<endl;
		zip1=gzopen (seq1_file.c_str(), "r");
		zip2=gzopen (seq2_file.c_str(), "r");
		char *buf = NULL;
		int len=500;			
		int flag_eof = 0;	
		int kk = 0;	
		do{
			
				char *read = NULL;
				read = new char[500];	
				seq11="";seq22="";
				line_num=0;
				string str;
				while(line_num<buffSize )
				{
					buf=gzgets(zip1,read,len);
                                        if(gzeof(zip1)){
                                                flag_eof = 1;
                                                break;
                                        }
					str=buf;					
					read1Buffer[line_num]=str;
					line_num++;
				}
				line_num=0;
				while (line_num<buffSize )
				{
					buf=gzgets(zip2,read,len);
                                        if(gzeof(zip2)){
                                                flag_eof = 1;
                                                break;
                                        }
					str=buf;
					read2Buffer[line_num]=str;
					line_num++;
				}
				delete read;
				
				id1="";id2="";seq11="";seq22="";textLine="";qual11="";qual22="";
				for (int k=0;k<line_num-3 ;k++ )
				{
						id1=read1Buffer[k];
						id2=read2Buffer[k];k++;
						seq11=read1Buffer[k];
						seq22=read2Buffer[k];k++;
						textLine=read1Buffer[k];
						textLine=read2Buffer[k];k++;
						qual11=read1Buffer[k];
						qual22=read2Buffer[k];
						Raw_reads++;
						Raw_bases += Read_len1;
						Raw_bases += Read_len2;
						
                                        for(int i=0;i<Read_len1-1;i++)
                                        {
                                                switch ( seq11[i] )
                                                {
                                                        case 'G': case 'C':
                                                                Read1_GC++;
                                                                break;
                                                }
                                                if ( qual11[i] + Q_SHIFT >= Q_LOW)
                                                {
                                                        Read1_HignQual++;
                                                }
                                        }
                                        for(int i=0;i<Read_len2-1;i++)
                                        {
                                                switch ( seq22[i] )
                                                {
                                                        case 'G': case 'C':
                                                                Read2_GC++;
                                                                break;
                                                }
                                                if ( qual22[i] + Q_SHIFT >= Q_LOW)
                                                {
                                                        Read2_HignQual++;
                                                }
                                        }


						id1 = id1.substr(0,id1.length()-1);
						id2 = id2.substr(0,id2.length()-1);
						seq11 = seq11.substr(0,Read_len1);
						seq22 = seq22.substr(0,Read_len2);
						qual11 = qual11.substr(0,Read_len1);
						qual22 = qual22.substr(0,Read_len2);
						if ( Start_trim1 > 0 || End_trim1 >0 || Start_trim2 >0 ||End_trim2>0){
							trim(seq11, seq22, qual11, qual22, Start_trim1, End_trim1, Start_trim2, End_trim2);
						}
						int p1,p2;

						p1 = filter_low_qual(seq11,qual11,clean1_Q20,N_num,Qual_rate,Q_SHIFT,Q_LOW,PolyA,Do_trim_lowq,Do_trim_5_N,Trim_3_Low);
						p2 = filter_low_qual(seq22,qual22,clean2_Q20,N_num,Qual_rate,Q_SHIFT,Q_LOW,PolyA,Do_trim_lowq,Do_trim_5_N,Trim_3_Low);
						
						int flag=3;
						
						if( (p1==0) && (p2==0) ){
							count_clean_rp++;
							count_clean_np += (seq11.length() + seq22.length());
							flag = 0;		
						}else if(p1==0){
							count_clean_rs++;
							count_clean_ns += seq11.length();
							flag = 1;
						}else if(p2==0){
							count_clean_rs++;
							count_clean_ns += seq22.length();
							flag = 2;
						}else {filter_num++;}
		
						if(flag!=3){
							int nnn;
							nnn=id1.find(" ",25);
							if(nnn!=string::npos)id1=id1.substr(0,nnn);
							nnn=id2.find(" ",25);
							if(nnn!=string::npos)id2=id2.substr(0,nnn);
							nnn=id1.find("/1");
							if(nnn!=string::npos)id1=id1.substr(0,nnn);
							nnn=id2.find("/2");
							if(nnn!=string::npos)id2=id2.substr(0,nnn);				
						}
		
						if ( Do_small_size && filter_small_size(seq11,seq22) )
						{
							Small_num++;
						}else if(IF_GZ_OUT){
									if(flag==0){
									gzprintf(gzclean1,"%s/1\n%s\n+\n%s\n",id1.c_str(),seq11.c_str(),qual11.c_str());
									gzprintf(gzclean2,"%s/2\n%s\n+\n%s\n",id2.c_str(),seq22.c_str(),qual22.c_str());
									}else if(flag==1){
									gzprintf(gzcleans,"%s/1\n%s\n+\n%s\n",id1.c_str(),seq11.c_str(),qual11.c_str());
									}else if(flag==2){
									gzprintf(gzcleans,"%s/2\n%s\n+\n%s\n",id2.c_str(),seq22.c_str(),qual22.c_str());
									}
								}else{
									if(flag==0){
									clean1 << id1 << "/1" << endl << seq11 << endl << "+" << endl << qual11 << endl;
									clean2 << id2 << "/2" << endl << seq22 << endl << "+" << endl << qual22 << endl;
									}else if(flag==1){
									cleans << id1 << "/1" << endl << seq11 << endl << "+" << endl << qual11 << endl;
									}else if(flag==2){
									cleans << id2 << "/2" << endl << seq22 << endl << "+" << endl << qual22 << endl;	
									}
						}	
				}
		}while( line_num==buffSize && !flag_eof);
		gzclose(zip1);
		gzclose(zip2);
		delete[] read1Buffer;
		delete[] read2Buffer; 
	}


	if(IF_GZ_OUT){
		gzclose(gzclean1);
		gzclose(gzclean2);
		gzclose(gzcleans);	
	}else{
		clean1.close();
		clean2.close();
		cleans.close();
	}	
		
	stafile2.precision(3);
	

	float reads_ratio = 0.0,bases_ratio = 0.0,Q20 = 0.0,Q20_clean = 0.0;
	Q20 = (float)( (Read1_HignQual+Read2_HignQual) * 100.0 / Raw_bases );
	Q20_clean = (float)( (clean1_Q20 + clean2_Q20) * 100.0 / (count_clean_np + count_clean_ns)  );

	stafile2	<<"Raw_reads\t"<<Raw_reads<<endl
				<<"Raw_bases\t"<<Raw_bases<<endl
				<<"Q"<<Q_LOW<<"_ratio"<<Q20<<"%"<<endl
				<<"Clean_reads(PE)\t"<<count_clean_rp<<endl
				<<"Clean_bases(PE)\t"<<count_clean_np<<endl
				<<"Clean_reads(SE)\t"<<count_clean_rs<<endl
				<<"Clean_reads(SE)\t"<<count_clean_ns<<endl
				<<"Clean_bases(ALL)\t"<<count_clean_np+count_clean_ns<<endl
				<<"Clean_Q"<<Q_LOW<<"_ratio"<<Q20_clean<<"%"<<endl;
	
	stafile2.close();
}



