#include "filter_small_size.h"
using namespace std;

void usage();
void trim_space(string &id);//返回ID：第一个空格到第二个空格之间的部分
int find_overlap(string seq1,string seq2,float mismatch_rate,int min_match_length,int &match_length,int &mismatch);
void reverse(string &seq); //配对，atcg-tagc
int filter_small_size( string &seq1, string &seq2) {
		float mismatch_rate = 0.1;        //误匹配比率，Q10
		int min_match_length = 10;        //最小匹配长度标准
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

void trim_space(string &id){    //返回ID：第一个空格到第二个空格之间的部分,m/\s.*\s/  $&;
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
//返回是否找到overlap，附带返回最大匹配长度和误匹配量
{
	int length1=seq1.length();
	int length2=seq2.length();
	int max_match_length=(length1>length2)?length2:length1;//最大可匹配长度为seq1，seq2的最小长度
	for(int i=max_match_length;i>=min_match_length;i--){//当前将匹配长度
		int max_mismatch=int(mismatch_rate * i);    //最大误匹配数量为最大误匹配率与匹配长度之积
		mismatch=0;                                 //当前误匹配计数
		for(int j=0;j<=i-1;j++){
			char c=seq1[length1-i+j];          //计算最大overlap长度	
			if (c!='A' &&c!='T'&&c!='C'&&c!='G' ||seq2[j]=='N')   //除了A、T、C、G、N 之外，是否有其他?
			{
				mismatch++;
			}else if(seq1[length1-i+j] !=seq2[j] )  
				//注意这里的length1和上面c的length1，而非max_match_length，表明length1和length2并非对称关系
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
