all: mytar

mytar: special.c mytar.c
	gcc -std=gnu99 -Wall -Wextra -Werror -o mytar special.c mytar.c 

clean:
	rm -f mytar
