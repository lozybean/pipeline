#include "filter_low_quality.h"

using namespace std;

void trim(string &seq1, string &seq2, string &qual1, string &qual2, int start_trim1, int end_trim1, int start_trim2, int end_trim2)
{
	int len1 = seq1.length();
	int len2 = seq2.length();
	if ( start_trim1 + end_trim1 >=len1 || start_trim2 + end_trim2 >=len2 )
	{
		cerr << " Trimed str longer than read length "<<endl;
	}
	int i=0, j=0, used_len1=len1-end_trim1-start_trim1, used_len2=len2-end_trim2-start_trim2;
	if (start_trim1 >0 || end_trim1 >0){
		seq1=seq1.substr(start_trim1,used_len1);
		qual1=qual1.substr(start_trim1,used_len1);
	}
	if (start_trim2 > 0 || end_trim2 > 0){
		seq2=seq2.substr(start_trim2,used_len2);
		qual2=qual2.substr(start_trim2,used_len2);
	}
}

int filter_low_qual(string &seq, string &qual,long long int &ReadCleanQ20, int N_num, float Qual_rate, int Q_shift, int Q_LOW,int PolyA,int PolyT, int Do_trim_lowq, int Do_trim_5_N, int Trim_3_Low)
{
		int N;
		N = seq.length();
		int index_end = N - 1;
		int index_start = 0;
		int N_count = 0, low_score_count = 0;
		int Max_low = Qual_rate * N;
                if(Do_trim_5_N)
                {
                        for(index_start;index_start < N; index_start++){
                                if (seq[index_start] != 'N'){
                                        break;
                                }
                        }
                }		
		seq = seq.substr(index_start,index_end-index_start+1);
		qual = qual.substr(index_start,index_end-index_start+1);
			int i,j;
			for(i = 0; i < N; i++){
				if(seq[i] == 'N'){
					N_count++;
				}
			}
			if(N_count > N_num){
				return 1;
			}

			for(i = 0; i < N; i++){
				if(qual[i]+Q_shift < Q_LOW ){
					low_score_count++;
				}	
			}
			if(low_score_count > Max_low ){
				return 1;
			}
		
		int pp = 0,pm = 0;
		if (PolyA){
			for(i=0; i < N; i++){
				pp = 0;
				for(j=i;j<PolyA;j++){
					if(seq[i]=='A'){
							pp++;
						} else{
							break;	
						}	
				}	
				if (pp>pm) pm=pp;
			}	
			if(pm >= PolyA) 
			{
				return 1;	
			}
		}
		pp = 0,pm = 0;
		if (PolyT){
			for(i=0; i < N; i++){
				pp = 0;
				for(j=i;j<PolyT;j++){
					if(seq[i]=='T'){
						pp++;
					}else{
						break;
					}
				}
				if(pm > pm) pm = pp;
			}
			if(pm >= PolyT)
			{
				return 1;
			}
		}
		if(Do_trim_lowq)
		{
			
			for(index_end; ( (seq[index_end]=='N') || (qual[index_end]+Q_shift<Q_LOW) ) && (index_end>=0); index_end--);
		}
		
		seq=seq.substr(0,index_end+1);
		qual=qual.substr(0,index_end+1);

		if(Trim_3_Low)
		{
			if(Trim_3_Low < N-index_end-1) return 1;
		}			

        for(i=0;i < qual.length();i++){
            if(qual[i] + Q_shift >= Q_LOW) ReadCleanQ20++;
        }

	return 0;
}

