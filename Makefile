# Makefile inspiration:
# https://github.com/azer/go-makefile-example/blob/master/Makefile
# https://sohlich.github.io/post/go_makefile/

VERSION := $(shell git describe --tags)
BUILD 	:= $(shell git rev-parse --short HEAD)
PROJECTNAME := $(shell basename "$(PWD)")
GOFILES := $(wildcard *.go)

BUILD_DIR := build

# Use linker flags to provide version/build settings
LDFLAGS := -ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD)"

# Redirect error output to a file, so we can show it in development mode.
STDERR := /tmp/.$(PROJECTNAME)-stderr.txt
# PID file will keep the process id of the server
PID := /tmp/.$(PROJECTNAME).pid

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR := $(dir $(MKFILE_PATH))

.PHONY: start-server stop-server go-build go-run go-test  ${BUILD_DIR}

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

go-build-amd64-linux: ${BUILD_DIR}
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o ${BUILD_DIR}/$(PROJECTNAME)-amd64-linux $(GOFILES)

go-run: go-build
	go run *.go

go-test: go-build
	go test ./...

build-docker-image: go-build-amd64-linux
	docker build -t microservice-example/accountservice ${MKFILE_DIR}

run-docker: build-docker-image
	docker run -p 127.0.0.1:6767:6767 --rm microservice-example/accountservice

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}
