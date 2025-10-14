#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi

    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi

    print_info "Prerequisites check passed"
}

# Function to deploy n8n
deploy_n8n() {
    print_info "Deploying n8n to Kubernetes..."

    # Apply deployment and service manifests
    print_info "Applying deployment manifest..."
    kubectl apply -f "${SCRIPT_DIR}/deployment.yaml"

    print_info "Applying service manifest..."
    kubectl apply -f "${SCRIPT_DIR}/service.yaml"

    print_info "Kubernetes manifests applied successfully"
}

# Function to wait for deployment
wait_for_deployment() {
    print_info "Waiting for deployment to be ready..."

    if kubectl wait --for=condition=available --timeout=300s deployment/n8n -n n8n; then
        print_info "Deployment is ready!"
    else
        print_error "Deployment failed to become ready within timeout"
        print_info "Checking pod status..."
        kubectl get pods -n n8n
        print_info "Checking pod logs..."
        kubectl logs -n n8n -l app=n8n --tail=50
        exit 1
    fi
}

# Function to show deployment status
show_status() {
    print_info "Deployment Status:"
    echo ""

    kubectl get all -n n8n

    echo ""
    print_info "Getting service details..."
    NODE_PORT=$(kubectl get svc n8n -n n8n -o jsonpath='{.spec.ports[0].nodePort}')

    echo ""
    print_info "n8n is accessible at:"
    echo "  - NodePort: http://<node-ip>:${NODE_PORT}"
    echo ""

    # Try to get node IPs
    print_info "Available nodes:"
    kubectl get nodes -o wide | awk '{print $1, $6}' | column -t
}

# Function to show logs
show_logs() {
    print_info "Showing recent logs..."
    kubectl logs -n n8n -l app=n8n --tail=20
}

# Main deployment function
main() {
    echo "======================================"
    echo "    n8n Kubernetes Deployment"
    echo "======================================"
    echo ""

    check_prerequisites
    deploy_n8n
    wait_for_deployment
    show_status

    echo ""
    print_info "Deployment completed successfully!"
    echo ""

    read -p "Do you want to see the logs? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_logs
    fi

    echo ""
    print_info "To view logs later, run: kubectl logs -n n8n -l app=n8n -f"
    print_info "To access the n8n UI, navigate to http://<node-ip>:${NODE_PORT}"
}

# Run main function
main
