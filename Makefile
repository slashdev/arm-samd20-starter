# Name: Makefile
# Authors:
# - Ferdi van der Werf <ferdi@slashdev.nl>
# - Alex Taradov <alex@taradov.com>

# Based on the Makefile from Alex Taradov <alex@taradov.com>,
# see his project on https://github.com/ataradov/mcu-starter-projects

# This is a prototype Makefile. Modify it according to your needs.
# You should at least check the settings for
# DEVICE ....... The SAM device you compile for
# ARCH ......... The architecture you compile for
# CLOCK ........ Target SAM clock rate in Hertz

#######################################
-include $(wildcard Makefile.make)

#######################################
BINARY       ?= starter
BUILD_DIR    ?= build
SOURCES_DIR  ?= src

# Device, 8 MHz
DEVICE       ?= samd20j15
FAMILY       ?= samd20
ARCH         ?= cortex-m0plus
CLOCK        ?= 8000000

OPTIMIZATION ?= s
DEBUG_LEVEL  ?= 3

#######################################
# Tune the lines below only if you know what you are doing:
.PHONY: lc uc all clear rebuild watch help clean lss upload reset directories size

CROSS       = arm-none-eabi-
CC          = $(CROSS)gcc
OBJCOPY     = $(CROSS)objcopy
OBJDUMP     = $(CROSS)objdump
SIZE        = $(CROSS)size
OPENOCD     = openocd

# Objects dir
OBJECTS_DIR = $(BUILD_DIR)/obj

# CPU flags
CPU_FLAGS   = -mcpu=$(ARCH) -mthumb
CC_FLAGS   += $(CPU_FLAGS)
CXX_FLAGS  += $(CPU_FLAGS)
LD_FLAGS   += $(CPU_FLAGS)

# Set the coding standard, optimization and debug flags
CC_FLAGS   += --std=gnu99 -O$(OPTIMIZATION) -g$(DEBUG_LEVEL)

# Dependency flags
CC_FLAGS   += -MD -MP

# Use pipes instead of temporary files for communication between processes
CC_FLAGS   += -pipe
CXX_FLAGS  += -pipe
LD_FLAGS   += -pipe

# Always enable warnings. And be very careful about implicit declarations.
CC_FLAGS    += -W -Wall -Werror -Wpointer-arith -Wstrict-prototypes -Wmissing-prototypes
CC_FLAGS    += -Werror-implicit-function-declaration
CXX_FLAGS   += -Wall
# IAR does not allow arithmetic on void pointers, so warn about that.
CC_FLAGS    += -Wpointer-arith
CXX_FLAGS   += -Wpointer-arith

# ----------------------------------------------------------------------
# Compiler flags
# ----------------------------------------------------------------------

# By default, each diagnostic emitted includes the original source
# line and a caret ‘^’ indicating the column. This option suppresses
# this information.
# CC_FLAGS   += -fno-diagnostics-show-caret

# Permits the char type to be signed, as in the type signed char.
# CC_FLAGS   += -funsigned-char

# These options control whether a bit-field is signed or unsigned,
# when the declaration does not use either signed or unsigned.
# By default, such a bit-field is signed, because this is consistent:
# the basic integer types such as int are signed types.
#
# Use only one of these:
# CC_FLAGS   += -fsigned-bitfields
# CC_FLAGS   += -funsigned-bitfields

# This optimization option, for output targets that support arbitrary
# code sections, causes GCC to place each function into its own
# section in the output file. The name of the function determines the
# name of the section in the output file. This option is typically
# used on systems whose linkers can perform optimizations that
# improve the locality of reference in the instruction space.
#
# Using this option causes the assembler and linker to create larger
# object and executable files that may therefore be slower on some
# systems.
#
# Using this option also prevents the use of gprof on some systems
# and may cause problems if you are also compiling with the -g option.
CC_FLAGS   += -ffunction-sections

# This optimization option, for output targets that support arbitrary
# code sections, causes GCC to place each data item into its own
# section in the output file. The name of the data item determines
# the name of the section in the output file.
# -> Same issues as with -ffunction-sections
CC_FLAGS   += -fdata-sections

# This preprocessor option along with the -M or -MM options identifies
# the name of a file to which GCC should write dependency information.
CC_FLAGS   += -MF "$(@:%.o=%.d)"

# This preprocessor option causes GCC to change the output target in
# the rule emitted by dependency-rule generation. Instead of following
# the standard extension-substitution naming convention, using this
# option sets the name of the output file to the exact filename that
# you specify.
CC_FLAGS   += -MT "$(@:%.o=%.d)"
CC_FLAGS   += -MT "$(@)"

# ----------------------------------------------------------------------
# Linker flags
# ----------------------------------------------------------------------

# Generate map file based on the BINARY name add cross reference to
# map file.
LD_FLAGS   += -Wl,-Map=$(BUILD_DIR)/$(BINARY).map,--cref

# By adding -specs=nano.specs to the gcc link command, a reduced-size
# libc is linked in (libc_nano). The effect of this on the final
# program size is significant.
LD_FLAGS   += --specs=nosys.specs --specs=nano.specs

# There are many library functions provided in common source files.
# All code and data is currently linked into every executable, and
# most of the images do not use most of the functions. Significant
# SRAM could be saved if only the required code and data are
# included.
#
# Using the GCC -ffunction-sections and LD --gc-sections directives
# automatically only include used code and data for C sources. This
# requires linker scripts to include any new input sections.
LD_FLAGS   += -Wl,--gc-sections

# Link the math library.
# LD_FLAGS   += -Wl,--start-group -lm -Wl,--end-group

# Initial entry point for a program. Not every source file has to
# have an entry point. Multiple entry points in a single source
# file are not permitted.
LD_FLAGS   += -Wl,--entry=irq_handler_reset

# Use script as the linker script.
LD_FLAGS   += -Wl,--script=linker/$(DEVICE).ld

INCLUDES   += -Iinclude
INCLUDES   += -Isrc

DEFINES    += -D__$(call uc,$(DEVICE))__
DEFINES    += -D$(call uc,$(FAMILY))
DEFINES    += -DDONT_USE_CMSIS_INIT
DEFINES    += -DF_CPU=$(CLOCK)

SOURCES     = $(wildcard $(SOURCES_DIR)/**/*.c) $(wildcard $(SOURCES_DIR)/*.c)
OBJECTS     = $(addprefix $(OBJECTS_DIR)/, $(notdir %/$(subst .c,.o, $(SOURCES))))
DIRECTORIES = $(patsubst $(SOURCES_DIR)/%,$(OBJECTS_DIR)/%,$(sort $(dir $(wildcard $(SOURCES_DIR)/*/))))

CC_FLAGS   += $(INCLUDES)
CC_FLAGS   += $(DEFINES)

COL_INFO    = tput setaf 2
COL_BUILD   = tput setaf 7
COL_ERROR   = tput setaf 1
COL_RESET   = tput sgr0

ELF         = $(BUILD_DIR)/$(BINARY).elf
HEX         = $(BUILD_DIR)/$(BINARY).hex
BIN         = $(BUILD_DIR)/$(BINARY).bin
LSS         = $(BUILD_DIR)/$(BINARY).lss
MAP         = $(BUILD_DIR)/$(BINARY).map

log_info = $(COL_RESET); printf "$(1) "
log_ok   = $(COL_RESET); printf "["; $(COL_INFO); printf "OK"; $(COL_RESET); printf "]\n"

# Build executable
all: directories $(ELF) $(HEX) $(LSS) $(BIN) size

# Clear screen
clear:
	@clear

# Cleans and builds everything
rebuild: clear clean all

# Watch the current directory and rebuild when a file changes
watch:
	@clear
	@echo "Watching current directory for changes"
	@fswatch --recursive --event Updated --exclude build --one-per-batch ./include/ ./linker/ ./src/  | xargs -n1 -I{} make rebuild

# Help, explains usage
help:
	@echo "Usage:"
	@echo "- all:     Build executable"
	@echo "- clean:   Clean the workspace and remove old builds"
	@echo "- help:    Display this help"
	@echo "Using OpenOCD:"
	@echo "- upload:  Upload elf to chip"
	@echo "- reset: Restart the chip"

# Clean environment
clean:
	@$(call log_info,"Cleaning...")
	@rm -rf $(ELF) $(HEX) $(BIN) $(LSS) $(MAP) $(OBJECTS_DIR)
	@$(call log_ok)

# Use disasm for debugging
lss: $(ELF)
	@$(call log_info,Create lss from elf)
	@$(OBJDUMP) --section-headers --file-headers --disassemble --demangle --line-numbers --source --syms --section=.text --wide $(ELF) > $(LSS)
	@$(call log_ok)

# OpenOCD / AtmelICE
upload:
	$(OPENOCD) -f openocd.cfg -c "program $(ELF) verify reset exit"

reset:
	$(OPENOCD) -f openocd.cfg -c 'init; reset; exit'

# Build specific
directories:
	@$(call log_info,Create directories in \'$(OBJECTS_DIR)\')
	@mkdir -p $(DIRECTORIES) $(BUILD_DIR)
	@$(call log_ok)

$(ELF): $(OBJECTS)
	@echo
	@$(call log_info,Linking $(ELF))
	@$(COL_ERROR)
	@$(CC) $(LD_FLAGS) $(OBJECTS) $(LIBS) -o $(ELF)
	@$(call log_ok)

$(HEX): $(ELF)
	@$(call log_info,Create new hex files)
	@$(COL_ERROR)
	@rm -f $(HEX) $(LSS)
	@$(OBJCOPY) --output-target ihex $(ELF) $(HEX)
	@$(call log_ok)

$(LSS): $(ELF)
	@$(call log_info,Create lss from elf)
	@$(OBJDUMP) --headers --section-headers --file-headers --disassemble --demangle --line-numbers --source --syms --section=.text --wide $(ELF) > $(LSS)
	@$(call log_ok)

$(BIN): $(ELF)
	@$(call log_info,Create binary from elf)
	@$(COL_ERROR)
	@$(OBJCOPY) --output-target binary $(ELF) $(HEX)
	@$(call log_ok)

size: $(ELF)
	@echo
	@$(COL_INFO)
	@echo Size:
	@$(COL_BUILD)
	@$(SIZE) --format=sysv --totals $(ELF)
	@$(SIZE) --format=berkley --totals $(ELF)
	@$(COL_RESET)

%.o:
	@$(call log_info,Compiling $(filter %/$(subst .o,.c,$(notdir $@)), $(SOURCES)))
	@$(COL_ERROR)
	@$(CC) $(CC_FLAGS) $(filter %/$(subst .o,.c,$(notdir $@)), $(SOURCES)) -c -o $@
	@$(call log_ok)

.S.o:
	@$(CC) $(CC_FLAGS) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.

.c.s:
	@$(call log_info,Compiling $<)
	@$(COL_ERROR)
	@$(CC) $(CC_FLAGS) -S $< -o $@
	@$(call log_ok)

-include $(wildcard $(BUILD_DIR)/*.d)

# Funky methods to help me
lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))
uc = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))
