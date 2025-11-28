# Deploy Splunk OpenTelemetry Collector via Helm with Custom Values

This guide explains how to deploy the Splunk OpenTelemetry Collector using Helm with customized configuration. The default chart only enables logging, so additional configuration is applied using a custom `values.yaml` file.

---

## Prerequisites

- Helm installed and configured
- Splunk HEC endpoint and token available
  - `values.yaml`: Base configuration
  - `values-splunk.yaml`: Splunk-specific configuration for metrics, traces, and log indexing

---

## Helm Chart Setup

### 1. Add the Splunk OTel Helm Repository

```bash
helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart

helm repo update
```

---

## Custom Values File

### `values.yaml`

The `values.yaml` file is based on the official [Splunk OpenTelemetry Collector Helm chart](https://github.com/signalfx/splunk-otel-collector-chart). By default, only **log collection** is enabled in the Splunk Platform section, and **logs are disabled** in the global telemetry configuration section. This configuration has been modified to enable full telemetry: **logs, metrics, and traces**.

```yaml
# Official Chart Reference Modifications

# Line ~161-163: General telemetry toggle section
metricsEnabled: true       # Already true (default)
tracesEnabled: true        # Already true (default)
logsEnabled: true          # Modified from false to true

# Line ~89–91
logsEnabled: true          # Already true by default
metricsEnabled: true       # Enabled to support metrics export to Splunk
tracesEnabled: true        # Enabled to support traces export to Splunk
```

> **Note:** Further customization (log configuration, daemonset settings, resource limits, etc) can be applied as needed.

### `values-splunk.yaml`

Contains overrides for Splunk HEC configuration, indexes, and cluster name:

```yaml
splunkPlatform:
  token: "<your-splunk-token>"
  endpoint: "https://splunk-hec.umd.edu:8088/services/collector"
  index: "svpaap_libr_dss_ssdr_k8_applogs"
  metricsIndex: "svpaap_libr_dss_ssdr_k8_metrics"
  tracesIndex: "svpaap_libr_dss_ssdr_k8_objects"
  insecureSkipVerify: false

clusterName: "libr-test-cluster"
logsEngine: "otel"
```

---

## Deployment Script

Save the following script as `deploy-splunk-otel.sh` and run it after updating both values files.

```bash
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
helm upgrade --install "$HELM_RELEASE" "$HELM_CHART" -n "$NAMESPACE"     -f "$VALUES1" -f "$VALUES2"

# Verify if the deployment was successful
if [ $? -eq 0 ]; then
    echo "Helm upgrade/install successful!"
else
    echo "Helm upgrade/install failed! Check the errors above."
    exit 1
fi
```

Make it executable and run:

```bash
./deploy-splunk-otel.sh
```

---

## Post Deployment

Check the status of the pods:

```bash
kubectl get pods -n default
```

Validate logs and telemetry ingestion in your Splunk instance.
