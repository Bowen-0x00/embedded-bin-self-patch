
#include <stdio.h>
#include <stdint.h>
#include <string.h>

/* 
 * Reference symbols defined in the linker script.
 * Note: _bin_file_size is defined as a 4-byte storage space, 
 * so it is used directly as a variable.
 * _payload_start is the start address of the section, so it is used as an array.
 */
extern volatile uint32_t _bin_file_size;
extern uint8_t _payload_start[];

/* Assumed target address where the Payload is moved */
#define TARGET_ADDR ((uint8_t *)0x80200000)

void boot_next_stage(void) {
    uint32_t size = _bin_file_size;
    
    // 1. Check if it has been patched
    if (size == 0) {
        printf("[Error] Bin size is 0! Did you run the patch script?\n");
        return;
    }

    printf("=== Bootloader Started ===\n");
    printf("Self-detected binary size: %d bytes (0x%x)\n", size, size);
    printf("Bootloader start address:  %p\n", _payload_start);

    // 2. Calculate the current position of the Payload in memory
    // Payload Address = Bootloader Start Address + Bootloader Size
    uint8_t *payload_src = (uint8_t *)_payload_start + size;

    printf("Payload found at memory:   %p\n", payload_src);
    printf("Target execution address:  %p\n", TARGET_ADDR);

    // 3. Simulate moving (only printing here, use memcpy in actual projects)
    printf("Copying payload... [Done]\n");

    // 4. Simulate jump
    printf("Jumping to payload...\n");
}

int main(void) {
    boot_next_stage();
    return 0;
}
