# Workflow 05 — ECS on EC2
## Cluster, host, task, and service. No public URL.

**Programme:** AWS Graduate Cloud Skills Accelerator  
**Region:** `us-east-1` only  
**Prefix:** `accelerator`  
**Project:** the `accelerator-app` folder  
**Compute:** self-managed EC2 (one `t3.micro`).

---

# Workflow Overview

Workflow 04 put `accelerator:latest` in ECR, then you destroyed the repo. There is still no runtime.

This chapter is **all of ECS**: cluster, one private `t3.micro` in an Auto Scaling group, a capacity provider, a task definition, and a service. When you finish apply, **Running tasks = 1**.

There is **no ALB**. There is **no public URL**. If you open a browser and see nothing, you are on track.

---

### The 5 Codewrkx Engineer Questions

**What is the problem?**  
A packed image in ECR does not serve visitors. **ECR (Elastic Container Registry)** is only storage. Nothing is running.

A **region** is a geographic AWS location — a cluster of **data centres**. Light picture: the **city** (N. Virginia). An **Availability Zone (AZ)** is an isolated data centre inside that region. Light picture: a **district**. The EC2 host sits in a **private subnet** (a **back room**). Two AZs come into play for the ALB in Workflow 06 — not today.

**Why solve it with these services?**  
**ECS (Elastic Container Service)** runs and restarts containers. **EC2 (Elastic Compute Cloud)** is the **virtual server** you manage — one `t3.micro` in a private subnet, with no public IP.

Four names you will see in the console:

| Name | Plain English |
|------|----------------|
| **Cluster** | Named group (`accelerator-cluster`). |
| **Task definition** | Instruction sheet (image `accelerator:latest`, port 80). |
| **Task** | One running copy of the container. |
| **Service** | Standing order: keep **one** task (`Running = 1`). |

**When are these services used?**  
When an image must actually run. After the registry, before a public URL. In a job: every environment that must serve the app. Not on every save.

**How does this work?**  
Apply the house (VPC) + registry (ECR) first, push `accelerator:latest`, add `ecs-cluster` and `ecs-service`, then:

| Command | Today |
|---------|--------|
| `terraform init` | Read the new modules. |
| `terraform validate` | Grammar check. |
| `terraform plan` | Preview: cluster, one host, task definition, service. Confirm **no** load balancer. |
| `terraform apply` | Build it. Type `yes`. Wait for **Running = 1**. |
| `terraform destroy` | Take it down before you leave. Terraform files stay. |

Walk the console as root (N. Virginia). The task is private. No browser URL yet — that is the **ALB (Application Load Balancer)** in Workflow 06.

**Who typically deploys them?**  
Platform or cloud engineers own the cluster and hosts. Application engineers own the image. You write both in Terraform. Root **looks** in the Console. `accelerator-cli` **applies** and **destroys**.

---

### Where We Came From

You can create ECR and push an image. You have a VPC module on disk. AWS is empty. You destroyed ECR at the end of Workflow 04.

### Where We Are Now

You will apply **VPC + ECR** (NAT starts), **push the image**, add `modules/ecs-cluster` and `modules/ecs-service`, and wait until one task is **RUNNING**.

### Where We Are Going

The workload will run in a private subnet. Workflow 06 adds the ALB and the allow-list (internet → ALB SG → task SG).

### Technical Context

You own the **EC2** instance. The **ECS agent** on that instance registers with the cluster. A **capacity provider** tied to the ASG is how ECS places work on *this* host.

**`awsvpc`** gives the task its own elastic network interface and its own security group. That is **not** `accelerator-ecs-instance-sg`. The host SG stays closed. The task SG (`accelerator-svc-sg`) allows **egress only** in this chapter. Workflow 06 will add inbound port 80 **only from the ALB SG**.

Do **not** set `launch_type = "EC2"` when you use a **capacity provider strategy**. This Accelerator uses the capacity provider.

If the task stops, you read the **stopped task reason** on the service.

| Resource | Responsibility |
|-------|----------|
| Cluster `accelerator-cluster` | Named runtime group |
| Instance SG `accelerator-ecs-instance-sg` | Host. Egress via NAT. No public HTTP |
| One `t3.micro` in a **private** subnet | Host. No public IP |
| Capacity provider | ECS places work on the ASG |
| Execution role | ECS may **pull** `accelerator:latest` from ECR |
| Task definition | Image, port 80, `awsvpc`, EC2 |
| Service SG `accelerator-svc-sg` | Attached to the **task ENI**. Egress only |
| Service `desired = 1` | Keep one task running |

### Architecture Snapshot

When [`architecture.png`](architecture.png) is in this Accelerator folder, that is the full drawing. If it is not there yet, use the text snapshot below.

```text
accelerator-cluster
        │
        ├─ 1 private t3.micro  (ASG, instance SG closed)
        │
        └─ accelerator-service   desired = 1
                │
                ▼
           task (awsvpc) :80
                SG = accelerator-svc-sg (egress only)
                │
                └── NAT → ECR pull

No ALB.  No http://
```

### SOFTWARE DELIVERY PROGRESS: ✓ 0 Intro → ✓ 01 Access → ✓ 02 VPC → ✓ 03 Docker → ✓ 04 ECR → ► 05 ECS → □ 06 ALB → □ 07 Prove → □ 08 Pipeline

### Learning Outcomes

- Raise a cluster on a self-managed EC2 host  
- Author a task definition and service as a module  
- Use `awsvpc` and a task SG separate from the instance SG  
- Prove Running = 1 in the console  
- Explain why there is still no URL  

### Labs

Tick as you finish. Change `- [ ]` to `- [x]`.

- [ ] Lab 5.1 — Confirm CLI and Docker
- [ ] Lab 5.2 — Apply VPC + ECR
- [ ] Lab 5.3 — Push the image to ECR
- [ ] Lab 5.4 — Create `modules/ecs-cluster`
- [ ] Lab 5.5 — Create `modules/ecs-service`
- [ ] Lab 5.6 — Call both modules from the root
- [ ] Lab 5.7 — Apply and wait
- [ ] Lab 5.8 — See the instance and the task (root)
- [ ] Lab 5.9 — Destroy

---

## Lab 5.1 — Confirm CLI and Docker

### Procedure

Open a terminal in the **accelerator-app** folder.

`aws sts get-caller-identity` asks AWS: “who am I?” It does **not** create anything. The `Arn` must contain `user/accelerator-cli`. If it contains `root`, stop. Workflow 01 Labs 1.2–1.3.

```bash
aws sts get-caller-identity
```

Docker Desktop must be **running**. You will build and push in Lab 5.3.

### See it (root)

Confirm the window you will use after apply. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → **email that owns the account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.  
   **Why it matters:** Lab 5.2 looks here. Wrong region = empty VPC list after apply.

### Verification

- CLI Arn contains `user/accelerator-cli`. Docker running. Console is N. Virginia as the account email.  
- **Expected State:** Ready to apply and push.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 5.1 — Confirm CLI and Docker

---

## Lab 5.2 — Apply VPC + ECR

### Objective

Bring the network and the empty registry back. Full apply — **NAT comes back; the clock starts**.

`terraform/main.tf` should still call **only** `vpc` and `ecr`. Do not add ECS yet.

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform init` does **not** build the land. It re-reads `vpc` and `ecr`. You should see **Terraform has been successfully initialized**.

```bash
terraform init
```

`terraform validate` is a grammar check. It still does **not** touch AWS. You should see **Success! The configuration is valid**.

```bash
terraform validate
```

`terraform plan` is the preview. It does **not** create anything yet.

Read the plan. You should see vpc and ecr. You should **not** see ECS or a load balancer. If you see those, stop. Do not apply. This lab is vpc + ecr only.

```bash
terraform plan
```

`terraform apply` is a **full** apply of vpc + ecr. **NAT comes back; the clock starts.** It will ask you to type `yes`. Until you type `yes`, nothing is created. Do **not** add ECS modules before this lab.

```bash
terraform apply
```

Type `yes` and press **Enter**. Wait until **Apply complete!**

### See it (root)

The house and the registry are back. No cluster yet. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
   (or [https://aws.amazon.com](https://aws.amazon.com) → **Sign in to the Console**).  
2. **Root user** → **email that owns the account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

4. Top search: **VPC** → **VPC**. Left: **Your VPCs** → **`accelerator-vpc`**.  
   **Why it matters:** the EC2 host will sit on this VPC, in a **private** subnet (a back room).

5. Left: **NAT gateways** → **`accelerator-nat`**. State **Available**.  
   **Why it matters:** the host has no public IP. It fetches the image through this service exit (NAT). The clock is running.

6. Top search: **ECR** → **Elastic Container Registry** → **Repositories** → **`accelerator`**.  
   The repository exists. It may still be **empty** until Lab 5.3.  
   **Why it matters:** ECS pulls from here, not from your laptop.

7. Top search: **ECS** → **Clusters**. **`accelerator-cluster`** should **not** exist yet.  
   **Why it matters:** this lab is only vpc + ecr. The cluster comes in Lab 5.7.

### Verification

- NAT **Available**. ECR repo `accelerator` exists (may be empty until the next lab).  
- No ECS cluster yet.  
- **Expected State:** Place to put an image and a host. Clock started.

### Troubleshooting References

¹ **Symptom:** Plan includes ECS.  
  **Resolution:** You pasted ECS modules too early. This lab is vpc + ecr only.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 5.2 — Apply VPC + ECR

---

## Lab 5.3 — Push the image to ECR

Destroy in Workflow 04 deleted the image. Push again. Docker Desktop must be **running**. Work from the **accelerator-app** root (not `terraform/`). If you are still in `terraform/`:

```bash
cd ..
```

This prints your 12-digit AWS account id only. Copy it. Paste it in place of `ACCOUNT_ID` below.

```bash
aws sts get-caller-identity --query Account --output text
```

`docker build` packs the app on this laptop. It does **not** upload yet.

```bash
docker build -t accelerator:latest .
```

`docker login` uses a short-lived ECR password, not your IAM access key. Replace `ACCOUNT_ID`. You should see **Login Succeeded**.

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

`docker tag` points the local image at the registry URL. It does **not** upload yet. Replace `ACCOUNT_ID`.

```bash
docker tag accelerator:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

`docker push` uploads `latest` to ECR. Replace `ACCOUNT_ID`. Empty repository = Lab 5.7 will fail with `CannotPullContainerError`.

```bash
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

### See it (root)

If the console is closed, sign in again (Lab 5.2 steps 1–3). Region **N. Virginia**.

1. Top search: **ECR** → **Repositories** → **`accelerator`**.  
2. Tag **`latest`** is listed. **Pushed at** is recent.  
   **Why it matters:** Lab 5.7 will start a task that pulls this tag. Empty repository = `CannotPullContainerError`.

### Verification

**ECR → Repositories → `accelerator`** → tag **`latest`**.  
- **Expected State:** Pull will succeed.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 5.3 — Push the image to ECR

---

## Lab 5.4 — Create `modules/ecs-cluster`

### Objective

Build the host: AMI, instance IAM, instance SG, named cluster, launch template, Auto Scaling group, capacity provider. Do **not** apply in this lab.

### Why this lab exists

The root stays a list of calls. The cluster lives in `modules/ecs-cluster` so the service (Lab 5.5) can ask for `cluster_arn` and `capacity_provider_name` without copying IDs by hand.

You add **one slice at a time** to `main.tf` (paste each slice at the **bottom**, then save). If a slice goes wrong, skip to **Your file must look like this** and replace the whole `main.tf`.

### Procedure — folder and variables

1. In Explorer, right-click the existing `terraform` folder (Workflow 01).  
2. Open `modules` (Workflow 02). Right-click `modules` → **New Folder** → name it `ecs-cluster`.

### Slice 1 — variables

Create `terraform/modules/ecs-cluster/variables.tf`. The root will pass the VPC and the private subnets. The host sits in those subnets.

Paste:

```hcl
# Values the root will pass in.

variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}
```

Save.

### Slice 2 — the AMI

Create `terraform/modules/ecs-cluster/main.tf`. Leave it empty, then paste this slice.

AWS publishes the current ECS-optimised Amazon Linux 2 image in SSM. You do **not** pick a random AMI. This lookup runs at plan time; it does not launch a computer yet.

```hcl
# 1. Picture of the host. ECS-optimised Amazon Linux 2.

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}
```

Save.

### Slice 3 — instance IAM

**Why this is next:** the host must talk to ECS (register, pull from ECR). That is a **role on the computer**, not the task’s execution role.

Paste at the **bottom** of `main.tf`:

```hcl
# 2. Badge the EC2 host wears so the ECS agent can register and pull images.

resource "aws_iam_role" "ecs_instance" {
  name = "${var.project}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.project}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}
```

Save.

### Slice 4 — instance security group

**Why this is next:** the host needs a lock. Outbound through the NAT is enough. **No** public HTTP inbound. The **task** uses a **different** security group in Lab 5.5.

Paste at the **bottom** of `main.tf`:

```hcl
# 3. Lock on the host. Egress via NAT. No public HTTP.

resource "aws_security_group" "instance" {
  name        = "${var.project}-ecs-instance-sg"
  description = "ECS container instances - egress via NAT, no public HTTP"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-ecs-instance-sg"
  }
}
```

Save.

### Slice 5 — the cluster

**Why this is next:** ECS needs a cluster name. The host will join this name. There is still no computer.

Paste at the **bottom** of `main.tf`:

```hcl
# 4. Named cluster. ECS uses this name. Empty until a host joins.

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"

  tags = {
    Name = "${var.project}-cluster"
  }
}
```

Save.

### Slice 6 — launch template and Auto Scaling group

**Why this is next:** this is the computer. `t3.micro` in **private** subnets (back rooms). `user_data` writes `ECS_CLUSTER=...` so the agent registers in the right cluster. `desired_capacity = 1` means one host. `protect_from_scale_in = false` so `terraform destroy` can terminate it.

Paste at the **bottom** of `main.tf`:

```hcl
# 5. Launch template for the host, then the group that keeps one of them.

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project}-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(replace(<<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
  EOT
  , "\r", ""))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-ecs-instance"
    }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project}-asg"
  min_size            = 0
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  # Off so terraform destroy can terminate the instance.
  # A live production ASG often sets this true with managed termination protection.
  protect_from_scale_in = false

  tag {
    key                 = "Name"
    value               = "${var.project}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

Save.

### Slice 7 — capacity provider

**Why this is next:** the service in Lab 5.5 must **not** set `launch_type`. It asks this capacity provider for a seat on the ASG. `managed_termination_protection = DISABLED` and `managed_draining = DISABLED` match `protect_from_scale_in = false` so `terraform destroy` can terminate the instance. Leave draining on (the AWS default) and destroy sits on **Terminating:Wait** until Terraform times out.

Paste at the **bottom** of `main.tf`:

```hcl
# 6. Link the cluster to the ASG. The service will ask this provider for a seat.

resource "aws_ecs_capacity_provider" "this" {
  name = "${var.project}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"
    managed_draining               = "DISABLED"
    # Default draining is ENABLED. That adds hook ecs-managed-draining-termination-hook.
    # terraform destroy then waits on Terminating:Wait and times out. Off for this lab.

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.this.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
    base              = 1
  }
}
```

Save.

### Your file must look like this — `modules/ecs-cluster/main.tf`

If a slice went wrong, replace the whole file with this block.

```hcl
# 1. Picture of the host. ECS-optimised Amazon Linux 2.

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# 2. Badge the EC2 host wears so the ECS agent can register and pull images.

resource "aws_iam_role" "ecs_instance" {
  name = "${var.project}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.project}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

# 3. Lock on the host. Egress via NAT. No public HTTP.

resource "aws_security_group" "instance" {
  name        = "${var.project}-ecs-instance-sg"
  description = "ECS container instances - egress via NAT, no public HTTP"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-ecs-instance-sg"
  }
}

# 4. Named cluster. ECS uses this name. Empty until a host joins.

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"

  tags = {
    Name = "${var.project}-cluster"
  }
}

# 5. Launch template for the host, then the group that keeps one of them.

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project}-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(replace(<<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
  EOT
  , "\r", ""))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-ecs-instance"
    }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project}-asg"
  min_size            = 0
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  # Off so terraform destroy can terminate the instance.
  # A live production ASG often sets this true with managed termination protection.
  protect_from_scale_in = false

  tag {
    key                 = "Name"
    value               = "${var.project}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 6. Link the cluster to the ASG. The service will ask this provider for a seat.

resource "aws_ecs_capacity_provider" "this" {
  name = "${var.project}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"
    managed_draining               = "DISABLED"
    # Default draining is ENABLED. That adds hook ecs-managed-draining-termination-hook.
    # terraform destroy then waits on Terminating:Wait and times out. Off for this lab.

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.this.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
    base              = 1
  }
}
```

### Slice 8 — outputs

Create `terraform/modules/ecs-cluster/outputs.tf`. Lab 5.5 needs the cluster ARN and the capacity provider name.

`capacity_provider_name` waits for the **attachment** (`aws_ecs_cluster_capacity_providers`). The name exists as soon as the provider resource is created. The service cannot use it until it is attached to the cluster.

```hcl
# What the root (and the service module) may ask this cluster for.

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "instance_security_group_id" {
  value = aws_security_group.instance.id
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.this.name
  # Service must not start until this provider is attached to the cluster.
  depends_on = [aws_ecs_cluster_capacity_providers.this]
}
```

Save.

### Verification

- Three files under `modules/ecs-cluster`.  
- Security group descriptions use hyphens, not em dashes.  
- **Expected State:** Cluster module on disk. Nothing applied.

### Troubleshooting References

¹ **Symptom:** A slice looks wrong or Terraform will not parse later.  
  **Resolution:** Replace `modules/ecs-cluster/main.tf` with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 5.4 — Create `modules/ecs-cluster`

---

## Lab 5.5 — Create `modules/ecs-service`

### Objective

Build the task: task security group, execution role, task definition, service `desired = 1`. Task size is **256 CPU / 256 MB** so the nginx container stays small and leaves RAM on the `t3.micro` for the **ECS agent** (the agent runs on the host, not inside the task). Do **not** apply in this lab.

### Why this lab exists

The **service** is the standing order (“always one task”). The **task definition** is the instruction sheet. The **task** is one running copy. There is **no** load balancer in this module.

You add **one slice at a time** to `main.tf` (paste each slice at the **bottom**, then save). If a slice goes wrong, skip to **Your file must look like this** and replace the whole `main.tf`.

### Procedure — folder and variables

1. In Explorer, open `terraform/modules`. Right-click `modules` → **New Folder** → name it `ecs-service`.

### Slice 1 — variables

Create `terraform/modules/ecs-service/variables.tf`. The root will pass the cluster, the image URI, and the private subnets.

Paste:

```hcl
# Values the root will pass in.

variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_arn" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}

variable "image_uri" {
  type        = string
  description = "ECR URI including tag, e.g. .../accelerator:latest"
}
```

Save.

### Slice 2 — task security group

Create `terraform/modules/ecs-service/main.tf`. Leave it empty, then paste this slice.

This lock sits on the **task**, not the host. Egress only today. Workflow 06 will allow port 80 **only from the load balancer**.

```hcl
# 1. Lock on the task. Egress only until Workflow 06 adds the ALB rule.

resource "aws_security_group" "service" {
  name        = "${var.project}-svc-sg"
  description = "ECS tasks - egress only until the ALB rule is added"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-svc-sg"
  }
}
```

Save.

### Slice 3 — execution role

**Why this is next:** ECS pulls the image from ECR **as the task starts**. That is this role. It is **not** the instance role from Lab 5.4.

Paste at the **bottom** of `main.tf`:

```hcl
# 2. Badge ECS uses to pull the image and start the container.

resource "aws_iam_role" "execution" {
  name = "${var.project}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
```

Save.

### Slice 4 — task definition

**Why this is next:** this is the instruction sheet. `EC2` + `awsvpc` + port 80. **256 / 256** leaves RAM for the agent on the host. Do **not** add a load balancer block here.

Paste at the **bottom** of `main.tf`:

```hcl
# 3. Instruction sheet. Image, size, port 80. Not a running task yet.

resource "aws_ecs_task_definition" "app" {
  family                   = var.project
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution.arn
  cpu                      = "256"
  memory                   = "256"

  container_definitions = jsonencode([
    {
      name      = var.project
      image     = var.image_uri
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}
```

Save.

### Slice 5 — the service

**Why this is next:** this is the standing order: keep **one** task. It asks the **capacity provider** from Lab 5.4. Do **not** set `launch_type`. `assign_public_ip = false` — private subnets only. `force_delete = true` so `terraform destroy` does not sit 20 minutes on **DRAINING**. `ignore_changes = [task_definition]` so Workflow 08 can register a new task definition without Terraform rolling it back.

Paste at the **bottom** of `main.tf`:

```hcl
# 4. Standing order: always one task. Private subnets. No public IP.

resource "aws_ecs_service" "app" {
  name            = "${var.project}-service"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  # terraform destroy waits 20 min for INACTIVE if the service stays DRAINING.
  # Force skip that wait. Off and destroy times out.
  force_delete = true

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  # CodePipeline (Workflow 08) registers a new task definition.
  # Do not let a later terraform apply roll the service back.
  lifecycle {
    ignore_changes = [task_definition]
  }
}
```

Save.

### Your file must look like this — `modules/ecs-service/main.tf`

If a slice went wrong, replace the whole file with this block.

```hcl
# 1. Lock on the task. Egress only until Workflow 06 adds the ALB rule.

resource "aws_security_group" "service" {
  name        = "${var.project}-svc-sg"
  description = "ECS tasks - egress only until the ALB rule is added"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-svc-sg"
  }
}

# 2. Badge ECS uses to pull the image and start the container.

resource "aws_iam_role" "execution" {
  name = "${var.project}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 3. Instruction sheet. Image, size, port 80. Not a running task yet.

resource "aws_ecs_task_definition" "app" {
  family                   = var.project
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution.arn
  cpu                      = "256"
  memory                   = "256"

  container_definitions = jsonencode([
    {
      name      = var.project
      image     = var.image_uri
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# 4. Standing order: always one task. Private subnets. No public IP.

resource "aws_ecs_service" "app" {
  name            = "${var.project}-service"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  # terraform destroy waits 20 min for INACTIVE if the service stays DRAINING.
  # Force skip that wait. Off and destroy times out.
  force_delete = true

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  # CodePipeline (Workflow 08) registers a new task definition.
  # Do not let a later terraform apply roll the service back.
  lifecycle {
    ignore_changes = [task_definition]
  }
}
```

### Slice 6 — outputs

Create `terraform/modules/ecs-service/outputs.tf`. Workflow 06 will need the service security group to open port 80 from the load balancer only.

```hcl
# What the root (and Workflow 06) may ask this service for.

output "service_name" {
  value = aws_ecs_service.app.name
}

output "service_security_group_id" {
  value = aws_security_group.service.id
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}
```

Save.

### Verification

- Three files under `modules/ecs-service`.  
- **Expected State:** No ALB block in this module. No `launch_type`.

### Troubleshooting References

¹ **Symptom:** You set `launch_type`.  
  **Resolution:** Remove it. The service uses `capacity_provider_strategy` only.  
² **Symptom:** A slice looks wrong.  
  **Resolution:** Replace `modules/ecs-service/main.tf` with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 5.5 — Create `modules/ecs-service`

---

## Lab 5.6 — Call both modules from the root

### Objective

Wire the cluster and the service into the root. Do **not** apply in this lab. Lab 5.7 applies.

### Procedure

Open `terraform/main.tf`. **Keep** `vpc` and `ecr`. **Add** `ecs_cluster` then `ecs_service` underneath.

The cluster needs the VPC and the private subnets. The service needs the cluster, the capacity provider, and `image_uri` with the `:latest` tag. `depends_on = [module.ecs_cluster]` waits until the capacity provider is **attached** to the cluster. Without it, the first apply can fail with “capacity provider isn’t associated.”

### Your file must look like this — `terraform/main.tf`

If the two new calls look wrong, replace the whole file with this block. Do **not** delete `vpc` or `ecr`.

```hcl
# Root — calls only. Workflow 05 applies vpc + ecr + cluster + service.

locals {
  project = var.project
  region  = var.aws_region
}

module "vpc" {
  source  = "./modules/vpc"
  project = local.project
}

module "ecr" {
  source  = "./modules/ecr"
  project = local.project
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  project            = local.project
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "ecs_service" {
  source = "./modules/ecs-service"

  project                = local.project
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  cluster_arn            = module.ecs_cluster.cluster_arn
  capacity_provider_name = module.ecs_cluster.capacity_provider_name
  image_uri              = "${module.ecr.repository_url}:latest"

  # Wait until the capacity provider is attached to the cluster.
  depends_on = [module.ecs_cluster]
}
```

Open `terraform/outputs.tf`. **Keep** the VPC and ECR outputs. **Add** these four:

```hcl
output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "ecs_instance_security_group_id" {
  value = module.ecs_cluster.instance_security_group_id
}

output "ecs_service_name" {
  value = module.ecs_service.service_name
}

output "ecs_service_security_group_id" {
  value = module.ecs_service.service_security_group_id
}
```

Save. **Do not** `terraform apply` yet.

### Verification

- Four modules: `vpc`, `ecr`, `ecs_cluster`, `ecs_service`.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 5.6 — Call both modules from the root

---

## Lab 5.7 — Apply and wait

### Objective

Create the cluster, the host, and the service. Wait for one running task. Do not open a public URL.

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform init` does **not** start the cluster. It reads the new `ecs-cluster` and `ecs-service` modules. You should see **Terraform has been successfully initialized**.

```bash
terraform init
```

`terraform validate` is a grammar check. It still does **not** touch AWS. You should see **Success! The configuration is valid**.

```bash
terraform validate
```

`terraform plan` is the preview. It does **not** create anything yet.

Read the plan. You should see a cluster, an Auto Scaling group, a task definition, and a service. You should **not** see Terraform **creating** `aws_lb`, `aws_alb`, `aws_lb_listener`, or `aws_lb_target_group`. If you see those **resources**, stop. Do not apply. Fix Labs 5.5–5.6, then plan again.

`load_balancers = (known after apply)` on the ASG and `launch_type = (known after apply)` on the service are **computed** fields. They are **not** an ALB. Continue.

```bash
terraform plan
```

`terraform apply` is the first time this lab **builds** the cluster and service. It will show a plan again, then ask you to type `yes`. Until you type `yes`, nothing is created.

```bash
terraform apply
```

Type `yes` and press **Enter**. Wait until **Apply complete!** Then wait **3–8 minutes** more (instance register, then task start).

### See it (root)

The cluster is coming up. Do not hunt for a public URL. If the console is closed, sign in as in Lab 5.2 (account email, **N. Virginia**).

1. Top search: **ECS** → open **Elastic Container Service**.  
2. Left: **Clusters**. Open **`accelerator-cluster`**.  
   **Why it matters:** this is the named group. ECS uses this name.

3. Tab **Infrastructure**. Wait until **1** container instance is **Active**.  
   **Why it matters:** that is your `t3.micro` with the ECS agent. No Active instance = nowhere to run the task.

Lab 5.8 walks the instance, the **task**, the **service**, security groups, and proves there is **no** load balancer. Do not skip it.

### Verification

- Apply complete.  
- **Expected State:** Host coming up; orchestrator placing the task.

### Troubleshooting References

¹ **Symptom:** Plan includes `aws_lb` / `aws_alb` / `aws_lb_listener` / `aws_lb_target_group` **being created**.  
  **Resolution:** Stop. Labs 5.5–5.6 must have no ALB. Re-paste from **Your file must look like this**, then plan again.  
  `load_balancers = (known after apply)` on the ASG is **not** an ALB.  
² **Symptom:** Execution or instance role name conflict.  
  **Resolution:** Finish an old destroy, or delete leftover IAM roles named `accelerator-ecs-*` as root, then re-apply.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 5.7 — Apply and wait

---

## Lab 5.8 — See the instance and the task (root)

### Objective

See the EC2 host, the service, and the one running task. There is **no** ALB yet.

### Procedure

If the console is still open from Lab 5.7, skip to step 4. If not:

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → account **email** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

**Cluster**

4. Top search: **ECS** → **Elastic Container Service**.  
5. Left: **Clusters** → **`accelerator-cluster`**.  
   **Why it matters:** everything below belongs to this cluster.

**The computer (EC2), not the task**

6. Tab **Infrastructure**. Wait until **1** container instance is **Active**.  
7. Top search: **EC2** → **Instances**. Find **`accelerator-ecs-instance`**. State **running**.  
8. Open it. **Public IPv4** should be **blank** (or “-” / none). Subnet should be **private**.  
   **Why it matters:** this is the host in a back room. Visitors must never reach it. No public IP is correct.

9. **EC2 → Security Groups → `accelerator-ecs-instance-sg`**. Inbound: **no** HTTP from `0.0.0.0/0`.  
   **Why it matters:** this lock is on the **host**. The **task** uses a **different** security group (`accelerator-svc-sg`). Do not open 80 here.

**Service = the standing order**

10. Back to **ECS → Clusters → `accelerator-cluster` → Services** → **`accelerator-service`**.  
11. Wait until **Running tasks = 1** (desired = 1).  
    **Why it matters:** the **service** is not the app. It is the standing order: keep one task. If that task dies, start another.

**Task = one running copy**

12. Tab **Tasks**. Open the running task. **Last status** = **RUNNING**.  
13. **Task definition** family is **`accelerator`**. That is the instruction sheet (image, port 80).  
14. Network: ENI in a **private** subnet.  
    **Why it matters:** the **task** is the running copy of the app. Private. No URL.

15. **EC2 → Security Groups → `accelerator-svc-sg`**.  
    - Inbound: **no** `0.0.0.0/0`.  
    - Inbound: **no** ALB SG yet.  
    - Outbound: present (pulls through the NAT).  
    **Why it matters:** this lock is on the **task**, not the host. Workflow 06 will allow port 80 **only from the load balancer**.

**No reception yet**

16. Top search: **EC2** → **Load Balancers**. There is **no** `accelerator-alb`.  
    **Why it matters:** no public door. A browser timeout is expected. Do not “fix” it by opening the instance to the internet.

If **Running** stays **0**:

17. **Tasks** → filter **Stopped**. Open the stopped task. Read **Stopped reason**.  
18. `CannotPullContainerError` → registry empty or wrong URI → Lab 5.3.  
19. No capacity → instance not Active yet → wait, then Infrastructure again.

### Verification

- One Active instance. Running = 1. Task SG egress only. No ALB.  
- **Expected State:** Running = 1. No public URL.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 5.8 — See the instance and the task (root)

---

## Lab 5.9 — Destroy

Keep the `.tf` files. **Always** run this lab. Do not leave the stack up for Workflow 06. Workflow 06 will apply again.

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform destroy` tears down vpc, ecr, the cluster, the host, and the service. It will ask you to type `yes`. Until you type `yes`, nothing is deleted. Files in `terraform/` stay.

Slice 7 set `managed_draining = DISABLED` so this should **not** sit on **Terminating:Wait**. Slice 5 set `force_delete = true` so Terraform should **not** sit 20 minutes on service **DRAINING**. If destroy still hangs on **DRAINING** for more than about **10 minutes**, and the instance is **InService** (not Terminating:Wait), use Troubleshooting ². If you see **Terminating:Wait**, use Troubleshooting ¹. Do **not** wait for the 20-minute timeout.

```bash
terraform destroy
```

Type `yes` and press **Enter**. Wait until **Destroy complete!** NAT and instance hours stop only after that line.

### See it (root)

Same sign-in as Lab 5.8 if the console is closed: [https://console.aws.amazon.com](https://console.aws.amazon.com) → **Root user** → account email → **N. Virginia**.

1. **ECS → Clusters** — `accelerator-cluster` **gone**.  
2. **EC2 → Instances** — `accelerator-ecs-instance` **terminated** (or gone).  
3. **VPC → NAT gateways** — NAT **gone**.  
4. **ECR → Repositories** — `accelerator` **gone**.  
5. **EC2 → Security Groups** — `accelerator-ecs-instance-sg` and `accelerator-svc-sg` **gone**.  
   **Why it matters:** cluster, registry, and NAT were hourly. Files in `terraform/` stay. Workflow 06 applies again.

### Verification

- Cloud dead. Files stay.  
- **Expected State:** Safe to walk away.

### Troubleshooting References

¹ **Symptom:** Instance **Lifecycle** = **Terminating:Wait**. Hook name `ecs-managed-draining-termination-hook`. Terraform then times out (~20 min). NAT may already be gone.  
  **Cause:** `managed_draining` is still **ENABLED** (AWS default). Slice 7 must set it **DISABLED**.  
  **Resolution (root console):**  
  1. **EC2 → Auto Scaling Groups → `accelerator-asg` → Instance management**.  
  2. Instance **Lifecycle** = **Terminating:Wait**.  
  3. Select the instance → **Actions → Complete lifecycle action → Continue**.  
  4. Terminal: `terraform destroy` again. Type `yes`. Wait for **Destroy complete!**  
  **CLI instead of the console:**  
  `aws autoscaling update-auto-scaling-group --auto-scaling-group-name accelerator-asg --min-size 0 --max-size 0 --desired-capacity 0 --region us-east-1`  
  Then **EC2 → Instances** — copy the instance id (`i-...`) still in **Terminating:Wait**, then:  
  `aws autoscaling complete-lifecycle-action --lifecycle-hook-name ecs-managed-draining-termination-hook --auto-scaling-group-name accelerator-asg --lifecycle-action-result CONTINUE --instance-id i-REPLACE --region us-east-1`  
  Then `terraform destroy` again.

² **Symptom:** Destroy sits on `accelerator-service` **DRAINING** for more than about 10 minutes. Running = 0. Instance **InService**. **No** lifecycle hook. **No** Terminating:Wait. NAT may already be gone. Terraform then times out at **20 minutes**.  
  **Cause:** Terraform waits for the service to become **INACTIVE**. `managed_draining = DISABLED` stops the hook, so Troubleshooting ¹ does **not** match.  
  **Resolution:** In a **new** terminal (leave destroy running, or run this after it timed out):  
  `aws ecs delete-service --cluster accelerator-cluster --service accelerator-service --force --region us-east-1`  
  Then scale the host to zero:  
  `aws autoscaling update-auto-scaling-group --auto-scaling-group-name accelerator-asg --min-size 0 --max-size 0 --desired-capacity 0 --region us-east-1`  
  Then `terraform destroy` again. Type `yes`. Wait for **Destroy complete!**  
  **Why it matters:** the printed Terminating:Wait steps will not find a hook. `--force` is the unstick for this wait.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 5.9 — Destroy

---

### Workflow Completion Criteria

- [ ] VPC + ECR applied; image **pushed**  
- [ ] `modules/ecs-cluster` and `modules/ecs-service` authored by you  
- [ ] **Infrastructure** shows **1 Active** instance (private, no public IP)  
- [ ] **accelerator-service** shows **Running tasks = 1**  
- [ ] **accelerator-svc-sg** has no public inbound  
- [ ] **EC2 → Load Balancers** has no accelerator ALB  
- [ ] You did **not** need a browser URL  
- [ ] Destroy completed  

### Where We Are Going Next

Visitors still cannot enter. **Workflow 06** adds the ALB in public subnets, **`accelerator-alb-sg`**, and an inbound rule on **`accelerator-svc-sg`**: port 80 **only from the ALB SG**. Then you open `http://<alb-dns>`.

### Restart next time

1. `terraform apply` (vpc + ecr + ecs_cluster + ecs_service)  
2. **Build + push** the image  
3. Wait for Running = 1  
4. Then add the ALB module  

### Common Errors & Resolutions (Workflow 05)

| # | Error / symptom | Likely cause | Resolution |
|---|-----------------|--------------|------------|
| 1 | Running = 0, `CannotPullContainerError` | Empty ECR or bad URI | Lab 5.3; `image_uri` = `url:latest` |
| 2 | 0 container instances | Agent not registered | Wait; check user_data `ECS_CLUSTER`; instance in private subnet |
| 3 | `launch_type` conflicts with capacity provider | Both set | Remove `launch_type` |
| 4 | Capacity provider isn’t associated | Service started before the attachment | Confirm `depends_on` on `module.ecs_service` (Lab 5.6) and on `capacity_provider_name` (Lab 5.4). Re-apply. |
| 5 | Browser timeout / no DNS | Expected | No ALB in this workflow |
| 6 | Opened 80 on instance SG | Wrong SG | Task uses `accelerator-svc-sg` |
| 7 | Task SG already allows `0.0.0.0/0` | You “fixed” it early | Remove that rule; W06 uses ALB SG as source |
| 8 | Role name exists | Old stack | Finish destroy; delete orphan role |
| 9 | InvalidParameterValue on SG description | Em dash in description | Use a hyphen |
| 10 | Wrong region | Console not N. Virginia | Switch region |
| 11 | Left NAT + EC2 up | Skipped destroy | `terraform destroy` now |
| 12 | Destroy timeout on Terminating:Wait | `managed_draining` still ENABLED (AWS default) | Confirm Slice 7 has `managed_draining = "DISABLED"`. Unstick: Lab 5.9 Troubleshooting ¹ |
| 13 | Destroy sits on service **DRAINING**, instance **InService**, no hook | Terraform waiter for **INACTIVE** (~20 min) | Confirm Slice 5 has `force_delete = true`. Unstick now: Lab 5.9 Troubleshooting ² (`delete-service --force`) |

### Workflow Summary

Workflow 05 solved “there is no runtime and no workload.”  
The next problem is “there is no public URL.” Workflow 06 adds the ALB and the allow-list between ALB and task.

Open `workflow 6 - Load Balancing and Security.md` when you are ready.
