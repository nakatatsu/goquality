#!/bin/bash
set -euo pipefail

# Go Quality Tools Docker Build Script
# This script builds the Docker image locally and optionally pushes to GitHub Container Registry

# Configuration
REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAME="${IMAGE_NAME:-nakatatsu/goquality}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running or not installed"
        exit 1
    fi
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image: ${FULL_IMAGE}"
    
    if docker build -t "${FULL_IMAGE}" .; then
        print_status "Successfully built: ${FULL_IMAGE}"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to tag additional versions
tag_versions() {
    local go_version=$(docker run --rm "${FULL_IMAGE}" go version | awk '{print $3}' | sed 's/go//')
    local date_tag="${go_version}-$(date +%Y%m%d)"
    
    print_status "Tagging additional versions:"
    
    # Tag with Go version and date
    docker tag "${FULL_IMAGE}" "${REGISTRY}/${IMAGE_NAME}:${date_tag}"
    echo "  - ${REGISTRY}/${IMAGE_NAME}:${date_tag}"
    
    # If building latest, also tag without registry for local use
    if [ "${IMAGE_TAG}" = "latest" ]; then
        docker tag "${FULL_IMAGE}" "${IMAGE_NAME}:latest"
        echo "  - ${IMAGE_NAME}:latest (local)"
    fi
}

# Function to push to registry
push_image() {
    if [ "${PUSH:-false}" != "true" ]; then
        print_warning "Skipping push (set PUSH=true to push to registry)"
        return
    fi
    
    print_status "Pushing images to ${REGISTRY}"
    
    # Get all tags for this image
    local tags=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${REGISTRY}/${IMAGE_NAME}:")
    
    for tag in $tags; do
        print_status "Pushing ${tag}"
        if docker push "${tag}"; then
            echo "  ✓ Successfully pushed"
        else
            print_error "Failed to push ${tag}"
            exit 1
        fi
    done
}

# Function to verify image
verify_image() {
    print_status "Verifying Docker image"
    
    # Test basic functionality
    if docker run --rm "${FULL_IMAGE}" go version >/dev/null 2>&1; then
        echo "  ✓ Go version check passed"
    else
        print_error "Go version check failed"
        exit 1
    fi
    
    # List installed tools
    print_status "Installed tools:"
    docker run --rm "${FULL_IMAGE}" sh -c '
        for tool in gofumpt goimports staticcheck golangci-lint govulncheck gosec osv-scanner; do
            if command -v $tool >/dev/null 2>&1; then
                echo "  ✓ $tool: $(command -v $tool)"
            else
                echo "  ✗ $tool: not found"
            fi
        done
    '
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build Go Quality Tools Docker image

OPTIONS:
    -h, --help          Show this help message
    -p, --push          Push image to GitHub Container Registry
    -t, --tag TAG       Image tag (default: latest)
    -r, --registry REG  Registry URL (default: ghcr.io)
    -n, --name NAME     Image name (default: nakatatsu/goquality)
    -c, --clean         Remove dangling images after build

EXAMPLES:
    # Build local image
    $0

    # Build and push to registry
    $0 --push

    # Build with custom tag
    $0 --tag v1.0.0 --push

    # Clean build
    $0 --clean

ENVIRONMENT VARIABLES:
    REGISTRY      Registry URL (default: ghcr.io)
    IMAGE_NAME    Image name (default: nakatatsu/goquality)
    IMAGE_TAG     Image tag (default: latest)
    PUSH          Set to 'true' to push to registry

EOF
}

# Parse command line arguments
CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Update full image name with parsed values
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

# Main execution
main() {
    print_status "Go Quality Tools Docker Build Script"
    echo "Registry: ${REGISTRY}"
    echo "Image: ${IMAGE_NAME}"
    echo "Tag: ${IMAGE_TAG}"
    echo ""
    
    # Check Docker
    check_docker
    
    # Build image
    build_image
    
    # Tag additional versions
    tag_versions
    
    # Verify image
    verify_image
    
    # Push if requested
    push_image
    
    # Clean if requested
    if [ "${CLEAN}" = "true" ]; then
        print_status "Cleaning up dangling images"
        docker image prune -f
    fi
    
    print_status "Build complete!"
    echo ""
    echo "To use the image locally:"
    echo "  docker run --rm -v \$(pwd):/work ${FULL_IMAGE} make quality"
    echo ""
    echo "To use with Makefile:"
    echo "  make docker-quality"
}

# Run main function
main