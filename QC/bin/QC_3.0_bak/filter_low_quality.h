#include <iostream>
#include <fstream>
#include <string>
#include <vector>

using namespace std;
int filter_low_qual(string &seq, string &qual, long long  int &ReadCleanQ20, int N_num, float Qual_rate, int Q_shift, int Q_LOW,int PolyA,int Do_trim_lowq,int Do_trim_5_N,int Trim_3_Low);
void trim(string &seq1, string &seq2, string &qual1, string &qual2, int start_trim1, int end_trim1,int start_trim2, int end_trim2);
