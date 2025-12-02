# Copyright 2024, Command Line Inc.
# SPDX-License-Identifier: Apache-2.0
#
# Makefile for building Wave Terminal for Mac (arm64) and Linux (amd64)

# Variables
VERSION := $(shell node version.cjs)
DATE := $(shell date +'%Y%m%d%H%M')
BIN_DIR := bin
DIST_DIR := dist
MAKE_DIR := make

# Go build flags
GO_LDFLAGS := -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)
GO_BUILD_TAGS := osusergo,sqlite_omit_load_extension

# Default target
.PHONY: all
all: build

# Help target
.PHONY: help
help:
	@echo "Wave Terminal Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  help              - Show this help message"
	@echo "  init              - Initialize project (install dependencies)"
	@echo "  build             - Build backend and frontend for current platform"
	@echo "  build-backend     - Build backend (wavesrv and wsh) for current platform"
	@echo "  build-server      - Build wavesrv for current platform"
	@echo "  build-wsh         - Build wsh for all platforms"
	@echo ""
	@echo "  Mac ARM64 targets:"
	@echo "  build-mac-arm64   - Build wavesrv for Mac ARM64"
	@echo "  build-wsh-mac-arm64 - Build wsh for Mac ARM64"
	@echo ""
	@echo "  Linux AMD64 targets:"
	@echo "  build-linux-amd64 - Build wavesrv for Linux AMD64"
	@echo "  build-wsh-linux-amd64 - Build wsh for Linux AMD64"
	@echo ""
	@echo "  dev               - Run development server"
	@echo "  package           - Package application for current platform"
	@echo "  clean             - Clean build artifacts"
	@echo "  test              - Run tests"
	@echo ""
	@echo "Current version: $(VERSION)"

# Initialize project
.PHONY: init
init: npm-install go-mod-tidy
	@echo "Project initialized successfully"

# NPM install
.PHONY: npm-install
npm-install:
	npm install

# Go mod tidy
.PHONY: go-mod-tidy
go-mod-tidy:
	go mod tidy

# Generate TypeScript bindings
.PHONY: generate
generate: build-schema
	go run cmd/generatets/main-generatets.go
	go run cmd/generatego/main-generatego.go

# Build schema
.PHONY: build-schema
build-schema:
	go run cmd/generateschema/main-generateschema.go
	rm -rf $(DIST_DIR)/schema
	mkdir -p $(DIST_DIR)/schema
	cp -r schema/* $(DIST_DIR)/schema/

# ============================================================================
# Backend Build Targets
# ============================================================================

# Build backend for current platform
.PHONY: build-backend
build-backend: build-server build-wsh

# Build server for current platform (detects OS and ARCH)
.PHONY: build-server
build-server: go-mod-tidy generate
	@echo "Building wavesrv for current platform..."
ifeq ($(shell uname -s),Darwin)
	$(MAKE) build-server-macos
else ifeq ($(shell uname -s),Linux)
	$(MAKE) build-server-linux
endif

# Build server for macOS (both arm64 and amd64)
.PHONY: build-server-macos
build-server-macos: build-mac-arm64 build-mac-amd64

# Build server for Linux (current architecture)
.PHONY: build-server-linux
build-server-linux:
ifeq ($(shell uname -m),x86_64)
	$(MAKE) build-linux-amd64
else ifeq ($(shell uname -m),aarch64)
	$(MAKE) build-linux-arm64
endif

# ============================================================================
# Mac ARM64 Targets
# ============================================================================

.PHONY: build-mac-arm64
build-mac-arm64: go-mod-tidy
	@echo "Building wavesrv for Mac ARM64..."
	@mkdir -p $(DIST_DIR)/bin
	CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 go build \
		-tags "$(GO_BUILD_TAGS)" \
		-ldflags "$(GO_LDFLAGS)" \
		-o $(DIST_DIR)/bin/wavesrv.arm64 \
		cmd/server/main-server.go

.PHONY: build-wsh-mac-arm64
build-wsh-mac-arm64: go-mod-tidy
	@echo "Building wsh for Mac ARM64..."
	@mkdir -p $(DIST_DIR)/bin
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-darwin.arm64 \
		cmd/wsh/main-wsh.go

.PHONY: build-mac-amd64
build-mac-amd64: go-mod-tidy
	@echo "Building wavesrv for Mac AMD64..."
	@mkdir -p $(DIST_DIR)/bin
	CGO_ENABLED=1 GOOS=darwin GOARCH=amd64 go build \
		-tags "$(GO_BUILD_TAGS)" \
		-ldflags "$(GO_LDFLAGS)" \
		-o $(DIST_DIR)/bin/wavesrv.x64 \
		cmd/server/main-server.go

.PHONY: build-wsh-mac-amd64
build-wsh-mac-amd64: go-mod-tidy
	@echo "Building wsh for Mac AMD64..."
	@mkdir -p $(DIST_DIR)/bin
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-darwin.x64 \
		cmd/wsh/main-wsh.go

# ============================================================================
# Linux AMD64 Targets
# ============================================================================

.PHONY: build-linux-amd64
build-linux-amd64: go-mod-tidy
	@echo "Building wavesrv for Linux AMD64..."
	@mkdir -p $(DIST_DIR)/bin
ifeq ($(shell command -v zig 2> /dev/null),)
	CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build \
		-tags "$(GO_BUILD_TAGS)" \
		-ldflags "$(GO_LDFLAGS)" \
		-o $(DIST_DIR)/bin/wavesrv.x64 \
		cmd/server/main-server.go
else
	CGO_ENABLED=1 GOOS=linux GOARCH=amd64 CC="zig cc -target x86_64-linux-gnu.2.28" go build \
		-tags "$(GO_BUILD_TAGS)" \
		-ldflags "$(GO_LDFLAGS)" \
		-o $(DIST_DIR)/bin/wavesrv.x64 \
		cmd/server/main-server.go
endif

.PHONY: build-wsh-linux-amd64
build-wsh-linux-amd64: go-mod-tidy
	@echo "Building wsh for Linux AMD64..."
	@mkdir -p $(DIST_DIR)/bin
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-linux.x64 \
		cmd/wsh/main-wsh.go

# Linux ARM64 targets (bonus)
.PHONY: build-linux-arm64
build-linux-arm64: go-mod-tidy
	@echo "Building wavesrv for Linux ARM64..."
	@mkdir -p $(DIST_DIR)/bin
ifeq ($(shell command -v zig 2> /dev/null),)
	CGO_ENABLED=1 GOOS=linux GOARCH=arm64 go build \
		-tags "$(GO_BUILD_TAGS)" \
		-ldflags "$(GO_LDFLAGS)" \
		-o $(DIST_DIR)/bin/wavesrv.arm64 \
		cmd/server/main-server.go
else
	CGO_ENABLED=1 GOOS=linux GOARCH=arm64 CC="zig cc -target aarch64-linux-gnu.2.28" go build \
		-tags "$(GO_BUILD_TAGS)" \
		-ldflags "$(GO_LDFLAGS)" \
		-o $(DIST_DIR)/bin/wavesrv.arm64 \
		cmd/server/main-server.go
endif

.PHONY: build-wsh-linux-arm64
build-wsh-linux-arm64: go-mod-tidy
	@echo "Building wsh for Linux ARM64..."
	@mkdir -p $(DIST_DIR)/bin
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-linux.arm64 \
		cmd/wsh/main-wsh.go

# ============================================================================
# Build wsh for all platforms
# ============================================================================

.PHONY: build-wsh
build-wsh: go-mod-tidy generate
	@echo "Building wsh for all platforms..."
	@mkdir -p $(DIST_DIR)/bin
	@rm -f $(DIST_DIR)/bin/wsh*
	# Darwin
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-darwin.arm64 \
		cmd/wsh/main-wsh.go
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-darwin.x64 \
		cmd/wsh/main-wsh.go
	# Linux
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-linux.arm64 \
		cmd/wsh/main-wsh.go
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-linux.x64 \
		cmd/wsh/main-wsh.go
	# Windows
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-windows.x64.exe \
		cmd/wsh/main-wsh.go
	CGO_ENABLED=0 GOOS=windows GOARCH=arm64 go build \
		-ldflags="-s -w -X main.BuildTime=$(DATE) -X main.WaveVersion=$(VERSION)" \
		-o $(DIST_DIR)/bin/wsh-$(VERSION)-windows.arm64.exe \
		cmd/wsh/main-wsh.go

# ============================================================================
# Frontend Build Targets
# ============================================================================

.PHONY: build-frontend
build-frontend: npm-install
	npm run build:prod

.PHONY: build-frontend-dev
build-frontend-dev: npm-install
	npm run build:dev

# ============================================================================
# Full Build
# ============================================================================

.PHONY: build
build: build-backend build-frontend
	@echo "Build completed for current platform"

# ============================================================================
# Development
# ============================================================================

.PHONY: dev
dev: npm-install build-backend
	npm run dev

.PHONY: start
start: npm-install build-backend
	npm run start

# ============================================================================
# Packaging
# ============================================================================

.PHONY: package
package: clean npm-install build-backend build-tsunamiscaffold
	npm run build:prod
	npm exec electron-builder -- -c electron-builder.config.cjs -p never

.PHONY: build-tsunamiscaffold
build-tsunamiscaffold:
	@echo "Building tsunami scaffold..."
	cd tsunami/frontend && npm run build
	rm -rf $(DIST_DIR)/tsunamiscaffold
	mkdir -p $(DIST_DIR)/tsunamiscaffold
	cp -r tsunami/frontend/scaffold/* $(DIST_DIR)/tsunamiscaffold/ 2>/dev/null || true
	cp -r tsunami/frontend/dist/* $(DIST_DIR)/tsunamiscaffold/ 2>/dev/null || true

# ============================================================================
# Testing
# ============================================================================

.PHONY: test
test:
	npm run test

.PHONY: test-coverage
test-coverage:
	npm run coverage

# ============================================================================
# Clean
# ============================================================================

.PHONY: clean
clean:
	rm -rf $(MAKE_DIR)
	rm -rf $(DIST_DIR)

.PHONY: clean-all
clean-all: clean
	rm -rf node_modules
	rm -rf docs/node_modules
	rm -rf tsunami/frontend/node_modules

# ============================================================================
# Version
# ============================================================================

.PHONY: version
version:
	@echo $(VERSION)
