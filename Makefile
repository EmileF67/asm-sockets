all :
	mkdir -p bin
	
	
all: client server

client: client/client.asm
	mkdir -p bin
	nasm -f elf64 client/client.asm -o bin/client.o
	ld bin/client.o -o bin/client

server: server/server.asm
	mkdir -p bin
	nasm -f elf64 server/server.asm -o bin/server.o
	ld bin/server.o -o bin/server

clean:
	rm -rf bin

.PHONY: all clean