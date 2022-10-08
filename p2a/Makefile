default: wish

wish.o: wish.c
	gcc -c wish.c -o wish.o

wish: wish.o
	gcc wish.o -g -o wish

clean:
	-rm -f wish.o
	-rm -f wish

gdb_mode:
	gcc -g -o test wish.c