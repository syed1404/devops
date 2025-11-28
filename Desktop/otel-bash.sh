#!/bin/bash

# Set variables
NAMESPACE="default"
RELEASE_NAME="otel-collector"
CHART_NAME="open-telemetry/opentelemetry-collector"
VALUES_FILE="values.yaml"

# Helm upgrade/install command
helm upgrade --install $RELEASE_NAME $CHART_NAME -f $VALUES_FILE -n $NAMESPACE

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Helm chart successfully installed/upgraded."
else
    echo "Helm install/upgrade failed!"
    exit 1
fi
