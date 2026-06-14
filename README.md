# Multi-Tier Web Architecture on AWS

A production-grade, highly available web infrastructure built on AWS using Terraform. Demonstrates core cloud networking, compute, database, and security skills across a full three-tier architecture.

\---

## Architecture

```
                          INTERNET
                              |
                    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\[Internet Gateway]
                              |
                 ┌────────────────────────┐
                 │      PUBLIC SUBNETS     │
                 │  AZ1 (10.0.1.0/24)     │
                 │  AZ2 (10.0.2.0/24)     │
                 │  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\[Network Load Balancer]│
                 │  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\[NAT Gateway]          │
                 └────────────────────────┘
                         /        \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
            ┌───────────┐          ┌───────────┐
            │  PRIVATE   │          │  PRIVATE   │
            │  SUBNET    │          │  SUBNET    │
            │    AZ1     │          │    AZ2     │
            │ 10.0.3.0/24│          │ 10.0.4.0/24│
            │ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\[EC2 Web]  │          │ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\[EC2 Web]  │
            │ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\[RDS Pri]  │◄────────►│ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\[RDS Stby] │
            └───────────┘  sync    └───────────┘
```

**Traffic flow:**

```
Visitor → Internet Gateway → Network Load Balancer
        → EC2 Web Server (private subnet)
        → RDS MySQL Database (private subnet, Multi-AZ)
```

\---

## AWS Services Used

|Service|Purpose|
|-|-|
|**VPC**|Isolated private network — 10.0.0.0/16|
|**Subnets**|2 public + 2 private across 2 Availability Zones|
|**Internet Gateway**|Connects VPC to the public internet|
|**NAT Gateway**|Allows private instances to reach internet for updates|
|**Route Tables**|Controls traffic routing between subnets|
|**Security Groups**|Layer-by-layer virtual firewalls|
|**Network Load Balancer**|Distributes traffic across EC2 instances|
|**EC2**|Apache web servers in private subnets|
|**Auto Scaling Group**|Automatically replaces failed instances (min 2, max 4)|
|**Amazon RDS**|Managed MySQL database with Multi-AZ failover|
|**IAM**|Least-privilege roles — EC2 only has permissions it needs|
|**Terraform**|Full infrastructure defined and deployed as code|

\---

## Security Architecture

Security is enforced in layers — each component only accepts traffic from the layer directly above it:

```
Internet → Port 80 only → Network Load Balancer
NLB      → Port 80 only → EC2 Security Group
EC2      → Port 3306 only → RDS Security Group
```

|Security Control|Implementation|
|-|-|
|EC2 in private subnets|No direct internet access to web servers|
|RDS in private subnets|Database never reachable from internet|
|IAM least privilege|EC2 role only allows CloudWatch logs + Secrets Manager reads|
|No hardcoded passwords|DB password passed via Terraform variables, never in code|
|Storage encryption|RDS storage encrypted at rest|
|NAT Gateway|Outbound only — internet cannot initiate inbound connections|

\---

## How to Deploy

### Prerequisites

* AWS account with CLI configured (`aws configure`)
* Terraform installed
* Git installed

### Steps

**1. Clone the repository**

```bash
git clone https://github.com/OleratoPhiri/multi-tier-architecture.git
cd multi-tier-architecture
```

**2. Create variables file**

```bash
cd terraform
touch terraform.tfvars
```

Add database password to `terraform.tfvars`:

```hcl
db\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\_password = "Password"
```

> `terraform.tfvars` is in `.gitignore` — it will never be pushed to GitHub

**3. Initialise Terraform**

```bash
terraform init
```

**4. what will be created**

```bash
terraform plan
```

**5. Deploy the full stack**

```bash
terraform apply
```

Type `yes` when prompted. RDS Multi-AZ takes 10-15 minutes to provision.

**6. Gets Load Balancer URL from the outputs**

```bash
terraform output nlb\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\_dns\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\_name
```

Open `http://NLB DNS-Name` in browser.

**7. Destroy when done (to avoid costs)**

```bash
terraform destroy
```

\---

## Project Structure

```
multi-tier-architecture/
├── terraform/
│   ├── providers.tf      # AWS provider configuration
│   ├── variables.tf      # Reusable variables (region, CIDRs, instance type)
│   ├── vpc.tf            # VPC, subnets, IGW, NAT Gateway, route tables, security groups
│   ├── ec2.tf            # Launch template, Auto Scaling Group, scaling policy
│   ├── alb.tf            # Network Load Balancer, target group, listener
│   ├── rds.tf            # RDS MySQL instance, DB subnet group
│   ├── iam.tf            # IAM role, policy, and instance profile for EC2
│   └── outputs.tf        # NLB DNS name, RDS endpoint, VPC ID
├── scripts/
│   └── user\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\_data.sh      # Bootstrap script — installs Apache on EC2 launch
└── README.md
```

\---

## Networking — IP Address Plan

|Resource|CIDR Block|Purpose|
|-|-|-|
|VPC|10.0.0.0/16|Entire network — 65,536 IPs|
|Public Subnet AZ1|10.0.1.0/24|NLB + NAT Gateway|
|Public Subnet AZ2|10.0.2.0/24|NLB (second AZ)|
|Private Subnet AZ1|10.0.3.0/24|EC2 + RDS Primary|
|Private Subnet AZ2|10.0.4.0/24|EC2 + RDS Standby|

\---

## High Availability

The architecture is designed to survive a full Availability Zone failure:

**Compute HA:** Auto Scaling Group maintains a minimum of 2 instances across 2 AZs. If an instance fails health checks, ASG automatically terminates and replaces it — validated by manually terminating an instance and confirming replacement within minutes.

**Database HA:** RDS Multi-AZ maintains a synchronous standby replica in a second AZ. AWS automatically fails over in 60-120 seconds with no manual intervention — the application reconnects to the same endpoint.

**Load Balancing:** NLB continuously health checks EC2 instances every 30 seconds. Unhealthy instances are removed from rotation immediately.

\---

## Auto Scaling Configuration

|Setting|Value|Reason|
|-|-|-|
|Minimum instances|2|Always one per AZ for HA|
|Maximum instances|4|Cost control ceiling|
|Scale-out trigger|CPU > 70%|Add instance under load|
|Health check grace period|300 seconds|Wait for user data to complete|
|Health check type|ELB|NLB decides instance health|

\---

## What I Learned

* Designing **multi-AZ VPC architectures** with public and private subnet separation
* The difference between **NLB and ALB** — NLB preserves source IP, requires open security groups; ALB has its own security group
* Why **NAT Gateways** are required for private instances to download packages
* Writing **User Data bootstrap scripts** to automatically configure EC2 on launch
* Configuring **Auto Scaling Groups** with health checks and scaling policies
* Setting up **Multi-AZ RDS** for automatic database failover
* Applying **IAM least privilege** — EC2 only has the exact permissions it needs
* Managing sensitive values (DB passwords) with **Terraform variables** — never hardcoded

\---

## Part of a 3-Project Cloud Engineering Portfolio

|Project|Focus|Status|
|-|-|-|
|✅ Cloud Resume Challenge|Serverless, CDN, IaC, CI/CD|Complete|
|✅ Multi-Tier Web Architecture|VPC, EC2, RDS, Auto Scaling|Complete|
|🔄 Serverless Data Pipeline|S3 Events, Glue, Athena, CloudWatch|In Progress|



