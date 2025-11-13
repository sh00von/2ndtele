#!/usr/bin/env python3
"""
Demo application exposing Prometheus metrics endpoint.
Generates mock metrics for CPU, memory, and response time.
"""

import time
import random
import threading
from flask import Flask, Response
from prometheus_client import Counter, Gauge, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Prometheus metrics
request_count = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration in seconds', ['method', 'endpoint'])
cpu_usage = Gauge('app_cpu_usage_percent', 'Application CPU usage percentage')
memory_usage = Gauge('app_memory_usage_bytes', 'Application memory usage in bytes')
response_time = Gauge('app_response_time_seconds', 'Application response time in seconds')
app_health = Gauge('app_health_status', 'Application health status (1=healthy, 0=unhealthy)')

# Simulate varying metrics
def update_metrics():
    """Update mock metrics periodically"""
    while True:
        # Simulate CPU usage (0-100%, occasionally spike above 70%)
        cpu_value = random.uniform(30, 85) if random.random() < 0.1 else random.uniform(20, 65)
        cpu_usage.set(cpu_value)
        
        # Simulate memory usage (100MB - 500MB)
        memory_value = random.uniform(100 * 1024 * 1024, 500 * 1024 * 1024)
        memory_usage.set(memory_value)
        
        # Simulate response time (10ms - 500ms)
        response_value = random.uniform(0.01, 0.5)
        response_time.set(response_value)
        
        # App is healthy 95% of the time
        health_value = 1 if random.random() < 0.95 else 0
        app_health.set(health_value)
        
        time.sleep(5)

# Start metrics update thread
metrics_thread = threading.Thread(target=update_metrics, daemon=True)
metrics_thread.start()

@app.route('/')
def index():
    """Root endpoint"""
    request_count.labels(method='GET', endpoint='/').inc()
    with request_duration.labels(method='GET', endpoint='/').time():
        time.sleep(random.uniform(0.01, 0.1))
    return 'Demo Application - Observability Stack\n\nEndpoints:\n- /metrics: Prometheus metrics\n- /health: Health check'

@app.route('/health')
def health():
    """Health check endpoint"""
    request_count.labels(method='GET', endpoint='/health').inc()
    with request_duration.labels(method='GET', endpoint='/health').time():
        # Check if app is healthy (simulated)
        current_health = app_health._value.get()
        if current_health == 1:
            return Response('OK', status=200, mimetype='text/plain')
        else:
            return Response('UNHEALTHY', status=503, mimetype='text/plain')

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    request_count.labels(method='GET', endpoint='/metrics').inc()
    with request_duration.labels(method='GET', endpoint='/metrics').time():
        return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)

