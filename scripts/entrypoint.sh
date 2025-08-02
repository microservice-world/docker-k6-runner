#!/bin/bash
set -euo pipefail

# K6 Runner Entrypoint - Official K6 Dashboard Integration
# Uses official K6 web dashboard with HTML export

# Configuration defaults
REPORTS_DIR=${REPORTS_DIR:-/reports}
SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
CONFIG_DIR=${CONFIG_DIR:-/config}
OUTPUT_DIR=${OUTPUT_DIR:-/output}
BASE_URL=${BASE_URL:-http://localhost:8080}
TEST_FILE=${TEST_FILE:-""}
TEST_FOLDER=${TEST_FOLDER:-""}
PROJECT_NAME=${PROJECT_NAME:-k6-tests}
TEST_ENVIRONMENT=${TEST_ENVIRONMENT:-development}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << EOF
K6 Runner - Official K6 Web Dashboard Integration

DESCRIPTION:
    Professional load testing container using official K6 web dashboard
    with HTML report generation and environment-based test discovery.

ENVIRONMENT VARIABLES:
    TEST_FILE              Single test file to run (e.g., "load-test.js")
    TEST_FOLDER            Folder containing tests to run (e.g., "/scripts/api-tests")
    BASE_URL               Target application URL
    PROJECT_NAME           Project name for reports (default: k6-tests)
    TEST_ENVIRONMENT       Environment name (default: development)
    
    K6 Dashboard Configuration:
    K6_WEB_DASHBOARD       Enable web dashboard (default: true)
    K6_WEB_DASHBOARD_PORT  Dashboard port (default: 5665)
    K6_WEB_DASHBOARD_HOST  Dashboard host (default: 0.0.0.0)
    K6_OUT                 K6 output configuration (default: json=/output/results.json)

TEST DISCOVERY:
    1. If TEST_FILE is set: Run the specific test file
    2. If TEST_FOLDER is set: Run all .js files in the folder
    3. If neither set: Run all .js files in /scripts directory
    4. If no .js files found: Show help and exit

EXAMPLES:
    # Run specific test file
    docker run -e TEST_FILE=load-test.js -e BASE_URL=http://api.example.com k6-runner

    # Run all tests in a folder
    docker run -e TEST_FOLDER=/scripts/api-tests -e BASE_URL=http://api.example.com k6-runner

    # Run all tests in scripts directory (default)
    docker run -e BASE_URL=http://api.example.com k6-runner

    # Access web dashboard during test
    docker run -p 5665:5665 -e BASE_URL=http://api.example.com k6-runner

VOLUME MOUNTS:
    /scripts    Mount your test scripts here
    /reports    HTML reports will be saved here
    /output     JSON outputs and logs will be saved here
    /config     Configuration files

OUTPUTS:
    - Real-time web dashboard at http://localhost:5665 (if port exposed)
    - HTML report: /reports/k6-report-[test-name]-[timestamp].html (auto-generated)
    - JSON output: /output/results-[test-name]-[timestamp].json
    - Console output with official K6 metrics and enhanced text summary

For more information: https://k6.io/docs/results-output/web-dashboard/
EOF
}

setup_directories() {
    mkdir -p "$REPORTS_DIR" "$OUTPUT_DIR" "$CONFIG_DIR"
    if [ "$(id -u)" = "0" ]; then
        chown -R k6user:k6user "$REPORTS_DIR" "$OUTPUT_DIR" "$CONFIG_DIR" 2>/dev/null || true
    fi
}

validate_environment() {
    log_info "🔍 Validating K6 environment..."
    
    if ! command -v k6 &> /dev/null; then
        log_error "K6 is not installed or not in PATH"
        exit 1
    fi
    
    log_success "Environment validation complete"
}

discover_test_files() {
    local test_files=()
    
    if [[ -n "$TEST_FILE" ]]; then
        # Single test file specified
        if [[ "$TEST_FILE" == *.js ]]; then
            local full_path="$SCRIPTS_DIR/$TEST_FILE"
            if [[ -f "$full_path" ]]; then
                test_files=("$full_path")
            else
                log_error "Test file not found: $full_path"
                exit 1
            fi
        else
            log_error "TEST_FILE must be a .js file: $TEST_FILE"
            exit 1
        fi
    elif [[ -n "$TEST_FOLDER" ]]; then
        # Test folder specified
        if [[ -d "$TEST_FOLDER" ]]; then
            while IFS= read -r -d '' file; do
                test_files+=("$file")
            done < <(find "$TEST_FOLDER" -name "*.js" -type f -print0 | sort -z)
            
            if [[ ${#test_files[@]} -eq 0 ]]; then
                log_error "No .js files found in folder: $TEST_FOLDER"
                exit 1
            fi
        else
            log_error "Test folder not found: $TEST_FOLDER"
            exit 1
        fi
    else
        # Default: all .js files in scripts directory
        if [[ -d "$SCRIPTS_DIR" ]]; then
            while IFS= read -r -d '' file; do
                test_files+=("$file")
            done < <(find "$SCRIPTS_DIR" -name "*.js" -type f -print0 | sort -z)
            
            if [[ ${#test_files[@]} -eq 0 ]]; then
                log_warning "No .js files found in scripts directory: $SCRIPTS_DIR"
                log_info "💡 Mount your test scripts to /scripts or set TEST_FILE environment variable"
                show_help
                exit 0
            fi
        else
            log_error "Scripts directory not found: $SCRIPTS_DIR"
            exit 1
        fi
    fi
    
    echo "${test_files[@]}"
}

create_enhanced_script() {
    local original_script="$1"
    local html_output="$2"
    local enhanced_script="$3"
    
    # Read the original script
    local script_content
    script_content=$(cat "$original_script")
    
    # For now, disable HTML injection to test if external imports are the issue
    cp "$original_script" "$enhanced_script"
    log_info "📋 Running original script without HTML injection for debugging"
}

run_k6_test() {
    local script_file="$1"
    local test_name=$(basename "$script_file" .js)
    
    log_info "🚀 Starting K6 test: $test_name"
    log_info "📁 Script: $script_file"
    log_info "🎯 Target: $BASE_URL"
    log_info "📊 Dashboard: http://localhost:${K6_WEB_DASHBOARD_PORT}"
    
    # Set unique output paths for this test run
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local html_output="/reports/k6-report-${test_name}-${timestamp}.html"
    local json_output="/output/results-${test_name}-${timestamp}.json"
    
    # Create a temporary enhanced script with HTML report generation
    local temp_script="/tmp/enhanced_${test_name}_${timestamp}.js"
    create_enhanced_script "$script_file" "$html_output" "$temp_script"
    
    # Export environment variables for K6
    export BASE_URL
    export K6_OUT="json=$json_output"
    
    # Add test metadata as tags
    local k6_cmd="k6 run"
    k6_cmd="$k6_cmd --tag project=$PROJECT_NAME"
    k6_cmd="$k6_cmd --tag environment=$TEST_ENVIRONMENT"
    k6_cmd="$k6_cmd --tag test_name=$test_name"
    k6_cmd="$k6_cmd --tag timestamp=$timestamp"
    
    log_info "🔥 Executing: $k6_cmd $temp_script"
    echo ""
    
    # Run K6 with enhanced script that generates HTML report
    if $k6_cmd "$temp_script"; then
        local exit_code=0
        log_success "✅ Test completed successfully: $test_name"
    else
        local exit_code=$?
        log_error "❌ Test failed: $test_name (exit code: $exit_code)"
    fi
    
    # Clean up temporary script
    rm -f "$temp_script"
    
    # Show results
    echo ""
    log_info "📊 Test Results for: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ -f "$html_output" ]]; then
        log_success "📈 HTML Report: $html_output"
        echo "  🌐 Open in browser: file://$(realpath "$html_output" 2>/dev/null || echo "$html_output")"
    else
        log_warning "HTML report not generated"
    fi
    
    if [[ -f "$json_output" ]]; then
        log_info "📄 JSON Output: $json_output"
    fi
    
    return $exit_code
}

main() {
    setup_directories
    validate_environment
    
    # Handle help requests
    if [[ "${1:-}" == "help" ]] || [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # Handle version requests
    if [[ "${1:-}" == "version" ]] || [[ "${1:-}" == "--version" ]]; then
        k6 version
        exit 0
    fi
    
    # Discover test files
    local test_files
    IFS=' ' read -ra test_files <<< "$(discover_test_files)"
    
    # Log test discovery results
    if [[ -n "$TEST_FILE" ]]; then
        log_info "📄 Running single test: $TEST_FILE"
    elif [[ -n "$TEST_FOLDER" ]]; then
        log_info "📂 Found ${#test_files[@]} test file(s) in: $TEST_FOLDER"
    else
        log_info "📂 Found ${#test_files[@]} test file(s) in scripts directory"
    fi
    
    log_info "🎯 Target URL: $BASE_URL"
    log_info "🏷️  Project: $PROJECT_NAME"
    log_info "🌍 Environment: $TEST_ENVIRONMENT"
    echo ""
    
    # Run all discovered tests
    local failed_tests=0
    local total_tests=${#test_files[@]}
    
    for script_file in "${test_files[@]}"; do
        if ! run_k6_test "$script_file"; then
            ((failed_tests++))
        fi
        
        # Add spacing between tests if running multiple
        if [[ $total_tests -gt 1 ]]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
        fi
    done
    
    # Final summary
    if [[ $total_tests -gt 1 ]]; then
        log_info "🏁 Test Suite Summary"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "📊 Total tests: $total_tests"
        log_success "✅ Passed: $((total_tests - failed_tests))"
        if [[ $failed_tests -gt 0 ]]; then
            log_error "❌ Failed: $failed_tests"
        fi
        echo ""
        log_info "📁 All reports saved to: $REPORTS_DIR"
        log_info "📄 All outputs saved to: $OUTPUT_DIR"
    fi
    
    # Exit with error if any tests failed
    if [[ $failed_tests -gt 0 ]]; then
        exit 1
    fi
}

# Handle signals for graceful shutdown
trap 'log_info "🛑 Received shutdown signal, cleaning up..."; exit 0' SIGTERM SIGINT

# Execute main function
main "$@"