#!/usr/bin/env bash
# Installs the platform tools on EKS, in order:
#   1. External Secrets  2. Prometheus + Grafana  3. Loki + Alloy  4. Argo CD + the shop app
# Run after: terraform apply  and  aws eks update-kubeconfig ...
set -euo pipefail
cd "$(dirname "$0")/.."

helm repo add argo https://argoproj.github.io/argo-helm
helm repo add external-secrets https://charts.external-secrets.io
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "==> 1/4 External Secrets Operator"
helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --wait --timeout 5m

echo "==> 2/4 Prometheus, Alertmanager and Grafana"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-$(openssl rand -hex 12)}"
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f monitoring/kube-prometheus-stack-values.yaml \
  --set grafana.adminPassword="$GRAFANA_PASSWORD" \
  --wait --timeout 10m

echo "==> 3/4 Loki (logs) and Alloy (log collector)"
helm upgrade --install loki grafana/loki -n monitoring -f monitoring/loki-values.yaml --wait --timeout 10m
helm upgrade --install alloy grafana/alloy -n monitoring -f monitoring/alloy-values.yaml --wait --timeout 5m
kubectl apply -f monitoring/dashboards/

echo "==> 4/4 Argo CD and the shop application"
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --wait --timeout 10m
kubectl apply -f gitops/argocd/shop-app.yaml

echo
echo "Grafana:  kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80   (user admin, password: $GRAFANA_PASSWORD)"
echo "Argo CD:  kubectl port-forward -n argocd svc/argocd-server 8081:443                       (user admin, password below)"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "App:      kubectl port-forward -n shop svc/frontend 8080:80"
