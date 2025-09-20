# Компиляторы и флаги
ASM = fasm
CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2
LDFLAGS = -no-pie

# Цели
TARGET = queue_demo
ASM_SOURCE = queue.asm
ASM_OBJECT = queue.o
C_SOURCE = main.c

# Правила по умолчанию
all: $(TARGET)

# Сборка ассемблерного модуля
$(ASM_OBJECT): $(ASM_SOURCE)
	$(ASM) $(ASMFLAGS) $< $@

# Компиляция C программы
main.o: $(C_SOURCE)
	$(CC) $(CFLAGS) -c $< -o $@

# Линковка исполняемого файла
$(TARGET): $(ASM_OBJECT) main.o
	$(CC) -o $@ $^ $(LDFLAGS)

# Запуск программы
run: $(TARGET)
	./$(TARGET)

# Очистка
clean:
	rm -f $(TARGET) $(ASM_OBJECT) main.o

# Отладочная сборка
debug: CFLAGS += -g
debug: $(TARGET)

# Пересборка
rebuild: clean all

.PHONY: all run clean debug rebuild