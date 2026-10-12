#!/usr/bin/env bash
# Run BEFORE terraform destroy: removes anything Kubernetes created outside Terraform
# (e.g. load balancers), so the VPC can be deleted cleanly.
set -euo pipefail
kubectl delete application shop -n argocd --ignore-not-found
helm uninstall argocd -n argocd || true
helm uninstall alloy loki kube-prometheus-stack -n monitoring || true
helm uninstall external-secrets -n external-secrets || true
kubectl get svc -A | grep LoadBalancer || echo "No LoadBalancer services left."
