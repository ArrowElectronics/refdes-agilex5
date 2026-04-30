#include "intel_mailbox_client_flash.h"
#include "sys/alt_irq.h"
#include "sys/alt_cache.h"
#include <stdio.h>
#include <unistd.h>

// Constants
#define PROGRAM_RECORD_HEADER_SZ 8
#define PROGRAM_RECORD_LEN_IDX 0
#define PROGRAM_RECORD_ADDR_IDX 1
#define ERASED_FLASH_CONTENTS 0xFFFFFFFF
#define MAX_ATTEMPTS 1000

// Design specific (customize here)
#define MBOX_NAME "/dev/niosv_system_0_mailbox_client"
#define PAYLOAD_OFFSET 0x200000

// Global header buffer
alt_u32 g_program_header[2];

//
// *** Assumptions: All addresses & lengths are 32-bit word aligned aka 0x0, 0x4, 0x8, 0xC, 0x10, etc
//

__attribute__((noreturn)) void error() {
    while (1);
}

void read_flash(intel_mailbox_client* mbox_client, int offset, void* dest_addr, int length) {
    if (mailbox_client_flash_read(mbox_client, offset, dest_addr, length) != 0)
        error();
}

__attribute__((noreturn)) int main(int argc, char **argv) {   
	intel_mailbox_client* mbox_client = mailbox_client_open(MBOX_NAME);
    int record_address_ptr = PAYLOAD_OFFSET;

    printf("++++++++++++++++++++++++++++++++ Boot Copier ++++++++++++++++++++++++++++++\r\n\r\n");

    printf("Booting Nios V/g processor from On Chip Memory\r\n\r\n");

    // Obtain exclusive flash access
    int attempt = 0;

    while((mailbox_client_flash_open(mbox_client) != 0) && (++attempt < MAX_ATTEMPTS)){
    	usleep(10000);
    }
    if (attempt == MAX_ATTEMPTS)
        error();
    
    for (;;) {
        read_flash(mbox_client, record_address_ptr, (void *)g_program_header, PROGRAM_RECORD_HEADER_SZ);
        record_address_ptr += PROGRAM_RECORD_HEADER_SZ;

        // The address in this case is the jump target
        if (g_program_header[PROGRAM_RECORD_LEN_IDX] == 0)
            break;
        
        // This is not a legal or sane length.  It implies the flash we're reading isn't
        // programmed, and the safest thing to do in this case is error out.
        if (g_program_header[PROGRAM_RECORD_LEN_IDX] == ERASED_FLASH_CONTENTS)
            error();  
        
        read_flash(mbox_client, record_address_ptr, (void *)(g_program_header[PROGRAM_RECORD_ADDR_IDX]), g_program_header[PROGRAM_RECORD_LEN_IDX]);        
        record_address_ptr += g_program_header[PROGRAM_RECORD_LEN_IDX];
    }

    printf("User Application copied from external QSPI to external HyperRAM\r\n\r\n");

    // Release exclusive flash access
    if (mailbox_client_flash_close(mbox_client) != 0)
        error();
    
    printf("Jumping to User Application target in HyperRAM\r\n");

    // Disable all interrupts before jumping
    alt_irq_disable_all();
    
    // Flush data cache — ensures all copied bytes reach DRAM
    alt_dcache_flush_all();
    // Invalidate instruction cache — forces fresh fetch from DRAM
    alt_icache_flush_all();
    // Memory barrier — prevents any reordering across the fence
    __asm volatile ("fence.i" ::: "memory");

    // Jump to user application
    void *jump_target = (void *)(g_program_header[PROGRAM_RECORD_ADDR_IDX]);

    asm volatile ("jr %[reset_vec]" : : [reset_vec] "r"(jump_target));
    
    // Code should never get here -- put here to keep the compiler happy
    while (1);
}
