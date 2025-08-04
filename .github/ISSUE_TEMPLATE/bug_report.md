---
name: Bug report
about: Create a report to help us improve K6 Runner
title: '[BUG] '
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run command '...'
2. Mount volumes '...'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Actual behavior**
What actually happened instead.

**Test Script**
If applicable, provide the K6 test script that demonstrates the issue:
```javascript
// Your test script here
```

**Docker Command**
The exact Docker command you used:
```bash
docker run --rm \
  -v "$(pwd)/scripts:/scripts" \
  -v "$(pwd)/reports:/reports" \
  -e BASE_URL=http://example.com \
  k6-runner:latest run test.js
```

**Environment:**
 - OS: [e.g. Ubuntu 22.04, macOS 13, Windows 11]
 - Docker version: [e.g. 24.0.5]
 - K6 Runner version/tag: [e.g. latest, v1.2.3]
 - Architecture: [e.g. amd64, arm64]

**Logs**
Include any relevant error messages or logs:
```
// Paste logs here
```

**Additional context**
Add any other context about the problem here.

**Possible Solution**
If you have an idea of how to fix the issue, please describe it here.