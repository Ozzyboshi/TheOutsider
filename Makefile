# The Outsider intro - relocatable rebuild
#
#   make        -> build/outsider (AmigaDOS executable) + build/outsider.adf
#   make run    -> start FS-UAE (A500, KS1.3, 512K chip + 512K slow) on the ADF
#   make run600 -> A600, KS2.05, 1MB chip
#   make run1200-> A1200, KS3.1, 2MB chip
#   make release-> copy the executable and the ADF into bin/ (tracked in git)
#   make clean

VASM     ?= vasmm68k_mot
EXE2ADF  ?= exe2adf
FSUAE    ?= fs-uae
KSDIR    ?= $(HOME)/Documenti/FS-UAE/Kickstarts
KICKSTART ?= $(KSDIR)/Kickstart v1.3 rev 34.5 (1987)(Commodore)(A500-A1000-A2000-CDTV)[!].rom
KICK600  ?= $(KSDIR)/Kickstart v2.05 rev 37.299 (1991)(Commodore)(A600)[!].rom
KICK1200 ?= $(KSDIR)/Kickstart v3.1 rev 40.68 (1993)(Commodore)(A1200).rom

# -no-opt keeps every instruction exactly as in the original (same timing)
VASMFLAGS = -m68000 -Fhunkexe -kick1hunks -nosym -no-opt -quiet

SRC   = dec/outsider.asm
BUILD = build
EXE   = $(BUILD)/outsider
ADF   = $(BUILD)/outsider.adf

all: $(EXE) $(ADF)

$(BUILD):
	mkdir -p $@

$(EXE): $(SRC) | $(BUILD)
	$(VASM) $(VASMFLAGS) -L $(BUILD)/outsider.lst -o $@ $<

$(ADF): $(EXE)
	$(EXE2ADF) -i $< -a $@ -l OUTSIDER

run: $(ADF)
	$(FSUAE) --amiga_model=A500 \
		--kickstart_file="$(KICKSTART)" \
		--chip_memory=512 --slow_memory=512 --fast_memory=0 \
		--floppy_drive_0="$(abspath $(ADF))" \
		--floppy_drive_speed=0

run600: $(ADF)
	$(FSUAE) --amiga_model=A600 --kickstart_file="$(KICK600)" \
		--floppy_drive_0="$(abspath $(ADF))" --floppy_drive_speed=0

run1200: $(ADF)
	$(FSUAE) --amiga_model=A1200 --kickstart_file="$(KICK1200)" \
		--floppy_drive_0="$(abspath $(ADF))" --floppy_drive_speed=0

release: $(EXE) $(ADF)
	mkdir -p bin
	cp $(EXE) bin/outsider
	cp $(ADF) bin/outsider.adf

clean:
	rm -rf $(BUILD)

.PHONY: all run run600 run1200 release clean
