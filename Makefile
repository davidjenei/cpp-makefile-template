PROJECT = example
VERSION = 1.0.0

# TODO: -D_GLIBCXX_ASSERTIONS

.PHONY: all test debug release clean cppcheck bear help format-dry force tar require tools

#################################################################################
# Tooling
#################################################################################
CPPCHECK = cppcheck
BEAR = bear
CLANG_FORMAT = clang-format
CLANG_TIDY = clang-tidy
GCOVR = gcovr
PKG_CONFIG = pkg-config
INSTALL = install
COUNT = sloccount
MKDIR = mkdir -p

#################################################################################
# Artifacts
#################################################################################
EXEC = $(EXEC_DIR)/$(PROJECT)
EXEC_DIR = $(BUILD_DIR)/exec
BUILD_DIR = build

TEST_EXEC = $(EXEC_DIR)/tests
LIB = $(OBJ_DIR)/lib$(PROJECT).a

DIST_DIR = .dist/$(PROJECT)-$(VERSION)
TAR = $(BUILD_DIR)/$(PROJECT).tar.gz

#################################################################################
# Compiler and linker settings
#################################################################################

CXXFLAGS = -std=c++17
LDFLAGS =
INCLUDE = -Iinclude/

LIBPNG != $(PKG_CONFIG) --libs libpng # Use this instead of shell()
LDFLAGS += $(LIBPNG)
INCLUDE += -I/usr/include/png++

#################################################################################
# Sources and objects
#################################################################################

SRC = \
	$(wildcard src/submodule/*.cpp) \
	$(wildcard src/*.cpp)

OBJ_DIR = $(BUILD_DIR)/objects
OBJ_DIRS = $(addprefix $(OBJ_DIR)/, $(sort $(dir $(SRC))))

OBJ = $(SRC:%.cpp=$(OBJ_DIR)/%.o)
DEPS = $(OBJ:.o=.d)

SRC_TESTS = $(wildcard tests/*.cpp)
OBJ_TESTS = $(SRC_TESTS:%.cpp=$(OBJ_DIR)/%.o)

all: $(EXEC)
test: $(TEST_EXEC)

$(OBJ_DIR)/%.o: %.cpp $(BUILD_DIR)/.cxx_flags | $(OBJ_DIRS)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -c $< -MMD -o $@

$(EXEC_DIR) $(OBJ_DIRS):
	$(MKDIR) $(@)

$(EXEC): $(OBJ) | $(EXEC_DIR)
	$(CXX) $(CXXFLAGS) -o $(EXEC) $^ $(LDFLAGS)

$(LIB): $(filter-out $(OBJ_DIR)/src/main.o, $(OBJ))
	$(AR) rcs $(LIB) $^

$(TEST_EXEC): $(OBJ_TESTS) $(LIB) | $(EXEC_DIR)
	$(CXX) $(CXXFLAGS) -o $(TEST_EXEC) $(OBJ_TESTS) $(LDFLAGS) -L$(OBJ_DIR) -l$(PROJECT)

# Set a flag for a specific object
$(OBJ_DIR)/src/image.o: private CXXFLAGS += -Wall

-include $(DEPS)

harden: CXXFLAGS += -D_GLIBCXX_ASSERTIONS
harden: debug

debug: CXXFLAGS += -DDEBUG -g3
debug: all

release: CXXFLAGS += -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-strong
release: all

clean:
	-$(RM) -vr $(BUILD_DIR)

$(TAR).sha512: $(TAR)
	openssl dgst -sha512 -hex $(TAR) >$@

$(TAR):
	$(MKDIR) $(@D)
	$(MKDIR) $(DIST_DIR)
	$(INSTALL) -m 0644 $(SRC) $(DIST_DIR)
	$(INSTALL) -m 0644 Makefile LICENSE.md $(DIST_DIR)
	tar zcf $@ $(DIST_DIR)
	$(RM) -rf $(DIST_DIR)

# Note: Links dynamic by default. Use eg. -static-libasan if it's not desirable
debug-tsan: CXXFLAGS += -fsanitize=thread
debug-tsan: debug

debug-asan: CXXFLAGS += -fsanitize=address
debug-asan: debug

tools:
	@for i in $(TOOLS); do \
		command -v $$i >/dev/null \
			|| (echo ERROR: $$i not found in path >&2; exit 1); \
	done

CPPCHECKFLAGS += --enable=style,warning --cppcheck-build-dir=$(BUILD_DIR) --std=c++17

cppcheck: TOOLS += $(CPPCHECK)
cppcheck: tools
	$(CPPCHECK) $(CPPCHECKFLAGS) $(SRC) $(SRC_TESTS) $(INCLUDE)

tidy: TOOLS += $(CLANG_TIDY)
tidy: tools
	$(CLANG_TIDY) --extra-arg="$(CXXFLAGS)" -extra-arg=$(INCLUDE) $(SRC)

bear: TOOLS += $(BEAR)
bear: tools
	$(BEAR) -- $(MAKE) clean all test

format-dry: TOOLS += $(CLANG_FORMAT)
format-dry: tools
	@$(CLANG_FORMAT) --dry-run $(SRC) $(SRC_TESTS)

coverage: CXXFLAGS += -O0 --coverage -g
coverage: test

gcovr: TOOLS += $(GCOVR)
gcovr: tools coverage
	./$(TEST_EXEC)
	$(GCOVR) --object-directory=$(OBJ_DIR)

build/.cxx_flags: force | $(EXEC_DIR)
	-@echo '$(CXXFLAGS)' | cmp -s - $@ || echo '$(CXXFLAGS)' > $@

print-%:
	@echo $* = $($*)

info-%:
	$(MAKE) --no-print-directory --dry-run --always-make $*

tar: TOOLS += $(TAR)
tar: tools
	$(TAR) $(TAR).sha512

count: TOOLS += $(COUNT)
count: tools
	$(COUNT) src tests

help:
	@echo "usage: make [OPTIONS] <target>"
	@echo "  Options:"
	@echo "    > VERBOSE Show verbose output for Make rules. Default 1. Disable with 0."
	@echo "Targets:"
	@echo "  debug: Builds all with debug flags"
	@echo "  debug-tsan: Builds all with debug and threadsanitizer"
	@echo "  debug-asan: Builds all with debug and address-sanitizer"
	@echo "  release: Build with optimiser"
	@echo "  test: Build test executable"
	@echo "Static analysers:"
	@echo "  cppcheck: Run cppcheck"
	@echo "  tidy: Run clang-tidy"
	@echo "  count: Run sloccount"
	@echo "  coverage: Calculate test coverage"
	@echo "  gcovr: Show coverage results"
	@echo "Helpers: "
	@echo "  bear: Generate compilation database for clang tooling"
	@echo "  format-dry: Dry run clang-format on all sources"
	@echo "  print-%: Print value"
	@echo "  info-%: Print recipe"
	@echo "  tar: Package source files"

