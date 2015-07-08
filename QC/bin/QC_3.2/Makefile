objects = filter_low_quality.o filter_small_size.o QC.o

edit :	$(objects)
	g++ `pkg-config --cflags --libs glib-2.14`  -lz -o QC $(objects) -lstdc++

filter_low_quality.o : filter_low_quality.cpp filter_low_quality.h
	g++ -c filter_low_quality.cpp
filter_small_size.o : filter_small_size.cpp filter_small_size.h	
	g++ -c filter_small_size.cpp
QC.o :	QC.cpp
	g++ -c QC.cpp
clean:
	rm *.o 
