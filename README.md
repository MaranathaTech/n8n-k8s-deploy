# n8n Kubernetes Deployment

This directory contains Kubernetes manifests to deploy n8n on Rancher Desktop.

## Prerequisites

- Rancher Desktop installed and running
- kubectl configured to use Rancher Desktop's Kubernetes cluster

## Deployment

### Quick Deploy (Recommended)

Use the automated deploy script:

```bash
cd k8s
./deploy.sh
```

The script will:
- Check prerequisites (kubectl and cluster connectivity)
- Apply all Kubernetes manifests
- Wait for the deployment to be ready
- Show deployment status and access information
- Optionally display logs

### Manual Deployment

If you prefer to deploy manually:

Apply all manifests:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Or apply everything at once:

```bash
kubectl apply -f k8s/
```

### 2. Verify Deployment

Check if the pod is running:

```bash
kubectl get pods -n n8n
```

Check the service:

```bash
kubectl get svc -n n8n
```

### 3. Access n8n

n8n will be accessible at:

**http://localhost:30678**

The service is configured as a NodePort on port 30678, which is safe and outside the well-known ports range (0-1024).

### 4. Check Logs

To view n8n logs:

```bash
kubectl logs -n n8n -l app=n8n -f
```

## Configuration

The deployment includes:

- **Namespace**: `n8n` - isolated namespace for n8n resources
- **PersistentVolumeClaim**: 5Gi storage for n8n data persistence
- **Deployment**: Single replica with resource limits
  - Memory: 512Mi request, 1Gi limit
  - CPU: 250m request, 1000m limit
- **Service**: NodePort on port 30678
- **Health checks**: Liveness and readiness probes configured

## Customization

### Environment Variables

Edit `k8s/deployment.yaml` to customize environment variables:

- `N8N_HOST`: Hostname (default: localhost)
- `N8N_PORT`: Internal port (default: 5678)
- `WEBHOOK_URL`: Webhook URL for external access
- `GENERIC_TIMEZONE`: Timezone setting

### Storage

To change storage size, edit the PVC in `k8s/deployment.yaml`:

```yaml
resources:
  requests:
    storage: 5Gi  # Change this value
```

### Port

To change the external port, edit the NodePort in `k8s/service.yaml`:

```yaml
nodePort: 30678  # Change to any port between 30000-32767
```

## Cleanup

To remove the deployment:

```bash
kubectl delete -f k8s/
```

To completely remove including data:

```bash
kubectl delete namespace n8n
```

## Troubleshooting

### Pod not starting

Check pod events:
```bash
kubectl describe pod -n n8n -l app=n8n
```

### Cannot access n8n

1. Verify the service is running:
   ```bash
   kubectl get svc -n n8n
   ```

2. Check if the pod is ready:
   ```bash
   kubectl get pods -n n8n
   ```

3. Verify Rancher Desktop is running and Kubernetes is enabled

### Data persistence

Data is stored in a PersistentVolumeClaim. To check:
```bash
kubectl get pvc -n n8n
```
