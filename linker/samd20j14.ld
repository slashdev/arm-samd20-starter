/**
 * \brief Linker script for running in internal FLASH on the SAMD20J14
 */

/* Memory Spaces Definitions */
MEMORY
{
  rom (rx)  : ORIGIN = 0x00000000, LENGTH = 0x00004000
  ram (rwx) : ORIGIN = 0x20000000, LENGTH = 0x00000800
}

/* Include common linker script */
INCLUDE samd20_common.ld
