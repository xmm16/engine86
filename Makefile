END = build/kgb.iso
ASM_OUT = build/kgb.asm
FILES = src/engine/line.asm src/engine/rect.asm 
KERNEL = src/core/kernel.asm
BOOT = src/core/boot.asm
ASSEMBLER  = nasm
FILE_BUILDER = dd
SIZE = 5000

all: $(END)

$(END):
	cat $(KERNEL) $(FILES) > $(ASM_OUT)
	$(ASSEMBLER) -f bin $(BOOT) -o build/boot.bin
	$(ASSEMBLER) -f bin $(ASM_OUT) -o build/kernel.bin
	$(FILE_BUILDER) if=/dev/zero of=$(END) bs=512 count=$(SIZE)
	$(FILE_BUILDER) if=build/boot.bin of=$(END) bs=512 seek=0 conv=notrunc
	$(FILE_BUILDER) if=build/kernel.bin of=$(END) bs=512 seek=1 conv=notrunc
	rm build/*.bin


clean:
	rm $(END) $(ASM_OUT)

.PHONY: all clean
