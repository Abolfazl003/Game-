CC      ?= gcc
CXX     ?= g++
CFLAGS  := -std=c11 -O3 -Wall -Wextra -fPIC -Iinclude
CXXFLAGS:= -std=c++20 -O3 -Wall -Wextra -fPIC -Iinclude

BUILD_DIR := build
BIN_DIR   := bin

SHARED_LIB := $(BIN_DIR)/libnova_core.so
TEST_BIN   := $(BUILD_DIR)/test_native_core

C_SRCS   := src/colibri_tiered_runtime.c
CXX_SRCS := src/nova_blueprint.cpp src/nova_fracture.cpp src/gdextension_bridge.cpp

OBJS := $(BUILD_DIR)/colibri_tiered_runtime.o \
        $(BUILD_DIR)/nova_blueprint.o \
        $(BUILD_DIR)/nova_fracture.o \
        $(BUILD_DIR)/gdextension_bridge.o

.PHONY: all test clean

all: $(SHARED_LIB)

$(BUILD_DIR) $(BIN_DIR):
	mkdir -p $@

$(BUILD_DIR)/colibri_tiered_runtime.o: src/colibri_tiered_runtime.c include/colibri_tiered_runtime.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/nova_blueprint.o: src/nova_blueprint.cpp include/nova_blueprint.hpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/nova_fracture.o: src/nova_fracture.cpp include/nova_fracture.hpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/gdextension_bridge.o: src/gdextension_bridge.cpp include/colibri_tiered_runtime.h include/nova_blueprint.hpp include/nova_fracture.hpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(SHARED_LIB): $(OBJS) | $(BIN_DIR)
	$(CXX) -shared -o $@ $(OBJS) -lm

$(TEST_BIN): tests/test_native_core.cpp $(OBJS) | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) tests/test_native_core.cpp $(OBJS) -o $@ -lm

test: $(SHARED_LIB) $(TEST_BIN)
	./$(TEST_BIN)

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)
