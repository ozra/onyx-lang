.PHONY: all spec onyx doc clean bootstrap

-include Makefile.local # for optional local options e.g. threads

O := .build
SOURCES := $(shell find src -name '*.cr')
SPEC_SOURCES := $(shell find spec -name '*.cr') $(shell find spec -name '*.ox')
FLAGS := $(if $(release),--release )$(if $(stats),--stats )$(if $(threads),--threads $(threads) )$(if $(debug),-d )
EXPORTS := $(if $(release),,CRYSTAL_CONFIG_PATH=`pwd`/src)
# EXPORTS := CRYSTAL_CONFIG_PATH=`pwd`/src

SHELL = bash
LLVM_CONFIG := $(shell command -v llvm-config-3.6 llvm-config36 llvm-config-3.5 llvm-config35 llvm-config | head -n 1)

LLVM_EXT_DIR = src/llvm/ext
LLVM_EXT_OBJ = $(LLVM_EXT_DIR)/llvm_ext.o
LIB_CRYSTAL_SOURCES = $(shell find src/ext -name '*.c')
LIB_CRYSTAL_OBJS = $(subst .c,.o,$(LIB_CRYSTAL_SOURCES))
LIB_CRYSTAL_TARGET = src/ext/libcrystal.a
CFLAGS += -fPIC

all: onyx

bootstrap:
	./bootstrap.sh

install:
	./install.sh

ifeq (${LLVM_CONFIG},)
$(error Could not locate llvm-config, make sure it is installed and in your PATH)
endif

spec: all_spec
	$(O)/all_spec
std_spec: all_std_spec
	$(O)/std_spec
compiler_spec: all_compiler_spec
	$(O)/compiler_spec
doc:
	$(BUILD_PATH) ./bin/cr-ox doc src/docs_main.cr

onyx: $(O)/onyx

all_spec: $(O)/all_spec
all_std_spec: $(O)/std_spec
all_compiler_spec: $(O)/compiler_spec

llvm_ext: $(LLVM_EXT_OBJ)
libcrystal: $(LIB_CRYSTAL_TARGET)
deps: llvm_ext libcrystal

$(O)/all_spec: deps $(SOURCES) $(SPEC_SOURCES)
	@mkdir -p $(O)
	$(BUILD_PATH) ./bin/cr-ox build $(FLAGS) -o $@ spec/all_spec.cr

$(O)/std_spec: deps $(SOURCES) $(SPEC_SOURCES)
	@mkdir -p $(O)
	$(BUILD_PATH) ./bin/cr-ox build $(FLAGS) -o $@ spec/std_spec.cr

$(O)/compiler_spec: deps $(SOURCES) $(SPEC_SOURCES)
	@mkdir -p $(O)
	$(BUILD_PATH) ./bin/cr-ox build $(FLAGS) -o $@ spec/compiler_spec.cr

$(O)/onyx: deps $(SOURCES)
	@mkdir -p $(O)
	$(BUILD_PATH) $(EXPORTS) ./bin/cr-ox build $(FLAGS) -o $@ src/compiler/onyx.cr -D without_openssl -D without_zlib

$(LLVM_EXT_OBJ): $(LLVM_EXT_DIR)/llvm_ext.cc
	$(CXX) -c -o $@ $< `$(LLVM_CONFIG) --cxxflags`

$(LIB_CRYSTAL_TARGET): $(LIB_CRYSTAL_OBJS)
	ar -rcs $@ $^

clean:
	rm -rf $(O)
	rm -rf $(LLVM_EXT_OBJ)
	rm -rf $(LIB_CRYSTAL_OBJS) $(LIB_CRYSTAL_TARGET)
