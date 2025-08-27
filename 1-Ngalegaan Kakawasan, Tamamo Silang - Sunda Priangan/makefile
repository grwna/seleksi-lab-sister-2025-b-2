NASM = nasm
LD = ld
CC=gcc

NASMFLAGS = -f elf64 -g
CFLAGS=-O2 -fno-pie -g
LDFLAGS= -no-pie -nostartfiles

# Direktori sumber dan biner
SRC = src
BIN = bin

# Nama file objek
OBJS = $(addprefix $(BIN)/, server.o utils.o mime.o http.o plugin.o plugin_helper.o)

# Nama target executable
TARGET = $(BIN)/http_server

# Mendeklarasikan target 'all' dan 'clean' sebagai phony
.PHONY: all clean run

# Aturan default: build semuanya
all: $(TARGET)

run: $(TARGET)
	./$(TARGET)

# Linking
$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# Assembling
$(BIN)/%.o: $(SRC)/asm/%.asm
	@mkdir -p $(BIN)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Compiling
$(BIN)/%.o: $(SRC)/other/%.c
	@mkdir -p $(BIN)
	$(CC) $(CFLAGS) -c -o $@ $<

# Aturan untuk membersihkan file hasil kompilasi
clean:
	rm -rf $(BIN)
