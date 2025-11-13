#!/bin/bash

# Alert Dispatcher Script
# Fetches alerts from Prometheus API and logs them locally
# Usage: ./alert_dispatcher.sh [prometheus_url] [log_file]

set -euo pipefail

# Default values
PROMETHEUS_URL="${1:-http://localhost:9090}"
LOG_FILE="${2:-alerts.log}"
ALERTS_API="${PROMETHEUS_URL}/api/v1/alerts"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to log alerts
log_alert() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local alert_name="$1"
    local severity="$2"
    local state="$3"
    local value="$4"
    local description="$5"
    
    # Format log entry
    local log_entry="[${timestamp}] ALERT: ${alert_name} | SEVERITY: ${severity} | STATE: ${state} | VALUE: ${value} | DESC: ${description}"
    
    # Write to log file
    echo "${log_entry}" >> "${LOG_FILE}"
    
    # Print to console with color coding
    if [ "${severity}" = "critical" ]; then
        echo -e "${RED}${log_entry}${NC}"
    elif [ "${severity}" = "warning" ]; then
        echo -e "${YELLOW}${log_entry}${NC}"
    else
        echo -e "${GREEN}${log_entry}${NC}"
    fi
}

# Function to fetch and process alerts
fetch_alerts() {
    echo "Fetching alerts from ${ALERTS_API}..."
    
    # Check if Prometheus is accessible
    if ! curl -s -f "${PROMETHEUS_URL}/api/v1/status/config" > /dev/null; then
        echo "ERROR: Cannot connect to Prometheus at ${PROMETHEUS_URL}"
        echo "Make sure Prometheus is running and accessible."
        exit 1
    fi
    
    # Fetch alerts from Prometheus API
    local response=$(curl -s "${ALERTS_API}" 2>/dev/null)
    
    if [ -z "${response}" ]; then
        echo "ERROR: Failed to fetch alerts from Prometheus API"
        exit 1
    fi
    
    # Check if response is valid JSON
    if ! echo "${response}" | jq empty 2>/dev/null; then
        echo "ERROR: Invalid JSON response from Prometheus API"
        echo "Response: ${response}"
        exit 1
    fi
    
    # Parse alerts using jq
    local alert_count=$(echo "${response}" | jq '.data.alerts | length')
    
    if [ "${alert_count}" -eq 0 ]; then
        echo "No active alerts found."
        return 0
    fi
    
    echo "Found ${alert_count} active alert(s):"
    echo "----------------------------------------"
    
    # Process each alert
    echo "${response}" | jq -r '.data.alerts[] | 
        "\(.labels.alertname // "unknown")|\(.labels.severity // "unknown")|\(.state)|\(.activeAt // "N/A")|\(.annotations.description // .annotations.summary // "No description")|\(.value // "N/A")"' | \
    while IFS='|' read -r alert_name severity state active_at description value; do
        log_alert "${alert_name}" "${severity}" "${state}" "${value}" "${description}"
    done
    
    echo "----------------------------------------"
    echo "Alerts logged to ${LOG_FILE}"
}

# Main execution
main() {
    echo "=========================================="
    echo "Prometheus Alert Dispatcher"
    echo "=========================================="
    echo "Prometheus URL: ${PROMETHEUS_URL}"
    echo "Log File: ${LOG_FILE}"
    echo "=========================================="
    echo ""
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "ERROR: jq is required but not installed."
        echo "Please install jq: https://stedolan.github.io/jq/download/"
        exit 1
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "ERROR: curl is required but not installed."
        exit 1
    fi
    
    # Create log file if it doesn't exist
    touch "${LOG_FILE}"
    
    # Fetch and log alerts
    fetch_alerts
    
    echo ""
    echo "Done!"
}

# Run main function
main

