#!/usr/bin/env bash
# Run the whole app on a free local Kubernetes cluster (kind).
# Needs: docker, kind, kubectl, helm.
set -euo pipefail
cd "$(dirname "$0")/.."

CLUSTER=shop-dev

if ! kind get clusters | grep -qx "$CLUSTER"; then
  kind create cluster --name "$CLUSTER"
fi

for svc in api worker frontend; do
  docker build -t "shop-$svc:dev" "apps/$svc"
  kind load docker-image "shop-$svc:dev" --name "$CLUSTER"
done

helm upgrade --install shop helm/shop -n shop --create-namespace --wait --timeout 5m

kubectl get pods -n shop
echo
echo "Open the app:  kubectl port-forward -n shop svc/frontend 8080:80   ->  http://localhost:8080"
