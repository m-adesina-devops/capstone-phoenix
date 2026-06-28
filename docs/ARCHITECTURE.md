# Architecture — TaskApp on Kubernetes (Phoenix Capstone)

## Node Topology

3-node k3s cluster on AWS eu-west-2:
- Control Plane (t3.micro) 13.40.177.222 - k3s server, Traefik, CoreDNS, cert-manager, Argo CD
- Worker 1 (t3.micro) 3.8.232.68 - k3s agent, app pods
- Worker 2 (t3.micro) 18.134.159.222 - k3s agent, app pods

Pod CIDR:     10.42.0.0/16 (Flannel VXLAN)
Service CIDR: 10.43.0.0/16
DNS:          10.43.0.10 (CoreDNS)
Domain:       taskapp.13.40.177.222.nip.io

## Request Flow

Browser hits https://taskapp.13.40.177.222.nip.io
Traefik ingress terminates TLS (Let's Encrypt cert via cert-manager)
/api/* routes to backend-service:5000 (Flask, 2-6 replicas via HPA)
/* routes to frontend-service:80 (nginx serving React SPA)
Backend connects to postgres-service:5432 (StatefulSet with 10Gi PVC)

## Core Requirements - Single-Server Assumptions Fixed

1. Namespace + ConfigMap/Secret: ConfigMap holds non-secret config, Secret holds credentials. Replaces flat .env file.
2. Postgres StatefulSet + PVC: Data persists across pod restarts. Replaces Docker volume that dies with host.
3. 2+ replicas across nodes: topologySpreadConstraints forces pods onto different nodes. Eliminates single point of failure.
4. Migration as Job: db-migration Job runs once before app starts. Eliminates alembic race condition at 2+ replicas.
5. Probes: startupProbe + readinessProbe + livenessProbe on all pods. Dead containers are detected and replaced.
6. Resource limits: requests + limits on every container. Prevents containers starving each other.
7. RollingUpdate maxUnavailable 0: New pod passes readiness before old is terminated. Zero downtime deploys.
8. Ingress + TLS: Traefik + cert-manager + Let's Encrypt. Replaces manual certbot on host.
9. Pinned image tags: All images pinned to commit SHA c2b906d. No more non-deterministic :latest deploys.

## Advanced Features

- HPA: Backend scales 2-6 replicas based on CPU >60% and memory >90%
- PDB: minAvailable 1 on backend and frontend prevents drain outages
- GitOps: Argo CD auto-syncs from GitHub on every push, selfHeal reverts manual changes
- Observability: metrics-server provides CPU/memory metrics cluster-wide

## GitOps Flow

git push to GitHub
Argo CD polls every 3 minutes, detects diff
Applies manifests to cluster automatically
selfHeal: true reverts any manual kubectl changes
prune: true removes resources deleted from git

## Domain Choice Justification

nip.io provides a real public DNS record resolving to the cluster IP,
enabling valid Let's Encrypt HTTP-01 certificate issuance without the
cost of a registered domain. Chosen for cost efficiency in an academic
project. Security posture is identical to a registered domain.
