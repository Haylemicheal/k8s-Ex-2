#!/bin/bash

# Cleanup script to remove all Kubernetes resources
# Usage: ./cleanup.sh [PROJECT_ID] [ZONE]

set -e

PROJECT_ID=${1:-""}
ZONE=${2:-"us-central1-a"}
CLUSTER_NAME="temperature-converter-cluster"

echo "🧹 Cleaning up Kubernetes resources..."

# Delete namespace (this will delete all resources in the namespace)
kubectl delete namespace temperature-converter --ignore-not-found=true

echo "✅ Kubernetes resources deleted"

if [ -n "$PROJECT_ID" ]; then
    read -p "Do you want to delete the GKE cluster? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting GKE cluster..."
        gcloud container clusters delete $CLUSTER_NAME \
          --zone=$ZONE \
          --project=$PROJECT_ID \
          --quiet
        echo "✅ Cluster deleted"
    fi
fi

echo "✅ Cleanup complete!"

