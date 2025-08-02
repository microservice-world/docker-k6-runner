import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

// Load test configuration
export const options = {
  stages: [
    { duration: '1m', target: 10 },   // Ramp up to 10 users
    { duration: '3m', target: 20 },   // Stay at 20 users
    { duration: '1m', target: 0 },    // Ramp down
  ],
  
  thresholds: {
    http_req_duration: ['p(95)<500'],     // 95% of requests under 500ms
    http_req_failed: ['rate<0.1'],        // Error rate under 10%
    errors: ['rate<0.05'],               // Custom error rate under 5%
    response_time: ['p(90)<300'],        // 90% of responses under 300ms
  },
};

export default function () {
  // Make HTTP request
  const response = http.get(`${__ENV.BASE_URL}/get`);
  
  // Record response time
  responseTime.add(response.timings.duration);
  
  // Validate response
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 300ms': (r) => r.timings.duration < 300,
    'has correct content-type': (r) => r.headers['Content-Type'].includes('application/json'),
    'body contains origin': (r) => r.body.includes('origin'),
  });
  
  // Record errors
  if (!success) {
    errorRate.add(1);
  }
  
  // Think time between requests
  sleep(Math.random() * 2 + 1); // 1-3 seconds
}

export function setup() {
  console.log('🚀 Starting Basic Load Test');
  console.log(`📍 Target: ${__ENV.BASE_URL}`);
  
  // Verify target is accessible
  const response = http.get(`${__ENV.BASE_URL}/get`);
  if (response.status !== 200) {
    throw new Error(`Target not accessible: ${response.status}`);
  }
  
  return { startTime: Date.now() };
}

export function teardown(data) {
  const duration = (Date.now() - data.startTime) / 1000;
  console.log(`\n✅ Basic Load Test completed in ${duration}s`);
}