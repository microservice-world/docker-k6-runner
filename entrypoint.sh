#!/bin/sh
set -e

# Default values
BASE_URL=${BASE_URL:-http://localhost:8080}
TEST_FILE=${TEST_FILE:-""}
TEST_FOLDER=${TEST_FOLDER:-""}

# Get timestamp for unique file names
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "🚀 K6 Load Testing Runner"
echo "🎯 Target: $BASE_URL"
echo "📁 Scripts: /scripts"
echo "📊 Reports: /reports"
echo "📄 Output: /output"
echo ""

# Function to run a single test
run_test() {
    local script_file="$1"
    local test_name=$(basename "$script_file" .js)
    
    echo "▶️  Running test: $test_name"
    echo "📁 Script: $script_file"
    
    # Set unique output file names
    local json_output="/output/${test_name}-${TIMESTAMP}.json"
    local html_output="/reports/${test_name}-${TIMESTAMP}.html"
    
    # Export BASE_URL for the test script
    export BASE_URL
    
    # Export K6 environment variables for web dashboard
    export K6_WEB_DASHBOARD=true
    export K6_WEB_DASHBOARD_PORT=5665
    export K6_WEB_DASHBOARD_HOST=0.0.0.0
    export K6_WEB_DASHBOARD_OPEN=false
    export K6_WEB_DASHBOARD_EXPORT="${html_output}"
    
    # Create enhanced script with HTML report generation
    local enhanced_script="/tmp/enhanced_${test_name}.js"
    
    # Read the original script
    local script_content=$(cat "$script_file")
    
    # Create enhanced script with HTML report generation
    cat > "$enhanced_script" << 'EOF'
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.1/index.js";

EOF
    
    # Append original script content
    echo "$script_content" >> "$enhanced_script"
    
    # Add handleSummary function if not already present
    if ! grep -q "export function handleSummary" "$enhanced_script"; then
        cat >> "$enhanced_script" << EOF

export function handleSummary(data) {
    return {
        "$html_output": htmlReport(data),
        stdout: textSummary(data, { indent: " ", enableColors: true }),
    };
}
EOF
    fi
    
    # Run K6 test with web dashboard and JSON output
    echo "🔥 Executing K6 test..."
    echo "🌐 Web Dashboard: http://localhost:5665"
    k6 run \
        --out json="$json_output" \
        "$enhanced_script"
    
    # Clean up temporary script
    rm -f "$enhanced_script"
    
    echo "✅ Test completed: $test_name"
    echo "📄 JSON: $json_output"
    echo "📈 HTML: $html_output"
    echo ""
}

# Discover and run tests
if [ -n "$TEST_FILE" ]; then
    # Run specific test file
    if [ -f "/scripts/$TEST_FILE" ]; then
        run_test "/scripts/$TEST_FILE"
    else
        echo "❌ Test file not found: $TEST_FILE"
        exit 1
    fi
elif [ -n "$TEST_FOLDER" ]; then
    # Run all tests in specific folder
    if [ -d "$TEST_FOLDER" ]; then
        for script in "$TEST_FOLDER"/*.js; do
            if [ -f "$script" ]; then
                run_test "$script"
            fi
        done
    else
        echo "❌ Test folder not found: $TEST_FOLDER"
        exit 1
    fi
else
    # Run all tests in /scripts
    found_tests=0
    for script in /scripts/*.js; do
        if [ -f "$script" ]; then
            run_test "$script"
            found_tests=1
        fi
    done
    
    if [ $found_tests -eq 0 ]; then
        echo "❌ No test files found in /scripts"
        echo "💡 Mount your test scripts to /scripts volume"
        echo "💡 Or set TEST_FILE environment variable"
        exit 1
    fi
fi

echo "🎉 All tests completed!"