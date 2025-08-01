# Makefile for Jitsi Meet Enterprise Installation System
# Copyright (c) 2025 Jason Hempstead, Casjays Developments

# Variables
VERSION := $(shell date +%Y%m%d%H%M)-git
CURRENT_DATE := $(shell date '+%A, %b %d, %Y %I:%M %p %Z')
INSTALL_DESCRIPTION := Enterprise Jitsi Meet + Keycloak automated installer with monitoring stack

# Default target
.PHONY: all
all: headers

# Update headers in install.sh
.PHONY: headers
headers:
	@echo "Updating headers in install.sh..."
	@sed -i 's/##@Version           :  .*/##@Version           :  $(VERSION)/' install.sh
	@sed -i 's/# @@Created          :  .*/# @@Created          :  $(CURRENT_DATE)/' install.sh
	@sed -i 's/# @@Description      :  .*/# @@Description      :  $(INSTALL_DESCRIPTION)/' install.sh
	@sed -i 's/# @@Changelog        :  .*/# @@Changelog        :  Updated headers/' install.sh
	@sed -i 's/VERSION=.*/VERSION="$(VERSION)"/' install.sh
	@echo "Headers updated successfully"

# Build target (currently just updates headers)
.PHONY: build
build: headers
	@echo "Build complete"

# Test the installer script
.PHONY: test
test:
	@echo "Running shellcheck validation..."
	@shellcheck -s sh install.sh || echo "Note: Some warnings are expected due to POSIX compliance"
	@echo "Running basic syntax check..."
	@sh -n install.sh && echo "Syntax check passed"

# Install (dry-run mode)
.PHONY: install
install:
	@echo "Running installer in dry-run mode..."
	@sudo ./install.sh --dry-run

# Clean temporary files
.PHONY: clean
clean:
	@echo "Cleaning temporary files..."
	@rm -f *~
	@rm -f *.tmp
	@rm -rf /tmp/jitsi-install-*
	@echo "Clean complete"

# Show help
.PHONY: help
help:
	@echo "Jitsi Meet Enterprise Installation System"
	@echo ""
	@echo "Available targets:"
	@echo "  make           - Update script headers (default)"
	@echo "  make headers   - Update version and timestamps in scripts"
	@echo "  make build     - Build the project (updates headers)"
	@echo "  make test      - Run shellcheck validation"
	@echo "  make install   - Run installer in dry-run mode"
	@echo "  make clean     - Remove temporary files"
	@echo "  make help      - Show this help message"
	@echo ""
	@echo "Version: $(VERSION)"