# Kubernetes Deployment Guide for Google Kubernetes Engine (GKE)

This guide will help you deploy the Temperature Converter application to Google Kubernetes Engine.

## Prerequisites

1. **Google Cloud SDK (gcloud)** installed and configured
2. **kubectl** installed
3. **Docker** installed
4. A **Google Cloud Project** with billing enabled
5. **GKE API** enabled in your project

## Step 1: Set Up Google Cloud Project

```bash
# Set your project ID
export PROJECT_ID=your-project-id
export REGION=us-central1  # Change to your preferred region
export ZONE=us-central1-a  # Change to your preferred zone

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

## Step 2: Build and Push Docker Images

### Build and push backend image:

```bash
cd backend

# Build the image
docker build -t gcr.io/$PROJECT_ID/temperature-converter-backend:latest .

# Configure Docker to use gcloud as a credential helper
gcloud auth configure-docker

# Push the image
docker push gcr.io/$PROJECT_ID/temperature-converter-backend:latest
```

### Build and push frontend image:

```bash
cd ../my-calc

# Build the image
docker build -t gcr.io/$PROJECT_ID/temperature-converter-frontend:latest \
  --build-arg NEXT_PUBLIC_API_URL=http://temperature-converter-backend:8080 .

# Push the image
docker push gcr.io/$PROJECT_ID/temperature-converter-frontend:latest
```

## Step 3: Update Kubernetes Manifests

Replace `PROJECT_ID` in the deployment files:

```bash
cd ../k8s

# Replace PROJECT_ID in all deployment files
sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" backend-deployment.yaml
sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" frontend-deployment.yaml
```

Or manually edit:
- `backend-deployment.yaml`: Replace `PROJECT_ID` with your actual project ID
- `frontend-deployment.yaml`: Replace `PROJECT_ID` with your actual project ID

## Step 4: Create GKE Cluster

```bash
# Create a GKE cluster
gcloud container clusters create temperature-converter-cluster \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --num-nodes=2 \
  --machine-type=e2-medium \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=3

# Get credentials for the cluster
gcloud container clusters get-credentials temperature-converter-cluster \
  --zone=$ZONE \
  --project=$PROJECT_ID
```

## Step 5: Deploy to Kubernetes

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Deploy backend
kubectl apply -f backend-deployment.yaml -n temperature-converter
kubectl apply -f backend-service.yaml -n temperature-converter

# Deploy frontend
kubectl apply -f frontend-deployment.yaml -n temperature-converter
kubectl apply -f frontend-service.yaml -n temperature-converter
```

## Step 6: Verify Deployment

```bash
# Check pods
kubectl get pods -n temperature-converter

# Check services
kubectl get services -n temperature-converter

# Check deployments
kubectl get deployments -n temperature-converter

# View logs
kubectl logs -f deployment/temperature-converter-backend -n temperature-converter
kubectl logs -f deployment/temperature-converter-frontend -n temperature-converter
```

## Step 7: Access the Application

### Option 1: Using LoadBalancer Service (Recommended for testing)

The frontend service is configured as a LoadBalancer. Get the external IP:

```bash
kubectl get service temperature-converter-frontend -n temperature-converter
```

Access the application at: `http://EXTERNAL_IP`

### Option 2: Using Ingress (For production with domain)

1. **Reserve a static IP:**
```bash
gcloud compute addresses create temperature-converter-ip --global
```

2. **Update ingress.yaml** with your domain name

3. **Create managed certificate:**
```bash
# Update managed-certificate.yaml with your domain
kubectl apply -f managed-certificate.yaml -n temperature-converter
```

4. **Deploy ingress:**
```bash
kubectl apply -f ingress.yaml -n temperature-converter
```

5. **Get the ingress IP:**
```bash
kubectl get ingress temperature-converter-ingress -n temperature-converter
```

## Step 8: Update Frontend API URL

Since the frontend runs in the browser, it needs to call the backend via the external URL. Update the frontend deployment to use the correct API URL:

```bash
# Get the backend service external IP or use ingress
kubectl get service temperature-converter-backend -n temperature-converter

# Update frontend deployment with the correct API URL
kubectl set env deployment/temperature-converter-frontend \
  NEXT_PUBLIC_API_URL=http://BACKEND_EXTERNAL_IP:8080 \
  -n temperature-converter
```

Or expose the backend service as LoadBalancer:

```bash
# Edit backend-service.yaml to change type to LoadBalancer
kubectl apply -f backend-service.yaml -n temperature-converter
```

## Useful Commands

### Scale deployments:
```bash
kubectl scale deployment temperature-converter-backend --replicas=3 -n temperature-converter
kubectl scale deployment temperature-converter-frontend --replicas=3 -n temperature-converter
```

### Update images:
```bash
# After pushing new images
kubectl set image deployment/temperature-converter-backend \
  backend=gcr.io/$PROJECT_ID/temperature-converter-backend:latest \
  -n temperature-converter

kubectl set image deployment/temperature-converter-frontend \
  frontend=gcr.io/$PROJECT_ID/temperature-converter-frontend:latest \
  -n temperature-converter
```

### Delete everything:
```bash
kubectl delete namespace temperature-converter
```

### Delete cluster:
```bash
gcloud container clusters delete temperature-converter-cluster \
  --zone=$ZONE \
  --project=$PROJECT_ID
```

## Troubleshooting

1. **Pods not starting:**
   ```bash
   kubectl describe pod <pod-name> -n temperature-converter
   kubectl logs <pod-name> -n temperature-converter
   ```

2. **Image pull errors:**
   - Ensure images are pushed to GCR
   - Check image names match in deployment files
   - Verify gcloud auth is configured

3. **Service not accessible:**
   - Check service selectors match pod labels
   - Verify pods are running and ready
   - Check firewall rules if using LoadBalancer

## Cost Optimization Tips

1. Use **preemptible nodes** for development:
   ```bash
   --preemptible
   ```

2. Use **smaller machine types** for development:
   ```bash
   --machine-type=e2-small
   ```

3. **Delete the cluster** when not in use to avoid charges

4. Use **Autopilot mode** for automatic resource optimization:
   ```bash
   gcloud container clusters create-auto temperature-converter-cluster \
     --region=$REGION \
     --project=$PROJECT_ID
   ```

