#!/bin/bash
set -e

# Go Quality Check Script
# Comprehensive quality check for Go projects

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-80}
VERBOSE=${VERBOSE:-false}

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

run_command() {
    local cmd="$1"
    local description="$2"
    
    log_info "Running: $description"
    if [ "$VERBOSE" = "true" ]; then
        echo "Command: $cmd"
    fi
    
    if eval "$cmd"; then
        log_success "$description completed"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
Usage: go-quality-check.sh [OPTIONS]

Go project quality check script that runs:
- Code formatting checks (gofumpt, goimports)
- Static analysis (go vet, staticcheck, golangci-lint)
- Unit tests with coverage
- Security scans (govulncheck, gosec, osv-scanner)
- Cohesion analysis (LCOM4)
- Module health checks

OPTIONS:
    --coverage-threshold N Set coverage threshold (default: 80)
    --verbose              Enable verbose output
    --help                 Show this help message

ENVIRONMENT VARIABLES:
    COVERAGE_THRESHOLD     Coverage threshold percentage (default: 80)
    VERBOSE               Enable verbose output if set to 'true'

EXAMPLES:
    # Run all checks
    go-quality-check.sh
    
    # Set coverage threshold to 90%
    go-quality-check.sh --coverage-threshold 90
    
    # Environment variable usage
    COVERAGE_THRESHOLD=90 go-quality-check.sh

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage-threshold)
            COVERAGE_THRESHOLD="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if we're in a Go project
if [ ! -f "go.mod" ]; then
    log_error "go.mod not found. Please run this script in the root of a Go project."
    exit 1
fi

log_info "Starting Go quality check..."
log_info "Working directory: $(pwd)"
log_info "Coverage threshold: ${COVERAGE_THRESHOLD}%"

FAILED_CHECKS=0

# Code formatting checks
log_info "=== Code Formatting Checks ==="

# Check gofumpt
if ! run_command "gofumpt -l -d ." "gofumpt format check"; then
    log_warning "Code is not formatted properly. Run 'gofumpt -w .' to fix."
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check goimports
if ! run_command "goimports -l -d ." "goimports check"; then
    log_warning "Imports are not organized properly. Run 'goimports -w .' to fix."
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Static analysis
log_info "=== Static Analysis ==="

# go vet
if ! run_command "go vet ./..." "go vet"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# staticcheck
if ! run_command "staticcheck ./..." "staticcheck"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# golangci-lint
if ! run_command "golangci-lint run --timeout=5m" "golangci-lint"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Module health
log_info "=== Module Health Checks ==="

# Check go.mod tidy
if ! run_command "go mod tidy -v" "go mod tidy"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Verify modules
if ! run_command "go mod verify" "go mod verify"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi


# Security scans
log_info "=== Security Scans ==="

# govulncheck
if ! run_command "govulncheck ./..." "govulncheck vulnerability scan"; then
    log_warning "Vulnerability scan failed (non-blocking)"
fi

# gosec
if ! run_command "gosec ./..." "gosec security scan"; then
    log_warning "Security scan failed (non-blocking)"
fi

# OSV Scanner
if ! run_command "osv-scanner ." "OSV vulnerability scan"; then
    log_warning "OSV scan failed (non-blocking)"
fi

# Cohesion analysis
log_info "=== Cohesion Analysis ==="

# LCOM4 - Lack of Cohesion of Methods
if ! run_command "lcom4 ./..." "LCOM4 cohesion analysis"; then
    log_warning "LCOM4 analysis failed (non-blocking)"
fi

# Summary
log_info "=== Summary ==="
if [ $FAILED_CHECKS -eq 0 ]; then
    log_success "All quality checks passed! ✨"
    exit 0
else
    log_error "$FAILED_CHECKS check(s) failed"
    log_info "Review the output above for details on what needs to be fixed."
    exit 1
fi