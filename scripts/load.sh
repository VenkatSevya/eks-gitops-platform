#!/usr/bin/env bash
# Send steady traffic to the API from inside the cluster. Stop with Ctrl+C.
set -euo pipefail
kubectl run loadgen -n shop --rm -i --restart=Never --image=curlimages/curl:8.11.1 -- \
  sh -c 'i=0; while true; do
           curl -s -o /dev/null -w "%{http_code} " http://api:8000/orders
           curl -s -o /dev/null -X POST -H "Content-Type: application/json" \
                -d "{\"item\":\"widget-$i\",\"quantity\":1}" http://api:8000/orders
           i=$((i+1)); sleep 0.3
         done'
