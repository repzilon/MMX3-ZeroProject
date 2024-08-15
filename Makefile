OS := $(shell uname -s)
MACHINE := $(shell uname -m)
ASAR_VERSION := 1.91
BASEROM := Base_ROM.sfc
CXX := c++
CXXFLAGS_OPTIM := -O2 -pipe
CXXFLAGS_WARNINGS := -Wno-deprecated-declarations

all: Atlas/MMX3.sfc

help:
	@echo "Available targets: all (default), clean, distclean"
	@echo " * Be sure to copy the unheadered Mega Man X 3 (U) ROM image then rename it to $(BASEROM)"
	@echo " * You will need CMake, cURL, UnZip and compiler command line tools (obviously)"

asar-$(ASAR_VERSION).tar.gz:
	curl https://codeload.github.com/RPGHacker/asar/tar.gz/refs/tags/v$(ASAR_VERSION) -o asar-$(ASAR_VERSION).tar.gz

asar-$(ASAR_VERSION): asar-$(ASAR_VERSION).tar.gz
	tar -zxf asar-$(ASAR_VERSION).tar.gz

asar-$(ASAR_VERSION)-$(MACHINE)-$(OS): asar-$(ASAR_VERSION)
	cmake -S asar-$(ASAR_VERSION)/src -B asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)

asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar: asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)
	@# TODO : parallelism and verbosity control
	make -C asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)

MMX3.sfc: $(BASEROM) asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar
	cp -f $(BASEROM) MMX3.sfc
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_BlankCode.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_VariousImports.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_OriginalLocations.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_NewCode_Locations.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_SubWeapon_Changes.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_Miscellaneous.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_Alltext.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_Events_X.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_Events_Zero.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_ItemObjects.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_Objects.asm" "MMX3.sfc"
	asar-$(ASAR_VERSION)-$(MACHINE)-$(OS)/asar/bin/asar "MMX3_SpriteSetup.asm" "MMX3.sfc"

atlas-1.11_p3-repzilon.zip:
	curl https://codeload.github.com/repzilon/Atlas/zip/refs/heads/main -o atlas-1.11_p3-repzilon.zip

Atlas-main/AtlasMain.cpp: atlas-1.11_p3-repzilon.zip
	unzip atlas-1.11_p3-repzilon.zip

Atlas-main/atlas: Atlas-main/AtlasMain.cpp
	@# TODO : convert to a proper parallel build
	$(CXX) $(CXXFLAGS_OPTIM) $(CXXFLAGS_WARNINGS) Atlas-main/*.cpp -ldl -o Atlas-main/atlas

Atlas/MMX3.sfc: MMX3.sfc Atlas-main/atlas
	cp -f MMX3.sfc Atlas
	@# TODO : parallelism and verbosity control
	@# FIXME : my crude Atlas port builds but cannot process the files correctly
	make -C Atlas

clean:
	rm -rf asar-*/
	rm -rf asar-*-$(MACHINE)-$(OS)
	rm -rf Atlas-main
	rm -f MMX3.sfc
	rm -f Atlas/MMX3.sfc

distclean: clean
	rm -f $(BASEROM)
	rm -f asar-*.tar.gz
	rm -f atlas-1.11_p3-repzilon.zip

.PHONY : all help clean distclean
