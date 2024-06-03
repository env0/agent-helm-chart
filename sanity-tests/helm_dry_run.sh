#!/usr/bin/env bash

GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

info() {
    echo "$1"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

error() {
    echo -e "${RED}$1${NC}"
}

all_successful=true
failed_tests=()

for values_file in ./test-cases/*.yaml
do
    # Check if the file is a regular file
    if [ -f "$values_file" ]; then
        info "------------------------------------------------------------------------------------------------------"
        info "Running dry-run for values file: $values_file"
        info "------------------------------------------------------------------------------------------------------"

        helm install agent ../ --dry-run  -f "./default.values.yaml,$values_file"

        if [ $? -ne 0 ]; then
            error "Dry-run failed for values file: $values_file"
            all_successful=false
            failed_tests+=("$values_file")
        else
            success "Dry-run succeeded for values file: $values_file"
        fi

    fi
done

if ! $all_successful; then
    error "\n\n------------------------------------------------------------------------------------------------------"
    error "The following tests failed:"
    error "------------------------------------------------------------------------------------------------------"
    for failed_test in "${failed_tests[@]}"
    do
        error "$failed_test"
    done
    error "------------------------------------------------------------------------------------------------------"
    exit 1
else
    success "\n\n------------------------------------------------------------------------------------------------------"
    success "All tests passed successfully!"
    success "------------------------------------------------------------------------------------------------------"
    exit 0
fi
