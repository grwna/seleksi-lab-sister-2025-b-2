# Makefile untuk server assembly

# Assembler dan Linker
NASM = nasm
LD = ld

# Opsi kompilasi
# -f elf64: format output untuk Linux 64-bit
# -g: menyertakan informasi debug (opsional)
NASMFLAGS = -f elf64 -g

# Direktori sumber dan biner
SRC = src
BIN = bin

# Nama file objek
OBJS = $(addprefix $(BIN)/, server.o utils.o)

# Nama target executable
TARGET = $(BIN)/http_server

# Mendeklarasikan target 'all' dan 'clean' sebagai phony
.PHONY: all clean run

# Aturan default: build semuanya
all: $(TARGET)

run: $(TARGET)
	./$(TARGET)
# Aturan untuk linking
$(TARGET): $(OBJS)
	$(LD) -o $@ $^

# Aturan untuk assembling
# Menggunakan pattern rule untuk menyederhanakan
$(BIN)/%.o: $(SRC)/%.asm
	@mkdir -p $(BIN)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Aturan untuk membersihkan file hasil kompilasi
clean:
	rm -rf $(BIN)
