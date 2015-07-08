#include "filter_small_size.h"
using namespace std;

void usage();
void trim_space(string &id);
int find_overlap(string seq1,string seq2,float mismatch_rate,int min_match_length,int &match_length,int &mismatch);
void reverse(string &seq); 
int filter_small_size( string &seq1, string &seq2) {
		float mismatch_rate = 0.1;        
		int min_match_length = 10;      
		trim_space( seq1 ); 
		trim_space( seq2 );
		string temp_str=seq2;	
		reverse(temp_str);

		int match_length = 0, mismatch = 0;

		if ( find_overlap(seq1,temp_str,mismatch_rate,min_match_length,match_length,mismatch) )
		{
			return (1);
		}else{
			return (0);
		}
}

void trim_space(string &id){
	int pos=id.find_first_not_of(' '); 
	if (pos>=0)
		id.erase(0,pos);         
	pos=id.find_first_of(' ');
	if(pos>0){
		string sub_id=id.substr(0,pos-1);
		id=sub_id;
	}	
}

int find_overlap(string seq1,string seq2,float mismatch_rate,int min_match_length,int &match_length,int &mismatch)
{
	int length1=seq1.length();
	int length2=seq2.length();
	int max_match_length=(length1>length2)?length2:length1;
	for(int i=max_match_length;i>=min_match_length;i--){
		int max_mismatch=int(mismatch_rate * i);    
		mismatch=0;                              
		for(int j=0;j<=i-1;j++){
			char c=seq1[length1-i+j];          
			if (c!='A' &&c!='T'&&c!='C'&&c!='G' ||seq2[j]=='N')   
			{
				mismatch++;
			}else if(seq1[length1-i+j] !=seq2[j] )  
			{	
				mismatch++;
			}
		}
		if (mismatch<=max_mismatch){
			match_length=i;
			return(1);
		}		
	}
	match_length=0;
	return (0);
}
void reverse(string &seq){
	int length=seq.length();
	string str;
	for(int i=length-1;i>=0;i--){
		if (seq[i]=='A'){
			str.push_back('T');
		}else if(seq[i]=='T') {
			str.push_back('A');
		}else if(seq[i]=='C') {
			str.push_back('G');
		}else if(seq[i]=='G') {
			str.push_back('C');	
		}else{
			str.push_back('N');
		}	
	}
	seq=str;
}
