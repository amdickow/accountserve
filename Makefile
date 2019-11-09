VERSION := $(shell git describe --tags)
BUILD := $(shell git rev-parse --short HEAD)
PROJECTNAME := $(shell basename "$(PWD)")
GOFILES := $(wildcard *.go)

BUILD_DIR:=build

# Use linker flags to provide version/build settings
LDFLAGS=-ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD)"

# Redirect error output to a file, so we can show it in development mode.
STDERR := /tmp/.$(PROJECTNAME)-stderr.txt

# PID file will keep the process id of the server
PID := /tmp/.$(PROJECTNAME).pid

.PHONY: start-server stop-server go-build  ${BUILD_DIR}

all: go-build

start-server: stop-server
	@-$(BUILD_DIR)/$(PROJECTNAME) 2>&1 & echo $$! > $(PID)
	@cat $(PID) | sed "/^/s/^/  \>  PID: /"

stop-server:
	@-touch $(PID)
	@-kill `cat $(PID)` 2> /dev/null || true
	@-rm $(PID)

go-build: ${BUILD_DIR}
	go build $(LDFLAGS) -o ${BUILD_DIR}/$(PROJECTNAME) $(GOFILES)


${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}
