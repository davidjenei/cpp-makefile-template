VERBOSE ?= 1

ifeq ($(VERBOSE),1)
	export Q :=
export VERBOSE := 1
else
	export Q := @
export VERBOSE := 0
endif

CXXFLAGS = -std=c++17 -Wall
LDFLAGS =

BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/objects
EXEC_DIR = $(BUILD_DIR)/exec

PROJECT = app
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

.PHONY: all
all: $(EXEC)

.PHONY: test
test: $(TEST_EXEC)

$(OBJ_DIR)/%.o: %.cpp
	@mkdir -p $(@D)
	$(Q) $(CXX) $(CXXFLAGS) $(INCLUDE) -c $< -MMD -o $@

$(EXEC): $(OBJ)
	@mkdir -p $(@D)
	$(Q) $(CXX) $(CXXFLAGS) -o $(EXEC) $^ $(LDFLAGS)

$(LIB): $(filter-out $(OBJ_DIR)/src/main.o, $(OBJ))
	$(Q) $(AR) rcs $(LIB) $^

$(TEST_EXEC): INCLUDE := $(INCLUDE) -I/usr/include/catch2
$(TEST_EXEC): $(OBJ_TESTS) $(LIB)
	@mkdir -p $(@D)
	$(Q) $(CXX) $(CXXFLAGS) -o $(TEST_EXEC) $(OBJ_TESTS) $(LDFLAGS) -L$(OBJ_DIR) -l$(PROJECT)

-include $(DEPS)

.PHONY: debug
debug: CXXFLAGS += -DDEBUG -g
debug: all

.PHONY: release
release: CXXFLAGS += -O2
release: all

.PHONY: clean
clean:
	-@rm -rvf $(BUILD_DIR)

CPPCHECK := cppcheck
CPPCHECKFLAGS += --enable=style,warning --cppcheck-build-dir=$(BUILD_DIR) --std=c++17
.PHONY: cppcheck
cppcheck:
	$(Q) $(CPPCHECK) $(CPPCHECKFLAGS) $(SRC) $(SRC_TESTS) $(INCLUDE)

# Note: Links dynamic by default. Use eg. -static-libasan if it's not desirable.
SANITIZER ?= none
ifneq ($(SANITIZER),none)
	CXXFLAGS += -fsanitize=$(SANITIZER)
endif

.PHONY: help
help:
	@echo "usage: make [OPTIONS] <target>"
	@echo "  Options:"
	@echo "    > VERBOSE Show verbose output for Make rules. Default 1. Disable with 0."
	@echo "    > SANITIZER Compile with GCC sanitizer. Default none. Options: address, thread, etc."
	@echo "Targets:"
	@echo "  debug: Builds all with debug flags"
	@echo "  release: Build with optimiser"
	@echo "Static analysers:"
	@echo "  cppcheck: Runs cppcheck"
	@echo "  clang-analyser: TODO"
	@echo "  clang-tidy: TODO"
	@echo "  sloccount: TODO"

