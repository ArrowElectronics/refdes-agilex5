#include "system.h"
#include "stdio.h"
#include "alt_types.h"
#include <sys/alt_sys_init.h>
#include "altera_avalon_sysid_qsys.h"
#include "altera_avalon_sysid_qsys_regs.h"

alt_u32   temp_data;

int main()
{
    // Initialize all of the HAL drivers used in this design
    alt_sys_init();

    // Read and display the system ID value created in hardware
    temp_data = IORD_ALTERA_AVALON_SYSID_QSYS_ID(SYSID_BASE);
    printf("\r\nHello World! My System ID is: 0x%08lX\r\n", temp_data);

    while (1);

    return 0;
}
