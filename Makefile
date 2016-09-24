-include Makefile.local # for optional local options e.g. threads

O := .build
SOURCES := $(shell find src -name '*.cr')
SPEC_SOURCES := $(shell find spec -name '*.cr') $(shell find spec -name '*.ox')
FLAGS := $(if $(release),--release )$(if $(stats),--stats )$(if $(threads),--threads $(threads) )$(if $(debug),-d )
EXPORTS := $(if $(release),,CRYSTAL_CONFIG_PATH=`pwd`/src)

ifdef disable_all_oxides
	disable_ox_typarchy = 1
	disable_ox_libspicing = 1
endif

DEFINES := $(if $(disable_ox_typarchy),-D disable_ox_typarchy,)
DEFINES := $(DEFINES) $(if $(disable_ox_libspicing),-D disable_ox_libspicing,)
DEFINES := $(DEFINES) $(if $(x_verbose),-D ox_verbose_debug,)

SHELL = bash
LLVM_CONFIG_FINDER := command -v llvm-config-3.8 || command -v llvm-config38 || (command -v llvm-config > /dev/null && (case "$(llvm-config --version)" in 3.8*) command -v llvm-config;; *) false;; esac)) || command -v llvm-config-3.6 || command -v llvm-config36 || command -v llvm-config-3.5 || command -v llvm-config35 || command -v llvm-config
LLVM_CONFIG := $(shell $(LLVM_CONFIG_FINDER))
LLVM_EXT_DIR = src/llvm/ext
LLVM_EXT_OBJ = $(LLVM_EXT_DIR)/llvm_ext.o
LIB_CRYSTAL_SOURCES = $(shell find src/ext -name '*.c')
LIB_CRYSTAL_OBJS = $(subst .c,.o,$(LIB_CRYSTAL_SOURCES))
LIB_CRYSTAL_TARGET = src/ext/libcrystal.a
CFLAGS += -fPIC

ifeq (${LLVM_CONFIG},)
$(error Could not locate llvm-config, make sure it is installed and in your PATH)
endif

.PHONY: all
all:
	make onyx release=1

.PHONY: dev
dev:
	make onyx release=

# Extremely verbose devel build of onyx
.PHONY: x
x:
	make onyx release= x_verbose=1

.PHONY: bootstrap
bootstrap:
	./bootstrap.sh

.PHONY: install
install:
	./install.sh

.PHONY: spec
spec: all_spec
	$(O)/all_spec

.PHONY: std_spec
std_spec: all_std_spec ## Run standard library specs
	$(O)/std_spec

.PHONY: compiler_spec
compiler_spec: all_compiler_spec ## Run compiler specs
	$(O)/compiler_spec

.PHONY: doc
doc:
	$(BUILD_PATH) ./bin/onyx doc src/docs_main.cr

.PHONY: onyx
onyx: $(O)/onyx

.PHONY: all_spec
all_spec: $(O)/all_spec

.PHONY: all_std_spec
all_std_spec: $(O)/std_spec

.PHONY: all_compiler_spec
all_compiler_spec: $(O)/compiler_spec

.PHONY: llvm_ext
llvm_ext: $(LLVM_EXT_OBJ)

.PHONY: libcrystal
libcrystal: $(LIB_CRYSTAL_TARGET)

.PHONY: deps
deps: llvm_ext libcrystal

.PHONY: help
help: ## Show this help
	@printf '\033[34mtargets:\033[0m\n'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) |\
		sort |\
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

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
	$(BUILD_PATH) $(EXPORTS) ./bin/cr-ox build $(FLAGS) -o $@ src/compiler/onyx.cr -s $(DEFINES) -D without_openssl -D without_zlib

$(LLVM_EXT_OBJ): $(LLVM_EXT_DIR)/llvm_ext.cc
	$(CXX) -c -o $@ $< `$(LLVM_CONFIG) --cxxflags`

$(LIB_CRYSTAL_TARGET): $(LIB_CRYSTAL_OBJS)
	ar -rcs $@ $^

.PHONY: clean
clean: ## Clean up built directories and files
	rm -rf $(O)
	rm -rf $(LLVM_EXT_OBJ)
	rm -rf $(LIB_CRYSTAL_OBJS) $(LIB_CRYSTAL_TARGET)
