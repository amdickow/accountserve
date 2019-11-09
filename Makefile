
BUILD_DIR:=build

.PHONY: go-build

all: go-build

go-build: ${BUILD_DIR}
	go build -o ${BUILD_DIR} ./...


${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}
