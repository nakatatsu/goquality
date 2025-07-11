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
SKIP_FORMAT=${SKIP_FORMAT:-false}
SKIP_LINT=${SKIP_LINT:-false}
SKIP_TEST=${SKIP_TEST:-false}
SKIP_SECURITY=${SKIP_SECURITY:-false}
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
- Module health checks

OPTIONS:
    --skip-format          Skip code formatting checks
    --skip-lint            Skip static analysis
    --skip-test            Skip tests
    --skip-security        Skip security scans
    --coverage-threshold N Set coverage threshold (default: 80)
    --verbose              Enable verbose output
    --help                 Show this help message

ENVIRONMENT VARIABLES:
    COVERAGE_THRESHOLD     Coverage threshold percentage (default: 80)
    SKIP_FORMAT           Skip formatting if set to 'true'
    SKIP_LINT             Skip linting if set to 'true'
    SKIP_TEST             Skip testing if set to 'true'
    SKIP_SECURITY         Skip security if set to 'true'
    VERBOSE               Enable verbose output if set to 'true'

EXAMPLES:
    # Run all checks
    go-quality-check.sh
    
    # Skip security scans
    go-quality-check.sh --skip-security
    
    # Set coverage threshold to 90%
    go-quality-check.sh --coverage-threshold 90
    
    # Environment variable usage
    COVERAGE_THRESHOLD=90 SKIP_SECURITY=true go-quality-check.sh

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-format)
            SKIP_FORMAT=true
            shift
            ;;
        --skip-lint)
            SKIP_LINT=true
            shift
            ;;
        --skip-test)
            SKIP_TEST=true
            shift
            ;;
        --skip-security)
            SKIP_SECURITY=true
            shift
            ;;
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

# 1. Code formatting checks
if [ "$SKIP_FORMAT" != "true" ]; then
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
else
    log_info "Skipping format checks"
fi

# 2. Static analysis
if [ "$SKIP_LINT" != "true" ]; then
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
else
    log_info "Skipping static analysis"
fi

# 3. Module health
log_info "=== Module Health Checks ==="

# Check go.mod tidy
if ! run_command "go mod tidy -v" "go mod tidy"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Verify modules
if ! run_command "go mod verify" "go mod verify"; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 4. Tests and coverage
if [ "$SKIP_TEST" != "true" ]; then
    log_info "=== Tests and Coverage ==="
    
    # Run tests with coverage
    if run_command "go test -race -coverprofile=coverage.out -covermode=atomic ./..." "unit tests with coverage"; then
        # Check coverage threshold
        if [ -f "coverage.out" ]; then
            COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//')
            log_info "Coverage: ${COVERAGE}%"
            
            if (( $(echo "$COVERAGE < $COVERAGE_THRESHOLD" | bc -l) )); then
                log_error "Coverage ${COVERAGE}% is below threshold ${COVERAGE_THRESHOLD}%"
                FAILED_CHECKS=$((FAILED_CHECKS + 1))
            else
                log_success "Coverage ${COVERAGE}% meets threshold ${COVERAGE_THRESHOLD}%"
            fi
            
            # Generate HTML coverage report
            if run_command "go tool cover -html=coverage.out -o coverage.html" "coverage HTML report generation"; then
                log_info "Coverage report generated: coverage.html"
            fi
        else
            log_warning "No coverage data generated"
        fi
    else
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    
    # Run fuzz tests if they exist
    if go test -list 'Fuzz.*' ./... 2>/dev/null | grep -q Fuzz; then
        log_info "Found fuzz tests, running for 30 seconds..."
        if ! run_command "go test -fuzz=Fuzz -fuzztime=30s ./..." "fuzz tests"; then
            log_warning "Fuzz tests failed (non-blocking)"
        fi
    else
        log_info "No fuzz tests found"
    fi
else
    log_info "Skipping tests"
fi

# 5. Security scans
if [ "$SKIP_SECURITY" != "true" ]; then
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
else
    log_info "Skipping security scans"
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