# Compiler and Flags
CC = gcc
CFLAGS = -Wall -Wextra -O2 -Iinclude
LDFLAGS = -lcurl

# Directories
SRCDIR = src
INCDIR = include
BUILDDIR = build

# Source Files and Object Files
SRCS = $(wildcard $(SRCDIR)/*.c)
OBJS = $(SRCS:$(SRCDIR)/%.c=$(BUILDDIR)/%.o)
TARGET = $(BUILDDIR)/ixxler

# Default Target
all: $(TARGET)

# Build the Target Binary
$(TARGET): $(OBJS)
	@mkdir -p $(BUILDDIR)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)

# Compile Each Source File into Object Files
$(BUILDDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Clean the Build Directory
clean:
	rm -rf $(BUILDDIR)

# Run the Program
run: all
	./$(TARGET)

# Phony Targets
.PHONY: all clean run
