# ShopSphere Infra

Terraform that provisions ShopSphere cloud infrastructure.

**Single codebase. Multiple environments. Isolated state.**

The same modules and stacks are applied per environment with `tfvars` and a matching backend file. Nothing environment-specific is hardcoded in the modules.

---

## Strategy

| Principle | How it is applied |
|---|---|
| Single codebase | Shared `modules/` plus one set of stacks under `infra/` |
| Multi-environment | `dev`, `qa`, `uat`, `preprod`, `prod` — selected with `-var-file` and `-backend-config` |
| Isolation | Separate EKS cluster, secrets, DNS, load balancer, and logs per environment |
| State isolation | Separate Terraform state per stack **and** per environment (`vars/<env>.tfbackend`) |
| High availability | Multi-AZ worker nodes and Aurora writer + reader. Regional DR (Global Database) for `preprod` and `prod` only |
| Scalability | EKS Cluster Autoscaler for nodes; application HPA for pods |

**non-prod** (`dev`, `qa`, `uat`): one VPC, one Aurora cluster (three databases), three EKS clusters, Multi-AZ, no second region.

**prod** (`preprod`, `prod`): dedicated networking and Aurora Global Database (primary + DR region).

---

## Folder structure

```text
shopsphere-infra/
├── bootstrap/
│   └── github-oidc/                 # CI identity (once per account)
├── modules/
│   ├── vpc/
│   ├── eks/
│   └── aurora/
├── infra/
│   ├── core-infra/
│   │   ├── cluster/                 # VPC + EKS
│   │   │   └── vars/
│   │   └── k8-services/             # Cluster add-ons (ingress, secrets, autoscaler, …)
│   │       └── vars/
│   └── app-infra/                   # Data stores, secrets, DNS, ingress
│       └── vars/
└── scripts/                         # One-time operational SQL / helpers
```

Each stack that is applied (`cluster`, `k8-services`, `app-infra`) has the same shape:

```text
vars/
  dev.tfvars
  qa.tfvars
  uat.tfvars
  preprod.tfvars
  prod.tfvars
  dev.tfbackend
  qa.tfbackend
  uat.tfbackend
  preprod.tfbackend
  prod.tfbackend
```

`.tfvars` = environment settings (CIDRs, instance sizes, names).  
`.tfbackend` = which state file that apply uses.  
Example files in Git are `*.example.tfvars`. Real `*.tfvars` are gitignored.

---

## What is provisioned

**`bootstrap/`**  
Remote state and GitHub OIDC so pipelines assume a role. No long-lived access keys in Git.

**`infra/core-infra/cluster`**  
VPC (public, private, RDS subnets), NAT, EKS, node groups.

**`infra/core-infra/k8-services`**  
ALB controller, External Secrets, Reloader, Cluster Autoscaler, ACM, DNS for cluster services.

**`infra/app-infra`**  
Aurora PostgreSQL, subnet groups, security groups, Secrets Manager, rotation, Route 53, ALB ingress, ECR.

**Data layout**  
One PostgreSQL database per environment. One schema per service (`product`, `user`, `order`, `payment`). Tables belong to the service schema.

---

## How we provision (order)

Always: **bootstrap → cluster → k8-services → app-infra**.  
Always: one environment at a time.

```bash
# 1. Identity for the target environment
aws sso login --sso-session my-sso
export AWS_PROFILE=<admin-profile-for-that-account>
export AWS_REGION=us-east-1

# 2. Cluster (VPC + EKS)
cd infra/core-infra/cluster
terraform init -backend-config=vars/<env>.tfbackend
terraform plan  -var-file=vars/<env>.tfvars
terraform apply -var-file=vars/<env>.tfvars

# 3. Cluster services
cd ../../k8-services
terraform init -backend-config=vars/<env>.tfbackend
terraform plan  -var-file=vars/<env>.tfvars
terraform apply -var-file=vars/<env>.tfvars

# 4. App infrastructure (Aurora, secrets, DNS)
cd ../../app-infra
terraform init -backend-config=vars/<env>.tfbackend
terraform plan  -var-file=vars/<env>.tfvars
terraform apply -var-file=vars/<env>.tfvars
```

Replace `<env>` with `dev`, `qa`, `uat`, `preprod`, or `prod`.

Apply `dev`, `qa`, and `uat` against the **non-prod** account.  
Apply `preprod` and `prod` against the **prod** account.

---

## High availability and scale

| Environment | Compute | Database | Region loss |
|---|---|---|---|
| `dev`, `qa`, `uat` | Dedicated EKS, Multi-AZ nodes, Cluster Autoscaler | Shared Aurora (one cluster, three databases), writer + reader in two AZs | Not covered |
| `preprod`, `prod` | Dedicated EKS, Multi-AZ, Cluster Autoscaler | Aurora Global Database, writer + reader in primary region, reader in DR region | Covered by Global Database failover |

Node capacity grows with Cluster Autoscaler (`min` / `desired` / `max` on the node group). Pods scale with HPA in the cluster.

---

## Security (this repo)

- Private subnets for EKS nodes and Aurora
- Encryption at rest and in transit
- Secrets Manager + rotation; External Secrets into the cluster
- No passwords, tfstate, or kubeconfig in Git
- Read-only IAM permission sets cannot retrieve secret values or describe EKS

---

## Naming

Resources follow `<env>-shopsphere-…` (cluster `dev-shopsphere`, secret `shopsphere/dev/rds`, and so on).
