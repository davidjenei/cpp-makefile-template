PROJECT = example
VERSION = 1.0.0

EXEC_DIR = $(BUILD_DIR)/exec
EXEC = $(EXEC_DIR)/$(PROJECT)

TEST_EXEC = $(EXEC_DIR)/tests
LIB = $(OBJ_DIR)/lib$(PROJECT).a

TAR = $(BUILD_DIR)/$(PROJECT).tar.gz

BUILD_DIR = build
DIST_DIR = .dist/$(PROJECT)-$(VERSION)

#################################################################################
# Compiler and linker settings
#################################################################################

# TODO: -D_GLIBCXX_ASSERTIONS
CXXFLAGS = -std=c++17
LDFLAGS =
INCLUDE = -Iinclude/

LIBPNG != pkg-config --libs libpng
LDFLAGS += $(LIBPNG)

#################################################################################
# Sources and objects
#################################################################################

SRC_DIRS = src src/submodule
SRC != find $(SRC_DIRS) -name '*.cpp' -or -name '*.c' -or -name '*.s'

TEST_DIR = tests
SRC_TESTS != find $(TEST_DIR) -name '*.cpp' -or -name '*.c' -or -name '*.s'

OBJ_DIR = $(BUILD_DIR)/objects
OBJ_DIRS = $(addprefix $(OBJ_DIR)/, $(sort $(dir $(SRC) $(SRC_TESTS))))

OBJ = $(SRC:%.cpp=$(OBJ_DIR)/%.o)
OBJ_TESTS = $(SRC_TESTS:%.cpp=$(OBJ_DIR)/%.o)
DEPS = $(OBJ:.o=.d)

.PHONY: all test
all: $(EXEC)
test: $(TEST_EXEC)

$(EXEC_DIR) $(OBJ_DIRS):
	$(MKDIR) $(@)

$(OBJ_DIR)/%.o: %.cpp $(BUILD_DIR)/.cxx_flags | $(OBJ_DIRS)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -c $< -MMD -o $@

$(EXEC): $(OBJ) | $(EXEC_DIR)
	$(CXX) $(CXXFLAGS) -o $(EXEC) $^ $(LDFLAGS)

$(LIB): $(filter-out $(OBJ_DIR)/src/main.o, $(OBJ))
	$(AR) rcs $(LIB) $^

$(TEST_EXEC): $(OBJ_TESTS) $(LIB) | $(EXEC_DIR)
	$(CXX) $(CXXFLAGS) -o $(TEST_EXEC) $(OBJ_TESTS) $(LDFLAGS) -L$(OBJ_DIR) -l$(PROJECT)

# Set a flag for a specific object
$(OBJ_DIR)/src/image.o: private CXXFLAGS += -Wall

.PHONY: force
build/.cxx_flags: force | $(EXEC_DIR)
	-@echo '$(CXXFLAGS)' | cmp -s - $@ || echo '$(CXXFLAGS)' > $@

-include $(DEPS)

.PHONY: harden debug release debug-tsan debug-asan
harden: CXXFLAGS += -D_GLIBCXX_ASSERTIONS
harden: debug

debug: CXXFLAGS += -DDEBUG -g3
debug: all

release: CXXFLAGS += -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-strong
release: all

debug-tsan: CXXFLAGS += -fsanitize=thread
debug-tsan: debug

debug-asan: CXXFLAGS += -fsanitize=address
debug-asan: debug

#################################################################################
# Tooling
#################################################################################
.PHONY: cppcheck tidy bear format-dry coverage gcovr count

CPPCHECK = cppcheck
BEAR = bear
CLANG_FORMAT = clang-format
CLANG_TIDY = clang-tidy
GCOVR = gcovr
INSTALL = install
COUNT = sloccount
MKDIR = @mkdir -p

CPPCHECKFLAGS += --enable=style,warning --cppcheck-build-dir=$(BUILD_DIR) --std=c++17
cppcheck: TOOLS += $(CPPCHECK)
cppcheck: tools
	$(CPPCHECK) $(CPPCHECKFLAGS) $(SRC) $(SRC_TESTS) $(INCLUDE)

tidy: TOOLS += $(CLANG_TIDY)
tidy: tools
	$(CLANG_TIDY) --extra-arg="$(CXXFLAGS)" --extra-arg="$(INCLUDE)" --system-headers $(SRC)

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

count: TOOLS += $(COUNT)
count: tools
	$(COUNT) src tests

#################################################################################
# Helpers
#################################################################################
.PHONY: clean tools print-% info-% help tar

clean:
	-@$(RM) -vr $(BUILD_DIR)

tools:
	@for i in $(TOOLS); do command -v $$i >/dev/null \
		|| (echo ERROR: Install $$i first >&2; exit 1); \
	done

print-%:
	@echo $* = $($*)

info-%:
	$(MAKE) --no-print-directory --dry-run --always-make $*

$(TAR).sha512: $(TAR)
	openssl dgst -sha512 -hex $(TAR) >$@

$(TAR): $(SRC) Makefile LICENSE.md
	$(MKDIR) $(@D)
	$(MKDIR) $(DIST_DIR)
	$(INSTALL) -m 0644 $(SRC) $(DIST_DIR)
	$(INSTALL) -m 0644 Makefile LICENSE.md $(DIST_DIR)
	tar zcf $@ $(DIST_DIR)
	$(RM) -rf $(DIST_DIR)

tar: tools $(TAR).sha512

help:
	@echo "usage: make [OPTIONS] <target>"
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
