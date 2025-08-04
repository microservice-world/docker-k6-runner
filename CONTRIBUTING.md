# Contributing to K6 Runner

Thank you for your interest in contributing to K6 Runner! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible using our issue template.

**Good bug reports include:**
- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Environment details (OS, Docker version, etc.)
- Relevant logs or error messages
- Test scripts that demonstrate the issue

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- Use a clear and descriptive title
- Provide a detailed description of the proposed enhancement
- Explain why this enhancement would be useful
- Include examples of how the feature would work

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding standards** outlined below
3. **Write tests** for any new functionality
4. **Update documentation** as needed
5. **Ensure all tests pass** before submitting
6. **Submit a pull request** using our PR template

## Development Setup

### Prerequisites

- Docker 20.10 or later
- Docker Buildx (for multi-platform builds)
- Make (optional, for using Makefile commands)
- Go 1.21+ (for K6 extension development)

### Local Development

```bash
# Clone your fork
git clone https://github.com/your-username/k6-runner.git
cd k6-runner

# Create a feature branch
git checkout -b feature/your-feature-name

# Build the container locally
docker build -t k6-runner:dev .

# Run tests
make test

# Test your changes
docker run --rm k6-runner:dev help
```

### Testing

Before submitting a PR, ensure:

1. **Unit tests pass**: Test individual components
2. **Integration tests pass**: Test the complete workflow
3. **Smoke tests pass**: Basic functionality works
4. **Manual testing**: Your specific changes work as expected

Example test commands:
```bash
# Run all tests
make test

# Test specific functionality
docker run --rm -v "$(pwd)/examples:/scripts" k6-runner:dev run basic-load-test.js

# Test report generation
docker run --rm -v "$(pwd)/test-output:/output" -v "$(pwd)/test-reports:/reports" k6-runner:dev report test-results.json

# Test cleanup functionality
docker run --rm -v "$(pwd)/test-reports:/reports" k6-runner:dev cleanup stats
```

## Coding Standards

### Shell Scripts

- Use `#!/bin/sh` for POSIX compatibility (Alpine Linux)
- Use `set -e` for error handling
- Add meaningful comments for complex logic
- Keep functions small and focused
- Use descriptive variable names

Example:
```bash
#!/bin/sh
set -e

# Function to validate test script exists
validate_script() {
    local script_path="$1"
    
    if [ ! -f "$script_path" ]; then
        echo "Error: Test script not found: $script_path" >&2
        return 1
    fi
}
```

### K6 Scripts

- Follow K6 best practices
- Use meaningful test names and descriptions
- Include proper error handling
- Add comments for complex scenarios
- Use consistent formatting

Example:
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 20 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.1'],
  },
};

export default function() {
  const response = http.get(__ENV.BASE_URL || 'http://localhost:8080');
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  sleep(1);
}
```

### Dockerfile Best Practices

- Use specific base image versions
- Minimize layers
- Run as non-root user
- Use multi-stage builds when appropriate
- Add helpful labels

## Documentation

- Update README.md for user-facing changes
- Add inline documentation for complex code
- Include examples for new features
- Keep documentation concise and clear

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Test additions or modifications
- `chore:` Maintenance tasks

Examples:
```
feat: add support for custom K6 extensions
fix: resolve report generation for large datasets
docs: update integration examples for CI/CD
```

## Release Process

1. Ensure all tests pass
2. Update version in relevant files
3. Update CHANGELOG.md
4. Create a pull request
5. After merge, tag the release
6. GitHub Actions will build and publish the container

## Getting Help

- Check existing [issues](https://github.com/your-org/k6-runner/issues)
- Review [documentation](https://github.com/your-org/k6-runner/wiki)
- Join [discussions](https://github.com/your-org/k6-runner/discussions)
- Contact maintainers if needed

## Recognition

Contributors will be recognized in:
- The project's contributors list
- Release notes for significant contributions
- Special mentions for exceptional contributions

Thank you for contributing to K6 Runner! 🚀