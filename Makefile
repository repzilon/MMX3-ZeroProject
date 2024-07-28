OS := $(shell uname -s)
MACHINE := $(shell uname -m)
ASAR_VERSION := 1.91
BASEROM := Base_ROM.sfc
CXX := c++
CXXFLAGS_OPTIM := -O2
CXXFLAGS_WARNINGS := -Wno-deprecated-declarations

all: Atlas/MMX3.sfc

help:
	@echo "Available targets: all (default), clean, distclean"
	@echo " * Be sure to copy the unheadered Mega Man X 3 (U) ROM image then rename it to $(BASEROM)"
	@echo " * Also download Atlas from https://www.romhacking.net/download/utilities/224/"
	@echo "   and copy it as Atlasv1.11.zip . Unlike Asar, it cannot be downloaded automatically"
	@echo "   because of a CAPTCHA on romhacking.net."
	@echo " * You will need CMake, cURL, UnZip, patch and compiler command line tools (obviously)"

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

atlas-1.11/src/AtlasMain.cpp: Atlasv1.11.zip
	mkdir atlas-1.11
	unzip -d atlas-1.11 "Atlasv1.11.zip"

atlas-1.11/src/atlas: atlas-1.11/src/AtlasMain.cpp
	@# TODO : improve the patch portability (I probably messed up with compiler defines)
	patch -p0 < atlas-1.11-$(OS)-r1.patch
	@# TODO : convert to a proper parallel build
	$(CXX) $(CXXFLAGS_OPTIM) -pipe $(CXXFLAGS_WARNINGS) atlas-1.11/src/*.cpp -ldl -o atlas-1.11/src/atlas

Atlas/MMX3.sfc: MMX3.sfc atlas-1.11/src/atlas
	cp -f MMX3.sfc Atlas
	@# TODO : parallelism and verbosity control
	@# FIXME : my crude Atlas port builds but cannot process the files correctly
	make -C Atlas

clean:
	rm -rf asar-*
	rm -rf asar-*-$(MACHINE)-$(OS)
	rm -rf atlas-1.11
	rm -f MMX3.sfc
	rm -f Atlas/MMX3.sfc

distclean: clean
	rm -f $(BASEROM)
	rm -f asar-*.tar.gz
	rm -f Atlasv1.11.zip

.PHONY : all help clean distclean
