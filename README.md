# Embedded Binary Self-Patch Demo

[中文版](README_CN.md)

This is an embedded development demo project showcasing a method to allow firmware to know its exact size (Bin Size) at runtime **without magic numbers** or **hardcoded addresses**.

## 🎯 Problem Solved

In a Bootloader + Payload architecture, the Payload is typically appended directly after the Bootloader's binary file (`.bin`).
**Pain Point**: How does the Bootloader know the exact memory address of the Payload at runtime?
*   **Method A**: Hardcoded addresses. Disadvantage: Code needs to be modified whenever the Bootloader size changes.
*   **Method B**: Magic Number search at the end of the file. Disadvantage: Low efficiency and risk of false positives.
*   **This Solution**: Reserve space during the linking stage, calculate the binary size after compilation, and "patch" it back into the reserved location.

## 🛠️ Principle

1.  **Linker Script ([link.ld](ld/link.ld))**: Reserves 4 bytes of space using `LONG(0)` in the data section and defines the symbol `_bin_file_size`.
2.  **Compilation ([Makefile](Makefile))**: Generates the raw `.bin` file (the reserved location is initially 0).
3.  **Patching ([patch_bin.py](tools/patch_bin.py))**:
    *   Reads the actual size of the `.bin` file.
    *   Parses the offset of `_bin_file_size` relative to the binary start from the `.elf` file.
    *   Modifies the `.bin` file directly, writing the size into the reserved location.
4.  **Runtime ([main.c](src/main.c))**: The program reads the `_bin_file_size` variable to calculate the absolute start address of the Payload.

## 🚀 Quick Start

### Dependencies
*   GNU Toolchain (Default configured for RISC-V `riscv64-unknown-elf-`, can be modified in the Makefile)
*   Python 3

### Run Demo
```bash
make run
```

### Expected Output
You will see logs similar to the following, proving the binary size was successfully written back and the program correctly calculated the Payload address:

```text
[1] Compiling and Linking...
[2] Generating Binary...
[3] Creating Dummy Payload...
[4] Patching Binary Size...
    -> Bin File Size: 45424 bytes
    -> Symbol '_bin_file_size' found at VMA: 0x8000A2C8 (Offset: 0xA2C8)
    -> Patching offset 0xA2C8 ...
       [Write] 45424 (Hex: 70b10000)
       [Read ] Verified! Data at 0xA2C8 is correct.
[5] Merging Bootloader + Payload...
    -> Generated full_image.bin
[6] Verifying with Hexdump (Dynamic Check)...
    -> Symbol located at VMA: 0x8000a2c8
    -> Calculated File Offset: 41672
    -> Content at this offset:
0000a2c8  70 b1 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |p...............|
```

## 📝 License
MIT License
