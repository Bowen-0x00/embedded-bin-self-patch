#!/usr/bin/env python3
import sys
import struct
import os
import subprocess
import argparse

def get_symbol_address(nm_cmd, elf_file, symbol_name):
    """
    Use the nm command to get the Virtual Memory Address (VMA) of a symbol from an ELF file.
    """
    cmd = f"{nm_cmd} {elf_file} | grep {symbol_name}"
    try:
        output = subprocess.check_output(cmd, shell=True).decode().strip()
        if not output:
            raise ValueError("Symbol not found")
        # nm output format: 80000004 T _bin_file_size
        addr_hex = output.split()[0]
        return int(addr_hex, 16)
    except Exception as e:
        print(f"[Error] Could not find symbol '{symbol_name}' in {elf_file}: {e}")
        sys.exit(1)

def patch_binary(bin_file, offset, file_size):
    """
    Modify the value at a specified offset in a binary file and read it back for verification.
    """
    with open(bin_file, 'r+b') as f:
        # 1. Write
        f.seek(offset)
        packed_size = struct.pack('<I', file_size)
        f.write(packed_size)
        
        # 2. Read back for verification (New logic)
        f.seek(offset)
        check_data = f.read(4)
        
        # 3. Print results
        print(f"    -> Patching offset 0x{offset:X} ...")
        print(f"       [Write] {file_size} (Hex: {packed_size.hex()})")
        
        if check_data == packed_size:
            print(f"       [Read ] Verified! Data at 0x{offset:X} is correct.")
        else:
            print(f"       [Error] Verification failed! Read: {check_data.hex()}")
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Patch binary size into ELF/BIN")
    parser.add_argument("--elf", required=True, help="Input ELF file")
    parser.add_argument("--bin", required=True, help="Input BIN file")
    parser.add_argument("--symbol", default="_bin_file_size", help="Symbol name to patch")
    parser.add_argument("--base", required=True, help="Base address of the binary (hex)")
    parser.add_argument("--nm", default="nm", help="Path to nm tool")

    args = parser.parse_args()

    # 1. 获取 Bin 文件大小
    if not os.path.exists(args.bin):
        print(f"[Error] Bin file {args.bin} not found")
        sys.exit(1)
    
    bin_size = os.path.getsize(args.bin)
    print(f"    -> Bin File Size: {bin_size} bytes")

    # 2. 获取符号地址
    sym_addr = get_symbol_address(args.nm, args.elf, args.symbol)
    base_addr = int(args.base, 16)

    # 3. 计算文件偏移
    offset = sym_addr - base_addr
    
    if offset < 0 or offset >= bin_size:
        print(f"[Error] Calculated offset 0x{offset:X} is out of bounds!")
        sys.exit(1)

    print(f"    -> Symbol '{args.symbol}' found at VMA: 0x{sym_addr:X} (Offset: 0x{offset:X})")

    # 4. 执行 Patch
    patch_binary(args.bin, offset, bin_size)

if __name__ == "__main__":
    main()
