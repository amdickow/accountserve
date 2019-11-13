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

.PHONY: start-server stop-server go-build go-run go-test run-docker create-docker-network deploy-dc undeploy-dc create-k8s-deployment deploy-k8s undeploy-k8s ${BUILD_DIR}

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
	docker build -t localhost:5000/microservice-example/accountservice ${MKFILE_DIR}

release-docker-image: build-docker-image
	docker push localhost:5000/microservice-example/accountservice

run-docker: build-docker-image
	docker run -p 127.0.0.1:6767:6767 --rm localhost:5000/microservice-example/accountservice

create-docker-network:
	docker network create microservice-example-network

deploy-dc: create-docker-network
	docker-compose -f deployment/docker-compose/docker-compose.yml up -d

undeploy-dc:
	docker-compose -f deployment/docker-compose/docker-compose.yml stop

create-k8s-deployment:
	kubectl create -f deployment/k8s_minikube/accountservice.yaml

deploy-k8s: create-k8s-deployment
	@$(eval EXTERNAL_IP:=$(shell ./scripts/check_and_wait_for_deployment_external_ip.sh accountservice-service))
	echo "Deployment is available on: ${EXTERNAL_IP}"

undeploy-k8s:
	kubectl delete -f deployment/k8s_minikube/accountservice.yaml

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}
