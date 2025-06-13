# Set path to build folder
OUTDIR = build

# Set cart type (16Kb = c128cart_16, 32Kb = c128cart_32) folder names
CARTTYPE = c128cart_16

# C128 Cartridge Makefile for CC65
CC = cl65
AS = ca65
LD = ld65

# Target system
TARGET = c128

# Source files
C_SOURCES = src/main.c
ASM_SOURCES = $(wildcard $(CARTTYPE)/*.s)
CFG = $(wildcard $(CARTTYPE)/*.cfg)

# Output files
CARTRIDGE = $(OUTDIR)/$(CARTTYPE).bin

# Object files
C_OBJECTS = $(C_SOURCES:.c=.o)
ASM_OBJECTS = $(ASM_SOURCES:.s=.o)

# Compiler flags
CFLAGS = -t $(TARGET) -O
AFLAGS = -t $(TARGET)
LDFLAGS = -t $(TARGET) -C $(CFG)

# Default target
all: $(OUTDIR) $(CARTRIDGE)

# Create build directory
$(OUTDIR):
	mkdir -p $(OUTDIR)

# Build the cartridge
$(CARTRIDGE): $(C_OBJECTS) $(ASM_OBJECTS)
	$(CC) $(LDFLAGS) -o $(CARTRIDGE) $^

# Compile main.c specifically
src/main.o: src/main.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Assemble ASM sources
$(CARTTYPE)/%.o: $(CARTTYPE)/%.s
	$(AS) $(AFLAGS) -o $@ $<

# Clean build files
clean:
	rm -f src/*.o $(CARTTYPE)/*.o $(CARTRIDGE) *.map

# Windows users: uncomment the next line and set the correct path to VICE x128.exe
# VICE = "C:/WinVICE/x128.exe"

# MacOS/Linux: Run in VICE emulator
run: $(CARTRIDGE)
	x128 --cartfrom $(CARTRIDGE)

# Windows users: comment out the above 'run', and uncomment this one
# run: $(CARTRIDGE)
# 	$(VICE) --cartfrom $(CARTRIDGE)

.PHONY: all clean run
