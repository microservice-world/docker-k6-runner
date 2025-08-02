# K6 Runner - Professional Load Testing Container

A production-ready Docker container for running K6 load tests with comprehensive HTML reporting, designed for reuse across multiple projects.

## Features

- 🚀 **K6 with Extensions** - Built with popular xk6 extensions for enhanced functionality
- 📊 **Professional HTML Reports** - Automatic generation of detailed HTML reports
- 🔧 **Multi-Project Support** - Configurable for different applications and environments  
- 📈 **Multiple Output Formats** - JSON, HTML, CSV, and Prometheus outputs
- 🌐 **Web Dashboard** - Built-in K6 web dashboard support
- 🧹 **Cleanup Tools** - Automated cleanup of old reports and temporary files
- 🔒 **Security-First** - Runs as non-root user with minimal attack surface
- 📦 **Multi-Platform** - Supports both AMD64 and ARM64 architectures

## Quick Start

### Using Pre-built Container

```bash
# Pull the latest container
docker pull ghcr.io/your-org/k6-runner:latest

# Run a simple test
docker run --rm \
  -v "$(pwd)/scripts:/scripts" \
  -v "$(pwd)/reports:/reports" \
  -e BASE_URL=http://your-api.com \
  ghcr.io/your-org/k6-runner:latest run your-test.js
```

### Building Locally

```bash
# Clone the repository
git clone https://github.com/your-org/k6-runner.git
cd k6-runner

# Build the container
docker build -t k6-runner .

# Run a test
docker run --rm \
  -v "$(pwd)/examples:/scripts" \
  -v "$(pwd)/reports:/reports" \
  k6-runner run load-test.js
```

## Usage


### Basic Commands

```bash
# Show help
docker run --rm k6-runner help

# Run a specific test script
docker run --rm \
  -v "/path/to/scripts:/scripts" \
  -v "/path/to/reports:/reports" \
  -e BASE_URL=http://api.example.com \
  k6-runner run load-test.js

# Run predefined test types
docker run --rm \
  -v "/path/to/reports:/reports" \
  -e BASE_URL=http://api.example.com \
  k6-runner test load --vus 100 --duration 5m

# Generate report from existing JSON
docker run --rm \
  -v "/path/to/reports:/reports" \
  k6-runner report results.json

# Start web dashboard
docker run --rm -p 5665:5665 k6-runner dashboard
```

### Test Types

The container includes several predefined test types:

- **load** - Standard load testing with gradual ramp-up
- **spike** - Traffic spike testing with sudden load increases  
- **soak** - Long-duration testing for stability validation
- **stress** - High-stress testing to find breaking points
- **smoke** - Quick validation testing

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BASE_URL` | `http://localhost:8080` | Target application URL |
| `REPORTS_DIR` | `/reports` | HTML reports output directory |
| `OUTPUT_DIR` | `/output` | Raw K6 outputs directory |
| `PROJECT_NAME` | `k6-tests` | Project name for reports |
| `TEST_ENVIRONMENT` | `development` | Environment identifier |
| `MAX_REPORTS_AGE_DAYS` | `30` | Days to keep HTML reports |
| `MAX_OUTPUT_AGE_DAYS` | `7` | Days to keep raw outputs |

## Project Integration

### Method 1: Volume Mounting (Recommended)

Create a `docker-compose.yml` in your project:

```yaml
version: '3.8'
services:
  k6-tests:
    image: ghcr.io/your-org/k6-runner:latest
    volumes:
      - ./k6-tests:/scripts
      - ./k6-reports:/reports
    environment:
      - BASE_URL=http://your-api:8080
      - PROJECT_NAME=your-project
      - TEST_ENVIRONMENT=testing
    depends_on:
      - your-api
```

### Method 2: Dockerfile Extension

Create a `Dockerfile` in your project:

```dockerfile
FROM ghcr.io/your-org/k6-runner:latest

# Copy your test scripts
COPY k6-tests/ /scripts/

# Set project-specific environment
ENV PROJECT_NAME=your-project
ENV BASE_URL=http://your-api:8080

# Optional: Add project-specific configuration
COPY k6-config.json /config/
```

### Method 3: CI/CD Integration

GitHub Actions example:

```yaml
- name: Run Load Tests
  run: |
    docker run --rm \
      -v "${{ github.workspace }}/k6-tests:/scripts" \
      -v "${{ github.workspace }}/k6-reports:/reports" \
      -e BASE_URL=https://staging.yourapp.com \
      -e PROJECT_NAME=${{ github.repository }} \
      -e TEST_ENVIRONMENT=staging \
      ghcr.io/your-org/k6-runner:latest test load

- name: Upload Test Reports
  uses: actions/upload-artifact@v3
  if: always()
  with:
    name: k6-reports
    path: k6-reports/
```

## Configuration

### Batch Testing

Create a `batch-config.json` file:

```json
{
  "project": "my-api",
  "environment": "staging",
  "baseUrl": "https://staging-api.example.com",
  "tests": [
    {
      "name": "smoke-test",
      "script": "smoke.js",
      "tags": ["smoke", "quick"]
    },
    {
      "name": "load-test",
      "script": "load.js", 
      "tags": ["load", "performance"]
    }
  ]
}
```

Run batch tests:

```bash
docker run --rm \
  -v "$(pwd)/k6-tests:/scripts" \
  -v "$(pwd)/k6-reports:/reports" \
  -v "$(pwd)/config:/config" \
  k6-runner batch /config/batch-config.json
```

### Custom Thresholds

Add thresholds to your test scripts:

```javascript
export const options = {
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.1'],
    errors: ['rate<0.05'],
  },
};
```

## Report Management

### Automatic Cleanup

The container includes automatic cleanup tools:

```bash
# Clean old reports (30+ days by default)
docker run --rm -v "$(pwd)/reports:/reports" k6-runner cleanup reports

# Clean all artifacts older than 7 days
docker run --rm \
  -v "$(pwd)/reports:/reports" \
  -v "$(pwd)/output:/output" \
  k6-runner cleanup all --max-age 7

# Show disk usage statistics
docker run --rm -v "$(pwd)/reports:/reports" k6-runner cleanup stats
```

### Report Index

An `index.html` is automatically generated in the reports directory listing all available reports with timestamps and links.

## Development

### Building from Source

```bash
git clone https://github.com/your-org/k6-runner.git
cd k6-runner

# Build multi-platform image
docker buildx build --platform linux/amd64,linux/arm64 -t k6-runner .

# Build for local testing
docker build -t k6-runner .
```

### Testing

```bash
# Run the test suite
make test

# Test specific functionality
docker run --rm k6-runner version
docker run --rm k6-runner help
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Examples

The `examples/` directory contains sample test scripts:

- `load-test-comprehensive.js` - Comprehensive load testing
- `spike-test.js` - Traffic spike testing
- `soak-test.js` - Long-duration stability testing
- `api-test-suite.js` - Complete API test suite

## Troubleshooting

### Common Issues

**Container exits immediately:**
```bash
# Check if volume mounts exist
ls -la /path/to/scripts
ls -la /path/to/reports

# Verify script syntax
docker run --rm -v "$(pwd)/scripts:/scripts" k6-runner validate test.js
```

**No HTML reports generated:**
```bash
# Check if JSON output was created
ls -la reports/*.json

# Manually generate HTML report
docker run --rm -v "$(pwd)/reports:/reports" k6-runner report results.json
```

**Permission issues:**
```bash
# Fix ownership (Linux/macOS)
sudo chown -R $(id -u):$(id -g) reports/
```

### Debug Mode

Run with verbose output:

```bash
docker run --rm \
  -v "$(pwd)/scripts:/scripts" \
  -v "$(pwd)/reports:/reports" \
  -e BASE_URL=http://api.example.com \
  k6-runner run test.js --verbose
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](https://github.com/your-org/k6-runner/wiki)
- 🐛 [Issues](https://github.com/your-org/k6-runner/issues)
- 💬 [Discussions](https://github.com/your-org/k6-runner/discussions)

---

**K6 Runner** - Professional load testing made simple and reusable.