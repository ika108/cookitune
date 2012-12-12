TARGET_DIR = $(PWD)

all: $(TARGET)

$(TARGET) : % : %.hex
				 
.PHONY: all $(TARGET)

CROSS_COMPILE	= $(AVRPREFIX)/bin/avr-
CC		= $(CROSS_COMPILE)gcc
GDB		= $(CROSS_COMPILE)gdb
OBJCOPY	= $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
AVR_MCU_FLAGS	= -mmcu=$(AVR_MCU)
AVR_SIMULATOR = $(AVRPREFIX)/bin/simulavr
AVR_SIMULATOR_ARGS = -g -p 4444 -d $(AVR_MCU) -F $(F_CPU) -t $(TARGET)-trace.out -c vcd:$(TARGET)-parts.vcd:$(TARGET)-trace.vcd:w


CFLAGS += -Os \
	-Wall \
	-Wimplicit \
	-Wpointer-arith \
	-Wswitch \
	-Wredundant-decls \
	-Wreturn-type \
	-Wshadow \
	-Wunused \
	-Wcast-qual \
	-Wnested-externs \
	-Wmissing-prototypes \
	-Wstrict-prototypes \
	-Wmissing-declarations \
	--save-temps \
	-g

CPPFLAGS += $(AVR_MCU_FLAGS) -I . -I libs -I lib -I include -DF_CPU=$(F_CPU)
LDFLAGS  += $(AVR_MCU_FLAGS) -Wl,-Map,$(basename $@).map

DEP_OUTPUT_OPTION = -MMD -MF $(@:.o=.d)

ECHO	= @echo
RM	= rm

COMMON_DEPS = $(strip $(INCLUDED_LIBS:.o=.d))

DEP_FILES = $(TARGET).d $(COMMON_DEPS)

PREPROCESS.c = $(CC) $(CPPFLAGS) $(TARGET_ARCH) -E -Wp,-C,-dD,-dI

FORCE:

.PHONY: FORCE

.PRECIOUS: %.o

%.o : %.c %.d
	$(ECHO) "Compiling $< ..."
	$(Q)$(COMPILE.c) $(DEP_OUTPUT_OPTION) $(OUTPUT_OPTION) $<

%.o : %.c
	$(ECHO) "Compiling $< ..."
	$(Q)$(COMPILE.c) $(DEP_OUTPUT_OPTION) $(OUTPUT_OPTION) $<
%.o : %.S
	$(ECHO) "Assembling $< ..."
	$(Q)$(COMPILE.S) $(OUTPUT_OPTION) $<
.PHONY: %.d
%.d: ;

%.pp : %.c FORCE
	$(ECHO) "Preprocessing $< ..."
	$(Q)$(PREPROCESS.c) $< > $@

%.cod : %.c FORCE
	$(ECHO) "Listing $< ..."
	$(Q)$(COMPILE.c) -gstabs -Wa,-ahdlms=$@ $<

%.hex : %.elf
	$(ECHO) "Creating $@ ..."
	$(Q)$(OBJCOPY) -j .text -j .data -O ihex $< $@
	$(ECHO)

%.od :  %.elf
	$(ECHO) "Creating $@ ..."
	$(Q)$(OBJDUMP) -zhD $< > $@  

%-eep.hex : %.elf
	$(ECHO) "Creating $@ ..."
	$(Q)$(OBJCOPY) -j .eeprom -O ihex $< $@
	$(ECHO)

.PRECIOUS: %.elf

ifeq ($(MAIN_OBJS),)
MAIN_OBJS = $(TARGET).o
endif

$(TARGET).elf : $(MAIN_OBJS) $(INCLUDED_LIBS)
	$(ECHO) "Linking $@ ..."
	$(Q)$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@
	$(ECHO)
	# $(AVRPREFIX)/bin/avr-mem.sh $@ $(AVR_MCU)
	$(ECHO)

clean: clean-other clean-hex

clean-other:
	$(ECHO) "Removing generated files ..."
	$(Q)$(RM) -f *.d *.o *.i *.s *.elf *.vcd *.out *.map *~ libs/*~ *.od libs/*.o libs/*.d

clean-hex:
	$(ECHO) "Removing hex files ..."
	$(Q)$(RM) -f *.hex

install: $(TARGET).hex
	$(ECHO) "Installing .hex into AVR..."
	avrdude  -c stk500 -p $(AVR_MCU) -e -U flash:w:$(TARGET).hex

dump:	$(TARGET).elf
	$(ECHO) "Dumping elf structure..."
	$(Q)$(OBJDUMP) -h -S $(TARGET).elf

$(TARGET)-parts.vcd : 
	$(ECHO) "Generation VCD part file..."
	$(AVR_SIMULATOR) -d $(AVR_MCU) -F $(F_CPU) -o $(TARGET)-parts.vcd

simul:	$(TARGET).elf $(TARGET)-parts.vcd
	$(ECHO) "Starting simulation"
	x-terminal-emulator -e $(AVR_SIMULATOR) $(AVR_SIMULATOR_ARGS)
	$(GDB) --eval-command="file $(TARGET).elf" --eval-command="target remote :4444" --eval-command="load" 

simul-data:  $(TARGET).elf $(TARGET)-parts.vcd
	$(ECHO) "Starting simulation to collect data..."
	$(AVR_SIMULATOR) -d $(AVR_MCU) -F $(F_CPU) -c vcd:$(TARGET)-parts.vcd:$(TARGET)-trace.vcd:w -m 1000000000 -f $(TARGET).elf
	gtkwave $(TARGET)-trace.vcd

ifneq ($(DEP_FILES),)
ifeq ($(strip $(filter clean% exec print-%, $(MAKECMDGOALS))),)
-include $(DEP_FILES)
endif
endif
