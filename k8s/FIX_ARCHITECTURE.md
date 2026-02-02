# Fix: exec format error

## The Problem

Your pods are crashing with "exec format error" because the Docker images were built for the wrong architecture (macOS ARM instead of Linux amd64).

## The Solution

Rebuild the images for the correct platform (linux/amd64) and push them to GCR.

## Quick Fix

Run this script (replace `tempcalc` with your project ID):

```bash
cd k8s
./rebuild-images.sh tempcalc
```

## Manual Steps

### 1. Rebuild Backend Image

```bash
cd backend
docker build --platform linux/amd64 -t gcr.io/tempcalc/temperature-converter-backend:latest .
docker push gcr.io/tempcalc/temperature-converter-backend:latest
cd ..
```

### 2. Rebuild Frontend Image

```bash
cd my-calc
docker build --platform linux/amd64 -t gcr.io/tempcalc/temperature-converter-frontend:latest \
  --build-arg NEXT_PUBLIC_API_URL=http://temperature-converter-backend:8080 .
docker push gcr.io/tempcalc/temperature-converter-frontend:latest
cd ..
```

### 3. Restart Deployments

```bash
kubectl rollout restart deployment/temperature-converter-backend -n temperature-converter
kubectl rollout restart deployment/temperature-converter-frontend -n temperature-converter
```

### 4. Wait for Rollout

```bash
kubectl rollout status deployment/temperature-converter-backend -n temperature-converter
kubectl rollout status deployment/temperature-converter-frontend -n temperature-converter
```

### 5. Check Status

```bash
kubectl get pods -n temperature-converter
```

## Why This Happened

When you build Docker images on macOS (especially Apple Silicon), they're built for ARM architecture by default. GKE nodes run Linux on amd64/x86_64 architecture, so the binaries don't match.

The `--platform linux/amd64` flag tells Docker to build for Linux amd64, which matches GKE nodes.

## Verify It's Fixed

After rebuilding, check the pods:

```bash
kubectl get pods -n temperature-converter
```

You should see:
```
NAME                                              READY   STATUS    RESTARTS   AGE
temperature-converter-backend-xxxxx              1/1     Running   0          1m
temperature-converter-frontend-xxxxx             1/1     Running   0          1m
```

## Get Service IPs

Once pods are running:

```bash
kubectl get services -n temperature-converter
```

Access your app:
- Frontend: `http://FRONTEND_EXTERNAL_IP`
- Backend: `http://BACKEND_EXTERNAL_IP:8080`


