# Go parameters
GOCMD=$(shell which go)
GOCMD=/usr/local/go/bin/go

.PHONY: m5ops

SRC=m5ops.go
BIN=client

test: build
		$(GOCMD) test


_CGO_LDFLAGS="-g -O2 -no-pie"

$(BIN): main.go version.go m5lib
	CGO_LDFLAGS=$(_CGO_LDFLAGS) go build -o $@ -v .

all: $(BIN)

libclean:
	rm $(DIR)/*.o
	rm $(DIR)/*.a

clean: libclean
	go clean




## m5 ops library -------------------------
CC = gcc
CFLAGS = -g -fPIC
DIR = m5

CFILES  := $(wildcard $(DIR)/*.c)
SFILES := $(wildcard  $(DIR)/*.S)
OBJFILES := $(CFILES:.c=.o) $(SFILES:.S=.o)


%.o : %.S
		$(CC) -o $@ $< -c -g -fPIC

%.o : %.c
		$(CC) -o $@ $< -c -g -fPIC

m5ops: $(OBJFILES)
		ar rc -o $(DIR)/lib$@.a $^
		ranlib $(DIR)/lib$@.a

m5lib: m5ops
## ----------------------------------------
