#include "filter_small_size.h"
using namespace std;

void usage();
void trim_space(string &id);//����ID����һ���ո񵽵ڶ����ո�֮��Ĳ���
int find_overlap(string seq1,string seq2,float mismatch_rate,int min_match_length,int &match_length,int &mismatch);
void reverse(string &seq); //��ԣ�atcg-tagc
int filter_small_size( string &seq1, string &seq2) {
		float mismatch_rate = 0.1;        //��ƥ����ʣ�Q10
		int min_match_length = 10;        //��Сƥ�䳤�ȱ�׼
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

void trim_space(string &id){    //����ID����һ���ո񵽵ڶ����ո�֮��Ĳ���,m/\s.*\s/  $&;
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
//�����Ƿ��ҵ�overlap�������������ƥ�䳤�Ⱥ���ƥ����
{
	int length1=seq1.length();
	int length2=seq2.length();
	int max_match_length=(length1>length2)?length2:length1;//����ƥ�䳤��Ϊseq1��seq2����С����
	for(int i=max_match_length;i>=min_match_length;i--){//��ǰ��ƥ�䳤��
		int max_mismatch=int(mismatch_rate * i);    //�����ƥ������Ϊ�����ƥ������ƥ�䳤��֮��
		mismatch=0;                                 //��ǰ��ƥ�����
		for(int j=0;j<=i-1;j++){
			char c=seq1[length1-i+j];          //�������overlap����	
			if (c!='A' &&c!='T'&&c!='C'&&c!='G' ||seq2[j]=='N')   //����A��T��C��G��N ֮�⣬�Ƿ�������?
			{
				mismatch++;
			}else if(seq1[length1-i+j] !=seq2[j] )  
				//ע�������length1������c��length1������max_match_length������length1��length2���ǶԳƹ�ϵ
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
