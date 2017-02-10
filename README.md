# SAMD20 Starter
Starter project for SAMD20 projects using a Makefile and OpenOCD.
The target compiler is GCC.

# Eeprom usage
Example code to use the eeprom emulator with 4 rows. One row is used for master row, one is used as
spare row and the other two can be used for pages.

    static void hard_reset(void)
    {
      __DSB();
      asm volatile ("cpsid i");
      WDT->CONFIG.reg = 0;
      WDT->CTRL.reg |= WDT_CTRL_ENABLE;
      while(1);
    }

    static void eeprom_init(void)
    {
      enum status_code error_code = eeprom_emulator_init();

      // Fusebits for memory are not set, or too low.
      // We need at least 3 pages, so set to 1024
      if (error_code == STATUS_ERR_NO_MEMORY) {
        struct nvm_fusebits fusebits;
        nvm_get_fuses(&fusebits);
        fusebits.eeprom_size = NVM_EEPROM_EMULATOR_SIZE_1024;
        nvm_set_fuses(&fusebits);
        hard_reset();
      } else if (error_code != STATUS_OK) {
        // Erase eeprom, assume unformated or corrupt
        eeprom_emulator_erase_memory();
        hard_reset();
      }
    }

Then you can call `eeprom_init();` in your `main` to initialize the eeprom. The allowed values for
`eeprom_size` can be found in `utils/nvm.h`.
