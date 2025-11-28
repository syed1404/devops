#!/bin/bash

# Set variables
HELM_RELEASE="splunk-otel-collector"
HELM_CHART="splunk-otel-collector-chart/splunk-otel-collector"
NAMESPACE="default"

# Get absolute paths to avoid any issues
VALUES1="$(pwd)/values.yaml"
VALUES2="$(pwd)/values-splunk.yaml"

# Check if files exist
if [[ ! -f "$VALUES1" || ! -f "$VALUES2" ]]; then
    echo "Error: One or both values files not found!"
    exit 1
fi

# Print file paths for debugging
echo "Using values files:"
echo " - $VALUES1"
echo " - $VALUES2"

# Run Helm upgrade/install
helm upgrade --install "$HELM_RELEASE" "$HELM_CHART" -n "$NAMESPACE" \
    -f "$VALUES1" -f "$VALUES2"

# Verify if the deployment was successful
if [ $? -eq 0 ]; then
    echo "Helm upgrade/install successful!"
else
    echo "Helm upgrade/install failed! Check the errors above."
    exit 1
fi
