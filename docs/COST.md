# Cost Analysis — TaskApp on AWS eu-west-2

## Current Monthly Cost (On-Demand t3.micro)

| Resource | Qty | Unit Price | Monthly Cost |
|---|---|---|---|
| EC2 t3.micro (control plane) | 1 | $0.0116/hr | $8.47 |
| EC2 t3.micro (worker-1) | 1 | $0.0116/hr | $8.47 |
| EC2 t3.micro (worker-2) | 1 | $0.0116/hr | $8.47 |
| EBS gp3 20GB x 3 nodes | 3 | $0.088/GB/mo | $5.28 |
| EBS gp3 10GB (Postgres PVC) | 1 | $0.088/GB/mo | $0.88 |
| S3 (Terraform state) | ~1MB | $0.023/GB/mo | $0.01 |
| DynamoDB (Terraform lock) | minimal | on-demand | $0.01 |
| Data transfer out | ~5GB/mo | $0.09/GB | $0.45 |
| Total | | | ~$32/month |

## AWS Credits
Account has $113.38 in AWS credits (135 days remaining as of 2026-06-26).
At $32/month burn rate, credits last approximately 3.5 months.

## How to Cut Cost in Half

Switch worker nodes to Spot Instances — reduces EC2 cost by ~70%.

| Resource | Change | Monthly Cost |
|---|---|---|
| EC2 On-Demand t3.micro (control plane) | Keep on-demand | $8.47 |
| EC2 Spot t3.micro (worker-1) | Switch to Spot | $2.54 |
| EC2 Spot t3.micro (worker-2) | Switch to Spot | $2.54 |
| EBS storage | unchanged | $6.16 |
| Data transfer | unchanged | $0.45 |
| Total | | ~$20/month |

Workers can use Spot because Kubernetes reschedules pods automatically
when a node is reclaimed. PDBs ensure minAvailable: 1 is maintained
during disruptions. Control plane stays On-Demand to avoid losing
the API server.

Alternative: Migrate to Hetzner Cloud (CPX11, 2vCPU/2GB) at 4.35 EUR
per node x 3 = ~13 EUR/month, saving over 60% vs AWS.
