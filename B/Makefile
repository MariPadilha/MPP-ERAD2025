FLAGS=-O3
AR=B
CC=gcc
ALL: $(AR)

$(AR):
	$(CC) $(FLAGS) $(AR).c -c -o $(AR).o
	$(CC) $(FLAGS) $(AR).o  -o $(AR)



clean:
	rm -rf $(AR) *.o


