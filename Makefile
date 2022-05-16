VERBOSE ?= 1

ifeq ($(VERBOSE),1)
	export Q :=
export VERBOSE := 1
else
	export Q := @
export VERBOSE := 0
endif

CPPCHECK = cppcheck
BEAR = bear
CLANG_FORMAT = clang-format-12
GCOVR = gcovr
PKG_CONFIG = pkg-config

CXXFLAGS = -std=c++17
LDFLAGS =

BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/objects
EXEC_DIR = $(BUILD_DIR)/exec

PROJECT = example
EXEC = $(EXEC_DIR)/$(PROJECT)
TEST_EXEC = $(EXEC_DIR)/tests
LIB = $(OBJ_DIR)/lib$(PROJECT).a

INCLUDE = -Iinclude/
SRC = \
   $(wildcard src/submodule/*.cpp) \
   $(wildcard src/*.cpp)

OBJ = $(SRC:%.cpp=$(OBJ_DIR)/%.o)
DEPS = $(OBJ:.o=.d)

SRC_TESTS = $(wildcard tests/*.cpp)
OBJ_TESTS = $(SRC_TESTS:%.cpp=$(OBJ_DIR)/%.o)

.PHONY: all test debug release clean cppcheck bear help format-dry force

LDFLAGS += $(shell $(PKG_CONFIG) --libs libpng)
CXXFLAGS += -I/usr/include/png++

all: $(EXEC)
test: $(TEST_EXEC)

$(OBJ_DIR)/%.o: %.cpp build/cxx_flags
	@mkdir -p $(@D)
	$(Q) $(CXX) $(CXXFLAGS) $(INCLUDE) -c $< -MMD -o $@

$(EXEC): $(OBJ)
	@mkdir -p $(@D)
	$(Q) $(CXX) $(CXXFLAGS) -o $(EXEC) $^ $(LDFLAGS)

$(LIB): $(filter-out $(OBJ_DIR)/src/main.o, $(OBJ))
	$(Q) $(AR) rcs $(LIB) $^

$(TEST_EXEC): $(OBJ_TESTS) $(LIB)
	@mkdir -p $(@D)
	$(Q) $(CXX) $(CXXFLAGS) -o $(TEST_EXEC) $(OBJ_TESTS) $(LDFLAGS) -L$(OBJ_DIR) -l$(PROJECT)

$(OBJ_DIR)/src/image.o: private CXXFLAGS += -Wall

-include $(DEPS)

debug: CXXFLAGS += -DDEBUG -g
debug: all

release: CXXFLAGS += -O2
release: all

clean:
	-@rm -rvf $(BUILD_DIR)

# Note: Links dynamic by default. Use eg. -static-libasan if it's not desirable.
SANITIZER ?= none
ifneq ($(SANITIZER),none)
	CXXFLAGS += -fsanitize=$(SANITIZER)
endif

define check_exec
	command -v $(1) >/dev/null || (echo ERROR: $(1) not found in path; exit 1)
endef

CPPCHECKFLAGS += --enable=style,warning --cppcheck-build-dir=$(BUILD_DIR) --std=c++17
cppcheck:
	$(call check_exec, $(CPPCHECK))
	$(CPPCHECK) $(CPPCHECKFLAGS) $(SRC) $(SRC_TESTS) $(INCLUDE)

bear:
	$(call check_exec, $(BEAR))
	$(Q) $(BEAR) -- $(MAKE) clean all test

format-dry:
	$(call check_exec, $(CLANG_FORMAT))
	@$(CLANG_FORMAT) --dry-run $(SRC) $(SRC_TESTS)

coverage: CXXFLAGS += -O0 --coverage -g
coverage: test
coverage:
	./$(TEST_EXEC)

gcovr:
	$(call check_exec, $(GCOVR))
	$(GCOVR) --object-directory=$(OBJ_DIR)

build/cxx_flags: force
	@mkdir -p $(@D)
	-@echo '$(CXXFLAGS)' | cmp -s - $@ || echo '$(CXXFLAGS)' > $@

help:
	@echo "usage: make [OPTIONS] <target>"
	@echo "  Options:"
	@echo "    > VERBOSE Show verbose output for Make rules. Default 1. Disable with 0."
	@echo "    > SANITIZER Compile with GCC sanitizer. Default none. Options: address, thread, etc."
	@echo "Targets:"
	@echo "  debug: Builds all with debug flags"
	@echo "  release: Build with optimiser"
	@echo "  test: Build test executable"
	@echo "Static analysers:"
	@echo "  cppcheck: Run cppcheck"
	@echo "  clang-tidy: TODO"
	@echo "  sloccount: TODO"
	@echo "  coverage: Calculate test coverage"
	@echo "  gcovr: Show coverage results"
	@echo "Helpers: "
	@echo "  bear: Generate compilation database for clang tooling"
	@echo "  format-dry: Dry run clang-format on all sources"

