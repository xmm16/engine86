END = build/kgb.iso
ASM_OUT = build/kgb.asm
SIZE = 5000

all: $(END)

$(END):
	cat src/core/kernel.asm src/engine/* > $(ASM_OUT)
	nasm -f bin src/core/boot.asm -o build/boot.bin
	nasm -f bin $(ASM_OUT) -o build/kernel.bin
	dd if=/dev/zero of=$(END) bs=512 count=$(SIZE)
	dd if=build/boot.bin of=$(END) bs=512 seek=0 conv=notrunc
	dd if=build/kernel.bin of=$(END) bs=512 seek=1 conv=notrunc
	rm build/*.bin


clean:
	rm $(END) $(ASM_OUT)

.PHONY: all clean
