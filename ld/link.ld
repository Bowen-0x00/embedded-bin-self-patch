ENTRY(main)

MEMORY
{
    DRAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS
{
    .text :
    {
        _payload_start = .;
        /* Only code here, ensure the first instruction is valid C startup code */
        *(.text .text.*)
        *(.rodata .rodata.*)
    } > DRAM

    .data :
    {
        . = ALIGN(4);
        /* ================================================= */
        /* Reserve 4 bytes for bin file size                 */
        /* ================================================= */
        _bin_file_size = .; 
        LONG(0);            
        /* ================================================= */

        *(.data .data.*)
    } > DRAM
    
    .bss : 
    { 
        . = ALIGN(4);
        *(.bss .bss.*) 
        *(COMMON)
    } > DRAM

    /DISCARD/ :
    {
        *(.comment)
        *(.riscv.attributes)
        *(.eh_frame)
    }
}
