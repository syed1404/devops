#!/bin/bash

# Set variables
HELM_RELEASE="splunk-otel-collector-test"
HELM_CHART="splunk-otel-collector-0.121.0\splunk-otel-collector"
VALUES_FILE="event-values.yaml"
NAMESPACE="default"

# Upgrade or install the Helm chart
helm upgrade --install "$HELM_RELEASE" "$HELM_CHART" -f "$VALUES_FILE" -n "$NAMESPACE"

# Check if the upgrade/install was successful
if [ $? -eq 0 ]; then
    echo "Helm upgrade/install successful!"
else
    echo "Helm upgrade/install failed! Check the errors above."
    exit 1
fi