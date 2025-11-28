#!/bin/bash

# Set variables
HELM_RELEASE="cluster-autoscaler"
HELM_CHART="autoscaler/cluster-autoscaler"
NAMESPACE="kube-system"
VALUES_FILE="values.yaml"

# Upgrade or install the Helm chart
helm upgrade --install "$HELM_RELEASE" "$HELM_CHART" -f "$VALUES_FILE" -n "$NAMESPACE"

# Check if the upgrade/install was successful
if [ $? -eq 0 ]; then
    echo "Helm upgrade/install successful!"
else
    echo "Helm upgrade/install failed! Check the errors above."
    exit 1
fi

