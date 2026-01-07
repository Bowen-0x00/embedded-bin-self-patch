# Embedded Binary Self-Patch Demo (中文版)

[English Version](README.md)

这是一个嵌入式开发的 Demo 项目，展示了一种**无需 Magic Number**、**无需硬编码地址**，即可让固件在运行时知道自身确切大小（Bin Size）的方法。

## 🎯 解决的问题

在 Bootloader + Payload 的架构中，我们通常将 Payload 直接追加在 Bootloader 的二进制文件（.bin）后面。
**痛点**：Bootloader 运行时如何知道 Payload 确切的内存地址？
*   **方法 A**：硬编码地址。缺点：Bootloader 大小变化时需要修改代码。
*   **方法 B**：在文件尾部加 Magic Number 搜索。缺点：效率低，且可能误判。
*   **本方案**：在链接阶段预留空间，编译后计算 Bin 大小并“回填”到预留位置。

## 🛠️ 原理

1.  **链接脚本 ([link.ld](ld/link.ld))**：在数据段使用 `LONG(0)` 预留 4 字节空间，并定义符号 `_bin_file_size`。
2.  **编译 ([Makefile](Makefile))**：生成原始的 `.bin` 文件（此时预留位置为 0）。
3.  **打补丁 ([patch_bin.py](tools/patch_bin.py))**：
    *   读取 `.bin` 实际文件大小。
    *   从 `.elf` 中解析 `_bin_file_size` 的相对于镜像起始位置的偏移量。
    *   直接修改 `.bin` 文件，将大小写入预留位置。
4.  **运行时 ([main.c](src/main.c))**：程序直接读取 `_bin_file_size` 变量，即可算出 Payload 的首地址。

## 🚀 快速开始

### 依赖
*   GNU Toolchain (默认配置为 RISC-V `riscv64-unknown-elf-`，可在 Makefile 中修改)
*   Python 3

### 运行 Demo
```bash
make run
```

### 预期输出
你将看到类似以下的日志，证明 Bin 大小被成功回写，且程序正确计算出了 Payload 地址：

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

## 📝 许可证
MIT License
