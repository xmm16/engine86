END = build/kgb.iso
ASM_OUT_PRE = build/kgb_pre.asm
ASM_OUT = build/kgb.asm
FILES = src/engine/line.asm <(echo) src/engine/rect.asm <(echo)
KERNEL = src/core/kernel.asm
BOOT = src/core/boot.asm
CPP_COMPILER = clang++
ALIASER = build/aliases.cpp
ALIASER_OUT = build/aliases
ASSEMBLER  = nasm
FILE_BUILDER = dd
SIZE = 5000

all: $(END)

$(END):
	bash -c 'cat $(KERNEL) <(echo) $(FILES) > $(ASM_OUT_PRE)'
	$(CPP_COMPILER) $(ALIASER) -o $(ALIASER_OUT)
	$(ALIASER_OUT) $(ASM_OUT_PRE) $(ASM_OUT)

	$(ASSEMBLER) -f bin $(BOOT) -o build/boot.bin
	$(ASSEMBLER) -f bin $(ASM_OUT) -o build/kernel.bin
	$(FILE_BUILDER) if=/dev/zero of=$(END) bs=512 count=$(SIZE)
	$(FILE_BUILDER) if=build/boot.bin of=$(END) bs=512 seek=0 conv=notrunc
	$(FILE_BUILDER) if=build/kernel.bin of=$(END) bs=512 seek=1 conv=notrunc
	rm build/*.bin
	rm $(ASM_OUT_PRE)
	rm $(ALIASER_OUT)


clean:
	rm $(END) $(ASM_OUT)

.PHONY: all clean
