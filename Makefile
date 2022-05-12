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
all: $(EXEC) $(TEST_EXEC)

$(OBJ_DIR)/%.o: %.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -c $< -MMD -o $@

$(EXEC): $(OBJ)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -o $(EXEC) $^ $(LDFLAGS)

$(LIB): $(filter-out $(OBJ_DIR)/src/main.o, $(OBJ))
	$(AR) rcs $(LIB) $^

$(TEST_EXEC): INCLUDE := $(INCLUDE) -I/usr/include/catch2
$(TEST_EXEC): $(OBJ_TESTS) $(LIB)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -o $(TEST_EXEC) $(OBJ_TESTS) $(LDFLAGS) -L$(OBJ_DIR) -l$(PROJECT)

-include $(DEPS)

.PHONY: debug
debug: CXXFLAGS += -DDEBUG -g
debug: all

.PHONY: release
release: CXXFLAGS += -O2
release: all

.PHONY : clean
clean:
	-@rm -rvf $(BUILD_DIR)

.PHONY : help
help :
	@echo "usage: make [OPTIONS] <target>"
	@echo "  Options:"
	@echo "    > VERBOSE Show verbose output for Make rules. Default 1. Disable with 0."
	@echo "Targets:"
	@echo "  debug: Builds all default targets ninja knows about"
	@echo "  release: Build and run unit test programs"
	@echo "Static analysis:"
	@echo "  TODO: cppcheck"
