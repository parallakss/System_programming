all: asm c compare

asm:
	nasm -f elf64 -o sum_asm.o task4.asm
	ld -s -o sum_asm sum_asm.o

c:
	gcc -Os -s -o sum_c task5.c
	gcc -Os -s -static -o sum_c_static task5.c

compare:
	@echo "=== Размеры файлов ==="
	@echo "Ассемблер: $$(stat -c%s sum_asm) байт"
	@echo "C (динамич.): $$(stat -c%s sum_c) байт"
	@echo "C (статич.): $$(stat -c%s sum_c_static) байт"

clean:
	rm -f sum_asm sum_asm.o sum_c sum_c_static

test:
	@echo "Ассемблер: "; ./sum_asm
	@echo "C: "; ./sum_c

.PHONY: all asm c compare clean test