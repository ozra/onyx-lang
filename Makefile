.PHONY: all spec onyx doc clean bootstrap

-include Makefile.local # for optional local options e.g. threads

O := .build
SOURCES := $(shell find src -name '*.cr')
SPEC_SOURCES := $(shell find spec -name '*.cr')
FLAGS := $(if $(release),--release )$(if $(stats),--stats )$(if $(threads),--threads $(threads) )
EXPORTS := $(if $(release),,CRYSTAL_CONFIG_PATH=`pwd`/src)
SHELL = /bin/bash
LLVM_CONFIG := $(shell command -v llvm-config-3.6 llvm-config-3.5 llvm-config | head -n 1)
LLVM_EXT_DIR = src/llvm/ext
LLVM_EXT_OBJ = $(LLVM_EXT_DIR)/llvm_ext.o

all: onyx

bootstrap:
	./bootstrap.sh

spec: all_spec
	$(O)/all_spec
doc:
	$(BUILD_PATH) ./bin/crystal doc docs/main.cr

onyx: $(O)/onyx

all_spec: $(O)/all_spec

llvm_ext: $(LLVM_EXT_OBJ)

$(O)/all_spec: $(LLVM_EXT_OBJ) $(SOURCES) $(SPEC_SOURCES)
	@mkdir -p $(O)
	$(BUILD_PATH) ./bin/crystal build $(FLAGS) -o $@ spec/all_spec.cr

$(O)/onyx: $(LLVM_EXT_OBJ) $(SOURCES)
	@mkdir -p $(O)
	$(BUILD_PATH) $(EXPORTS) ./bin/crystal build $(FLAGS) -o $@ src/compiler/onyx.cr

$(LLVM_EXT_OBJ): $(LLVM_EXT_DIR)/llvm_ext.cc
	$(CXX) -c -o $@ $< `$(LLVM_CONFIG) --cxxflags`

clean:
	rm -rf $(O)
	rm -rf ./doc
	rm -rf $(LLVM_EXT_OBJ)
