# Toolchain Configuration (Modify as needed)
CROSS_COMPILE ?= riscv64-unknown-elf-
CC      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
NM      = $(CROSS_COMPILE)nm

# Project Config
TARGET  = demo
SRC     = src/main.c
LD_SCRIPT = ld/link.ld
BASE_ADDR = 0x80000000

# Flags
CFLAGS  = -O2 -Wall -g -mcmodel=medany
LDFLAGS = -T $(LD_SCRIPT) -nostartfiles -Wl,--no-relax

all: $(TARGET).bin

$(TARGET).elf: $(SRC) $(LD_SCRIPT)
	@echo "[1] Compiling and Linking..."
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRC) -o $@

$(TARGET).bin: $(TARGET).elf
	@echo "[2] Generating Binary..."
	$(OBJCOPY) -O binary $< $@

payload.bin:
	@echo "[3] Creating Dummy Payload..."
	@echo "THIS IS PAYLOAD DATA" > payload.bin

run: $(TARGET).bin payload.bin
	@echo "[4] Patching Binary Size..."
	@python3 tools/patch_bin.py \
		--elf $(TARGET).elf \
		--bin $(TARGET).bin \
		--base $(BASE_ADDR) \
		--nm $(NM)
	
	@echo "[5] Merging Bootloader + Payload..."
	@cat $(TARGET).bin payload.bin > full_image.bin
	@echo "    -> Generated full_image.bin"

	@echo "[6] Verifying with Hexdump (Dynamic Check)..."
	@# 1. Use nm to extract the symbol address (e.g., 8000a628)
	@SYM_ADDR=$$($(NM) $(TARGET).elf | grep _bin_file_size | awk '{print $$1}'); \
	\
	# 2. Use a Python one-liner to calculate the offset: Offset = SymAddr - BaseAddr \
	OFFSET=$$(python3 -c "print(int('$$SYM_ADDR', 16) - $(BASE_ADDR))"); \
	\
	echo "    -> Symbol located at VMA: 0x$$SYM_ADDR"; \
	echo "    -> Calculated File Offset: $$OFFSET"; \
	echo "    -> Content at this offset:"; \
	\
	# 3. Call hexdump to view 16 bytes at that position \
	hexdump -C -s $$OFFSET -n 16 $(TARGET).bin


clean:
	rm -f *.elf *.bin *.map full_image.bin

.PHONY: all clean run
