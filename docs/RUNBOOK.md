# Runbook — TaskApp Operations

## Prerequisites
- AWS CLI configured
- kubectl with SSH tunnel running:
  ssh -i ~/.ssh/id_rsa -L 6443:localhost:6443 ubuntu@13.40.177.222

## 1. Provision from Zero

### Terraform
cd infra/terraform
terraform init
terraform apply

### Ansible
cd infra/ansible
ansible-playbook -i inventory install-k3s.yml

### Verify cluster
kubectl get nodes

## 2. Deploy Application

### Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml

### Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.0/manifests/install.yaml

### Create secret
kubectl create secret generic backend-secret \
  --from-literal=DATABASE_USER=taskapp \
  --from-literal=DATABASE_PASSWORD=taskapp123 \
  --from-literal=SECRET_KEY=$(openssl rand -base64 32) \
  -n taskapp

### Bootstrap GitOps
kubectl apply -f gitops/taskapp-application.yaml

## 3. Scaling

### Manual scale
kubectl scale deployment/backend -n taskapp --replicas=3

### HPA status
kubectl get hpa -n taskapp

## 4. Rolling Deploy (zero downtime)

Update image tag in manifests/backend/deployment.yaml then:
git add . && git commit -m "chore: bump image" && git push
Argo CD auto-syncs within 3 minutes.

## 5. Rollback

### Git revert (preferred)
git revert HEAD
git push

### Kubernetes rollback
kubectl rollout undo deployment/backend -n taskapp

## 6. Failure Recovery

### Dead worker node
kubectl get nodes
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl delete node <node>

### Dead backend pod
kubectl logs <pod> -n taskapp
kubectl describe pod <pod> -n taskapp

### Bad migration
kubectl exec -it postgres-0 -n taskapp -- psql -U taskapp -d taskapp
UPDATE alembic_version SET version_num='<previous-version>';

### Data verification after postgres restart
kubectl delete pod postgres-0 -n taskapp
kubectl exec -it postgres-0 -n taskapp -- psql -U taskapp -d taskapp -c "SELECT COUNT(*) FROM tasks;"

## 7. Useful Commands

# Check all pods
kubectl get pods -n taskapp -o wide

# Check logs
kubectl logs -l app=backend -n taskapp --tail=50

# Check certificate
kubectl get certificate -n taskapp

# Force Argo CD sync
kubectl -n argocd app sync taskapp

# Access postgres
kubectl exec -it postgres-0 -n taskapp -- psql -U taskapp -d taskapp

# Check metrics
kubectl top pods -n taskapp
kubectl top nodes
