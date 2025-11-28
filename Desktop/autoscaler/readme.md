# Cluster Autoscaler Deployment on AWS EKS Using Helm

This document is a step-by-step setup process followed to successfully deploy and configure the Kubernetes Cluster Autoscaler on an AWS EKS cluster using Helm.

---

## 1. Prerequisites

- An existing EKS Cluster.
- OIDC provider is enabled for the cluster.
- `kubectl` and `helm` installed.

---

## 2. IAM Role & Trust Relationship Setup

Create an IAM Role that the Cluster Autoscaler can assume:

### Trust Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::284762642143:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/6E5E900402A89EFE4E7390C4096C5725"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/6E5E900402A89EFE4E7390C4096C5725:sub": "system:serviceaccount:kube-system:cluster-autoscaler-aws-cluster-autoscaler"
        }
      }
    }
  ]
}
```

### IAM Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*"
    }
  ]
}
```

Attach this policy to the IAM Role.

---

## 4. Helm Chart Deployment

### Helm values.yaml
```yaml
autoDiscovery:
  clusterName: libr-test-cluster

awsRegion: us-east-1

cloudProvider: aws

rbac:
  create: true
  serviceAccount:
    create: true
    annotations: {
      eks.amazonaws.com/role-arn: arn:aws:iam::284762642143:role/ClusterAutoscalerRole
    }

extraArgs:
  cloud-provider: aws
  expander: least-waste
  aws-use-static-instance-list: "false"
  skip-nodes-with-local-storage: "false"
  skip-nodes-with-system-pods: "false"
  v: "4"

podAnnotations:
  cluster-autoscaler.kubernetes.io/safe-to-evict: "false"

resources:
  limits:
    cpu: 100m
    memory: 600Mi
  requests:
    cpu: 100m
    memory: 600Mi

```

### Deployment Script

Save the following script as `autoscaler-helm.sh` and run it after updating values files.

```bash
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
```

Deploy using Helm:
```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
./autoscaler-helm.sh
```

---

## 5. Verifying the Setup

Check if the pod is running:
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-cluster-autoscaler
```

Inspect logs:
```bash
kubectl logs -n kube-system <autoscaler-pod-name>
```
- Ensure no `AccessDenied` or `sts:AssumeRoleWithWebIdentity` errors occur.

---

## 6. Validation of Cluster Autoscaler (Optional)

#### Run the stress test to validate the instance autoscaling.
- Create an NGINX Deployment targeted to a specific Auto Scaling Group:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-scale-test
  namespace: default
spec:
  replicas: 10
  selector:
    matchLabels:
      app: nginx-scale-test
  template:
    metadata:
      labels:
        app: nginx-scale-test
    spec:
      nodeSelector:
        eks.amazonaws.com/nodegroup: node-group-us-east-1c-20250409151727593100000007
      containers:
      - name: nginx
        image: nginx:stable
        resources:
          requests:
            cpu: "800m"
            memory: "500Mi"
          limits:
            cpu: "1000m"
            memory: "800Mi"
```

## 7. Observing Auto-Scaling

- Use `kubectl get pods -w` to monitor Pending pods.

- Verify node scaling by using `kubectl top nodes`.

## 8. Clean Up

- Post the auto-scaling test the NGINX Deployment can be deleted.

```bash
kubectl delete deployment nginx-scale-test
```

