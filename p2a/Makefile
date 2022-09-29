default: wish

wish.o: wish.c
	gcc -c wish.c -o wish.o

wish: wish.o
	gcc wish.o -o wish

clean:
	-rm -f wish.o
	-rm -f wish