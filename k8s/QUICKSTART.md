# Quick Start Guide - GKE Deployment

## Prerequisites Checklist

- [ ] Google Cloud account with billing enabled
- [ ] `gcloud` CLI installed and authenticated
- [ ] `kubectl` installed
- [ ] `docker` installed
- [ ] GCP project ID ready

## Quick Deployment (Automated)

```bash
cd k8s
./deploy.sh YOUR_PROJECT_ID us-central1 us-central1-a
```

This script will:
1. Enable required GCP APIs
2. Build and push Docker images to GCR
3. Create GKE cluster (if it doesn't exist)
4. Deploy all Kubernetes resources
5. Show you the service information

## Manual Deployment Steps

### 1. Set Variables
```bash
export PROJECT_ID=your-project-id
export REGION=us-central1
export ZONE=us-central1-a
```

### 2. Build and Push Images

**Backend:**
```bash
cd backend
docker build -t gcr.io/$PROJECT_ID/temperature-converter-backend:latest .
gcloud auth configure-docker
docker push gcr.io/$PROJECT_ID/temperature-converter-backend:latest
```

**Frontend:**
```bash
cd ../my-calc
docker build -t gcr.io/$PROJECT_ID/temperature-converter-frontend:latest \
  --build-arg NEXT_PUBLIC_API_URL=http://temperature-converter-backend:8080 .
docker push gcr.io/$PROJECT_ID/temperature-converter-frontend:latest
```

### 3. Update Deployment Files

Replace `PROJECT_ID` in:
- `backend-deployment.yaml`
- `frontend-deployment.yaml`

### 4. Create Cluster
```bash
gcloud container clusters create temperature-converter-cluster \
  --zone=$ZONE \
  --num-nodes=2 \
  --machine-type=e2-medium
```

### 5. Get Credentials
```bash
gcloud container clusters get-credentials temperature-converter-cluster \
  --zone=$ZONE
```

### 6. Deploy
```bash
cd k8s
kubectl apply -f namespace.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f backend-service-lb.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
```

### 7. Get Service IPs
```bash
# Frontend IP
kubectl get service temperature-converter-frontend -n temperature-converter

# Backend IP (wait a few minutes for LoadBalancer IP)
kubectl get service temperature-converter-backend-lb -n temperature-converter
```

### 8. Update Frontend with Backend IP

Since the frontend runs in the browser, it needs the external backend IP:

```bash
# Get backend IP
BACKEND_IP=$(kubectl get service temperature-converter-backend-lb -n temperature-converter -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Rebuild frontend with correct API URL
cd ../my-calc
docker build -t gcr.io/$PROJECT_ID/temperature-converter-frontend:latest \
  --build-arg NEXT_PUBLIC_API_URL=http://$BACKEND_IP:8080 .
docker push gcr.io/$PROJECT_ID/temperature-converter-frontend:latest

# Update deployment
kubectl set image deployment/temperature-converter-frontend \
  frontend=gcr.io/$PROJECT_ID/temperature-converter-frontend:latest \
  -n temperature-converter
```

## Access Your Application

1. **Frontend**: Get the LoadBalancer IP:
   ```bash
   kubectl get service temperature-converter-frontend -n temperature-converter
   ```
   Access at: `http://FRONTEND_IP`

2. **Backend API**: Get the LoadBalancer IP:
   ```bash
   kubectl get service temperature-converter-backend-lb -n temperature-converter
   ```
   Access at: `http://BACKEND_IP:8080`

3. **Swagger Docs**: `http://BACKEND_IP:8080/swagger/index.html`

## Useful Commands

```bash
# View pods
kubectl get pods -n temperature-converter

# View logs
kubectl logs -f deployment/temperature-converter-backend -n temperature-converter
kubectl logs -f deployment/temperature-converter-frontend -n temperature-converter

# Scale deployments
kubectl scale deployment temperature-converter-backend --replicas=3 -n temperature-converter

# Restart deployments
kubectl rollout restart deployment/temperature-converter-backend -n temperature-converter

# Delete everything
./cleanup.sh
```

## Troubleshooting

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n temperature-converter
kubectl logs <pod-name> -n temperature-converter
```

**Image pull errors:**
- Verify images are in GCR: `gcloud container images list --repository=gcr.io/$PROJECT_ID`
- Check image names in deployment files match

**Services not accessible:**
- Wait 2-5 minutes for LoadBalancer IP assignment
- Check firewall rules if using custom VPC
- Verify pods are running: `kubectl get pods -n temperature-converter`

## Cost Management

- **Delete cluster when not in use**: `gcloud container clusters delete temperature-converter-cluster --zone=$ZONE`
- **Use preemptible nodes** for dev: Add `--preemptible` to cluster creation
- **Scale down**: `kubectl scale deployment --replicas=0 -n temperature-converter`

