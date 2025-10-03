#!/bin/bash

# Test script for Docker setup
# This script tests the Docker containerization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test 1: Check if Docker is available
test_docker_available() {
    print_status "Checking if Docker is available..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        return 1
    fi
    
    print_status "✓ Docker is available and running"
    return 0
}

# Test 2: Check if Docker Compose is available
test_docker_compose_available() {
    print_status "Checking if Docker Compose is available..."
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed or not in PATH"
        return 1
    fi
    
    print_status "✓ Docker Compose is available"
    return 0
}

# Test 3: Validate Dockerfile syntax
test_dockerfile_syntax() {
    print_status "Validating Dockerfile syntax..."
    if docker build --dry-run . &> /dev/null; then
        print_status "✓ Dockerfile syntax is valid"
        return 0
    else
        print_error "Dockerfile has syntax errors"
        return 1
    fi
}

# Test 4: Validate docker-compose.yml syntax
test_docker_compose_syntax() {
    print_status "Validating docker-compose.yml syntax..."
    if docker-compose config &> /dev/null; then
        print_status "✓ docker-compose.yml syntax is valid"
        return 0
    else
        print_error "docker-compose.yml has syntax errors"
        return 1
    fi
}

# Test 5: Check if required files exist
test_required_files() {
    print_status "Checking if required files exist..."
    
    local files=("Dockerfile" "docker-compose.yml" ".dockerignore" "package.json" "tsconfig.json")
    local missing_files=()
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        print_status "✓ All required files are present"
        return 0
    else
        print_error "Missing required files: ${missing_files[*]}"
        return 1
    fi
}

# Test 6: Check environment setup
test_environment_setup() {
    print_status "Checking environment setup..."
    
    if [ -f ".env" ]; then
        print_status "✓ .env file exists"
        
        # Check if INFURA_URL is set
        if grep -q "INFURA_URL=" .env && ! grep -q "YOUR_INFURA_PROJECT_ID" .env; then
            print_status "✓ INFURA_URL appears to be configured"
        else
            print_warning "INFURA_URL may not be properly configured in .env"
        fi
    else
        print_warning ".env file not found. You'll need to create it from docker.env.example"
    fi
    
    if [ -f "docker.env.example" ]; then
        print_status "✓ Environment template exists"
    else
        print_error "Environment template (docker.env.example) is missing"
        return 1
    fi
    
    return 0
}

# Test 7: Build test (without running)
test_build() {
    print_status "Testing Docker build process..."
    
    if docker build -t swap-optimizer-test . &> /dev/null; then
        print_status "✓ Docker image builds successfully"
        
        # Clean up test image
        docker rmi swap-optimizer-test &> /dev/null || true
        return 0
    else
        print_error "Docker build failed"
        return 1
    fi
}

# Run all tests
run_tests() {
    local failed_tests=0
    
    echo "Starting Docker setup tests..."
    echo "================================"
    
    test_docker_available || ((failed_tests++))
    test_docker_compose_available || ((failed_tests++))
    test_required_files || ((failed_tests++))
    test_dockerfile_syntax || ((failed_tests++))
    test_docker_compose_syntax || ((failed_tests++))
    test_environment_setup || ((failed_tests++))
    test_build || ((failed_tests++))
    
    echo "================================"
    
    if [ $failed_tests -eq 0 ]; then
        print_status "All tests passed! ✓"
        echo ""
        echo "Your Docker setup is ready. You can now run:"
        echo "  ./docker-run.sh up    # Start with Docker Compose"
        echo "  ./docker-run.sh logs  # View logs"
        echo "  ./docker-run.sh health # Check health"
        return 0
    else
        print_error "$failed_tests test(s) failed"
        echo ""
        echo "Please fix the issues above before running the application."
        return 1
    fi
}

# Main execution
if [ "${1:-test}" = "test" ]; then
    run_tests
else
    echo "Usage: $0 [test]"
    exit 1
fi

