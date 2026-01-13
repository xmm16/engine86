SRCC = build/build.c
ENDC = build/build
COMPC = gcc

END = build/kgb.iso
COMP = build/build
SIZE = 5000

all: $(END)

$(END): $(SRC)
	$(COMPC) $(SRCC) -o $(ENDC)
	$(COMP) -o $(END) -s $(SIZE)

clean:
	rm $(END) $(ENDC)

.PHONY: all clean
