# Workflow 06 — Load Balancing & Security
## Add the edge. Tighten the allow-lists. Open http.

**Programme:** AWS Graduate Cloud Skills Accelerator  
**Region:** `us-east-1` only  
**Prefix:** `accelerator`  
**Project:** the `accelerator-app` folder  

---

# Workflow Overview

Workflow 05 started the workload in private subnets. There was no public URL. This chapter puts an **Application Load Balancer** on the public subnets and locks the task so **only the ALB** may speak to it.

Then you open **`http://<alb-dns>`** — `http`, not https — and prove the page.

---

### The 5 Codewrkx Engineer Questions

**What is the problem?**  
The app is running in a **private subnet** (a **back room**). Visitors have no address. Nobody can knock.

A **region** is a geographic AWS location — a cluster of **data centres**. Light picture: the **city** (N. Virginia). An **Availability Zone (AZ)** is an isolated data centre inside that region. Light picture: a **district**. **Not** a house. **Not** a room. An Application Load Balancer must sit in **two public subnets** — two AZs, two districts — so if one data centre fails, the other can still answer. That is **high availability**. You still use **one** NAT (service exit) to keep the bill down.

**Why solve it with these services?**  
An **ALB (Application Load Balancer)** is **reception**. Path: internet → **Internet Gateway (front gate)** → **ALB** → **task**. Visitors never get the private address. Putting a public IP on the **EC2 (Elastic Compute Cloud)** host would work — and is how juniors get hacked. **Security groups** are **locks** on doors: the internet may knock on reception; only reception may speak to the task.

**When are these services used?**  
When something private must be reachable on HTTP. Every visitor request hits the ALB. You do not create a new load balancer per page load.

**How does this work?**  
Bring the house (VPC), registry (ECR), cluster, and service back, push `accelerator:latest`, add an `alb` module, then:

| Command | Today |
|---------|--------|
| `terraform init` | Read the new module. |
| `terraform validate` | Grammar check. |
| `terraform plan` | Preview: ALB, target group (type **IP**), listener `:80`, inbound 80 on the task **only from the ALB**. Confirm **one** NAT. |
| `terraform apply` | Build reception. Type `yes`. |
| `terraform output app_url` | Copy the **`http://`** address. |
| `terraform destroy` | Take reception, cluster, and NAT down. Terraform files stay. |

Walk the console as root (N. Virginia). Open **`http://`** — there is no certificate.

**Who typically deploys them?**  
Networking or platform engineers own the ALB and security groups. You still do it here. The browser is the visitor. Root **looks**. `accelerator-cli` **applies** and **destroys**.

---

### Where We Came From

You proved **Running tasks = 1** with `accelerator-svc-sg` on **egress only**. No load balancer. No URL. You destroyed the stack at the end of Workflow 05. AWS is empty.

### Where We Are Now

You will bring the stack back, restock the image, add `modules/alb`, wire the service to the target group, add the **ALB → task** security group rule, and verify healthy targets as root.

### Where We Are Going

The edge will work. Workflow 07 is not a new module — it is a full **launch** on purpose: apply everything you already wrote and prove the URL again.

### Launch context

Put the ALB on public subnets. `accelerator-alb-sg` allows inbound 80 from the internet. `accelerator-svc-sg` allows inbound 80 **only from the ALB SG**. The internet does not reach the task directly.

### Technical Context

| Resource | Responsibility |
|-------|----------|
| ALB `accelerator-alb` | Public HTTP edge. Two public subnets (two AZs). |
| ALB SG `accelerator-alb-sg` | Inbound **80** from `0.0.0.0/0`. Outbound to tasks. |
| Target group (type **IP**) | `awsvpc` tasks register by IP, not by instance port. |
| Listener `:80` | Forward to that target group. |
| Rule on `accelerator-svc-sg` | Inbound **80** **only** from the ALB SG. |

**Why the rule lives on the service module, not inside `modules/alb`:**  
If the ALB module needed the task SG **and** the service module needed the target group, Terraform would form a **cycle**. The ALB module stays independent. The service module **receives** `target_group_arn` and `alb_security_group_id`. The inbound rule is attached to the SG you created in Workflow 05.

**HTTP only.** No ACM certificate. Browsers that force `https://` will fail. Use the URL Terraform prints.

ALB hours are **not** free to leave running. Destroy at the end of the sitting.

### Why This Workflow Matters

This is the sentence employers want: “The internet hits the load balancer. The task is not public. Security groups enforce that.”

### What We Will Build

Module `alb`, a service update, and a working `http://` URL (then destroyed).

### Architecture Snapshot

When [`architecture.png`](architecture.png) is in this Accelerator folder, that is the full drawing. If it is not there yet, use the text snapshot below.

```text
Internet  :80
    │
    ▼
accelerator-alb-sg  →  accelerator-alb  (public subnets)
    │
    │  :80  source = ALB SG only
    ▼
accelerator-svc-sg  →  task :80  (private, awsvpc)

Instance SG still has no public HTTP.
```

### SOFTWARE DELIVERY PROGRESS: ✓ 0 Intro → ✓ 01 Access → ✓ 02 VPC → ✓ 03 Docker → ✓ 04 ECR → ✓ 05 ECS → ► 06 ALB → □ 07 Prove → □ 08 Pipeline

### Learning Outcomes

- Place an internet-facing ALB on public subnets  
- Use target type **IP** with `awsvpc`  
- Prove the SG pair in the console  
- Open the app over **http**  

### Key Terminology

| Term | Meaning |
|------|---------|
| ALB | Layer-7 load balancer (HTTP) |
| Target group | Set of tasks the listener forwards to |
| Target type IP | Register task ENIs, not EC2 instance IDs |
| Listener | Port + protocol on the ALB |
| Health check | ALB asks `GET /` on port 80 |
| Source SG | Inbound rule that names another security group, not a CIDR |

### Labs

Tick as you finish. Change `- [ ]` to `- [x]`.

- [ ] Lab 6.1 — Confirm CLI and Docker
- [ ] Lab 6.2 — Bring the stack back (no ALB yet)
- [ ] Lab 6.3 — Create `modules/alb`
- [ ] Lab 6.4 — Attach the service to the target group
- [ ] Lab 6.5 — Call the ALB from the root
- [ ] Lab 6.6 — Apply the ALB
- [ ] Lab 6.7 — See the ALB and security groups (root)
- [ ] Lab 6.8 — Open the URL in a browser
- [ ] Lab 6.9 — Save the Terraform files (not the state)
- [ ] Lab 6.10 — Destroy

---

## Lab 6.1 — Confirm CLI and Docker

### Procedure

Open a terminal in the **accelerator-app** folder.

`aws sts get-caller-identity` asks AWS: “who am I?” It does **not** create anything. The `Arn` must contain `user/accelerator-cli`. If it contains `root`, stop. Workflow 01 Labs 1.2–1.3.

```bash
aws sts get-caller-identity
```

Docker Desktop must be **running**. You will build and push in Lab 6.2.

### See it (root)

Confirm the window you will use after apply. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → **email that owns the account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.  
   **Why it matters:** Lab 6.2 looks here. Wrong city = empty VPC list after apply.

### Verification

- CLI Arn contains `user/accelerator-cli`. Docker running. Console is N. Virginia as the account email.  
- **Expected State:** Ready to apply and push.

### Troubleshooting References

¹ **Symptom:** Root keys or Docker down.  
  **Resolution:** Workflow 01 Labs 1.2–1.3; Workflow 03 Lab 3.1.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.1 — Confirm CLI and Docker

---

## Lab 6.2 — Bring the stack back (no ALB yet)

### Objective

Apply vpc + ecr + ecs_cluster + ecs_service. Wait for **Running = 1**. Image must be in the registry.

`terraform/main.tf` should **not** call `module "alb"` yet. The four module calls from Workflow 05 stay as they are.

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform init` does **not** start the cluster. It re-reads vpc, ecr, ecs-cluster, and ecs-service. You should see **Terraform has been successfully initialized**.

```bash
terraform init
```

`terraform validate` is a grammar check. It still does **not** touch AWS. You should see **Success! The configuration is valid**.

```bash
terraform validate
```

`terraform plan` is the preview. It does **not** create anything yet.

Read the plan. You should see vpc, ecr, cluster, and service. You should **not** see a load balancer. If you see an ALB, stop. Do not apply.

```bash
terraform plan
```

`terraform apply` is a **full** apply of those four modules. **NAT comes back; the clock starts.** There is still **no** load balancer. It will ask you to type `yes`. Until you type `yes`, nothing is created.

```bash
terraform apply
```

Type `yes` and press **Enter**. Wait until **Apply complete!**

### See it (root) — after apply

The house, registry, and cluster are back. There is still **no** reception. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
   (or [https://aws.amazon.com](https://aws.amazon.com) → **Sign in to the Console**).  
2. **Root user** → **email that owns the account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

4. Top search: **VPC** → **Your VPCs** → **`accelerator-vpc`**.  
   **Why it matters:** same house as Workflow 05. Reception in Lab 6.6 will sit on the **public** subnets (front rooms).

5. Left: **NAT gateways** → **`accelerator-nat`**. State **Available**. **One** row.  
   **Why it matters:** the host still has no public IP. Pulls go through this service exit (NAT). The clock is running.

6. Top search: **ECR** → **Repositories** → **`accelerator`**. The registry exists. It is often **empty** until you push below.  
   **Why it matters:** destroy in Workflow 05 deleted `latest`. Empty registry = `CannotPullContainerError` until the next step.

7. Top search: **EC2** → **Load Balancers**. There is **no** `accelerator-alb`.  
   **Why it matters:** this apply is vpc + ecr + ecs only. Do not hunt for a URL yet.

### Procedure — restock the registry

**Running = 0** / `CannotPullContainerError` until you push is expected. Destroy in Workflow 05 deleted the image.

Docker Desktop must be **running**. Work from the **accelerator-app** root (not `terraform/`). If you are still in `terraform/`:

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

`docker tag` points the local image at the registry. It does **not** upload yet. Replace `ACCOUNT_ID`.

```bash
docker tag accelerator:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

`docker push` puts `latest` in the registry. Replace `ACCOUNT_ID`. Empty registry = the task stays at Running = 0.

```bash
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

### See it (root) — after push

If the console is closed, sign in again (Lab 6.2 steps 1–3). Region **N. Virginia**.

1. **ECR → Repositories → `accelerator`**. Tag **`latest`** is listed.  
   **Why it matters:** the task can pull now.

2. **ECS → Clusters → `accelerator-cluster` → Services → `accelerator-service`**.  
   Wait until **Running tasks = 1**.  
   **Why it matters:** ECS retries the pull after the push. One running task — still no public door.

3. **EC2 → Load Balancers** — still **no** `accelerator-alb`.  
   **Why it matters:** Lab 6.6 adds reception. A browser timeout now is correct.

### Verification

- **ECR → `accelerator` → `latest`**.  
- **Running tasks = 1**.  
- **EC2 → Load Balancers** — still no `accelerator-alb`.  
- **Expected State:** Task running. No ALB yet.

### Troubleshooting References

¹ **Symptom:** Cannot pull / Running = 0.  
  **Resolution:** Workflow 05 Labs 5.3 and 5.8.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.2 — Bring the stack back (no ALB yet)

---

## Lab 6.3 — Create `modules/alb`

### Objective

Build reception: ALB security group, the load balancer on two public subnets (front rooms), a target group (type **IP**), and a listener on port 80. Do **not** mention the task security group here. Do **not** apply in this lab.

### Why this lab exists

The root stays a list of calls. Reception lives in `modules/alb` so the service (Lab 6.4) can **receive** `target_group_arn` and `alb_security_group_id`. If this module also asked for the task SG, Terraform would form a **cycle**.

You add **one slice at a time** to `main.tf` (paste each slice at the **bottom**, then save). If a slice goes wrong, skip to **Your file must look like this** and replace the whole `main.tf`.

### Procedure — folder and variables

1. In Explorer, right-click the existing `terraform` folder (Workflow 01).  
2. Open `modules`. Right-click `modules` → **New Folder** → name it `alb`.

### Slice 1 — variables

Create `terraform/modules/alb/variables.tf`. The root will pass the house (`vpc_id`) and the **public** subnets (front rooms). Reception sits behind the front gate, not in a back room.

Paste:

```hcl
# Values the root will pass in. Public subnets = two AZs (two districts) for high availability.

variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}
```

Save.

### Slice 2 — ALB security group

Create `terraform/modules/alb/main.tf`. Leave it empty, then paste this slice.

This is the only lock the **internet** may knock on. Inbound 80 from `0.0.0.0/0`. The task still stays closed.

```hcl
# 1. Lock on reception. Internet may knock here. Nowhere else.

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Public HTTP to the ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-alb-sg"
  }
}
```

Save.

### Slice 3 — the load balancer

**Why this is next:** this is reception. `internal = false` means internet-facing. `subnets` are the **public** subnets (front rooms) from Workflow 02 — two Availability Zones. There is still no listener.

Paste at the **bottom** of `main.tf`:

```hcl
# 2. Reception itself. Public HTTP. Two front rooms. Not a back room.

resource "aws_lb" "this" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project}-alb"
  }
}
```

Save.

### Slice 4 — target group (type IP)

**Why this is next:** reception needs a list of task addresses to forward to. `target_type = "ip"` because `awsvpc` tasks have their own address. **`instance` is wrong** — that would aim at the EC2 host. Health check is `GET /` on port 80 over **HTTP**.

Paste at the **bottom** of `main.tf`:

```hcl
# 3. Who reception forwards to. Task ENI addresses, not the EC2 instance ID.

resource "aws_lb_target_group" "app" {
  name        = "${var.project}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project}-tg"
  }
}
```

Save.

### Slice 5 — listener on port 80

**Why this is next:** this is the knock on reception. Port 80, protocol **HTTP**. No certificate. It forwards to the target group. Do **not** attach the task SG here.

Paste at the **bottom** of `main.tf`:

```hcl
# 4. Port 80 on reception. Forward to the target group. HTTP only.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

Save.

### Your file must look like this — `modules/alb/main.tf`

If a slice went wrong, replace the whole file with this block.

```hcl
# 1. Lock on reception. Internet may knock here. Nowhere else.

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Public HTTP to the ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-alb-sg"
  }
}

# 2. Reception itself. Public HTTP. Two front rooms. Not a back room.

resource "aws_lb" "this" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project}-alb"
  }
}

# 3. Who reception forwards to. Task ENI addresses, not the EC2 instance ID.

resource "aws_lb_target_group" "app" {
  name        = "${var.project}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project}-tg"
  }
}

# 4. Port 80 on reception. Forward to the target group. HTTP only.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

### Slice 6 — outputs

Create `terraform/modules/alb/outputs.tf`. Lab 6.4 needs the target group ARN and the ALB security group id. Lab 6.8 needs the DNS name.

```hcl
# What the root (and the service module) may ask this ALB for.

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}
```

Save.

### Verification

- Three files under `modules/alb`.  
- **Expected State:** ALB module on disk. Not applied yet.

### Troubleshooting References

¹ **Symptom:** `target_type = "instance"`.  
  **Resolution:** Must be **`ip`** for `awsvpc`. Replace `modules/alb/main.tf` with **Your file must look like this**.  
² **Symptom:** A slice looks wrong.  
  **Resolution:** Replace `modules/alb/main.tf` with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.3 — Create `modules/alb`

---

## Lab 6.4 — Attach the service to the target group

### Objective

Register the service with the target group. Allow port 80 **from the ALB SG only**. Do **not** apply in this lab.

### Why this lab exists

The ALB must not ask for the task lock. The service **receives** the ALB’s id. That avoids a Terraform cycle. Defaults stay `""` so the blocks stay off until Lab 6.5 passes real values.

This lab **edits** files you already wrote in Workflow 05. If a slice goes wrong, skip to **Your file must look like this**.

### Slice 1 — two new variables

Open `terraform/modules/ecs-service/variables.tf`. Paste these two at the **bottom**. Do **not** delete the variables from Lab 5.5.

```hcl
# Empty until the root passes the ALB. Defaults let a service-only apply still work.

variable "target_group_arn" {
  type        = string
  description = "ALB target group. Empty until Workflow 06."
  default     = ""
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB SG. Empty until Workflow 06."
  default     = ""
}
```

Save.

### Your file must look like this — `modules/ecs-service/variables.tf`

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

# Empty until the root passes the ALB. Defaults let a service-only apply still work.

variable "target_group_arn" {
  type        = string
  description = "ALB target group. Empty until Workflow 06."
  default     = ""
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB SG. Empty until Workflow 06."
  default     = ""
}
```

### Slice 2 — register with the ALB

**Why this is next:** the service must tell ECS “this task belongs to that target group.” `container_name` must be `accelerator` (same as the task definition). `health_check_grace_period_seconds = 60` gives nginx time before the ALB marks it unhealthy.

This host is one `t3.micro`. It has **two** ENIs: one for the instance, one for **one** `awsvpc` task. The AWS default deploy is **200% / 100%** — that tries a **second** task while the first is still running. The second task sits in **PROVISIONING**. The target group stays empty. Set **100 / 0**: stop the old task, then start the new one. The URL may go dark for a few minutes. That is expected.

Open `terraform/modules/ecs-service/main.tf`. Find `resource "aws_ecs_service" "app"`. **Inside** that resource, **after** `desired_count = 1`, paste this slice. Keep `force_delete`, `capacity_provider_strategy`, `network_configuration`, and `lifecycle`. Do **not** paste this at the bottom of the file.

```hcl
  # One t3.micro + awsvpc: two ENIs (host + one task). Default 200/100 tries a second
  # task and stalls in PROVISIONING. 100/0 = stop old, then start new.
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.project
    container_port   = 80
  }
```

Save.

### Slice 3 — inbound 80 from the ALB only

**Why this is next:** this is the lock on the **task**. Source is another security group, **not** `0.0.0.0/0`. Lab 6.5 always passes `alb_security_group_id`. Do **not** wrap this rule in `count`. Terraform cannot plan `count` from an id that does not exist yet (**Invalid count argument**). One `terraform apply` in Lab 6.6 creates the ALB SG, then this rule.

Paste at the **bottom** of `modules/ecs-service/main.tf`:

```hcl
# 5. Inbound 80 on the task lock. Source = ALB SG only. Lab 6.5 always passes the id.

resource "aws_security_group_rule" "alb_http_in" {
  type                     = "ingress"
  description              = "HTTP from the ALB only"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.service.id
  source_security_group_id = var.alb_security_group_id
}
```

Save.

### Your file must look like this — `modules/ecs-service/main.tf`

If a slice went wrong, replace the whole file with this block.

```hcl
# 1. Lock on the task. Egress always. Inbound 80 is the separate rule at the bottom.

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

  # One t3.micro + awsvpc: two ENIs (host + one task). Default 200/100 tries a second
  # task and stalls in PROVISIONING. 100/0 = stop old, then start new.
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.project
    container_port   = 80
  }

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

# 5. Inbound 80 on the task lock. Source = ALB SG only. Lab 6.5 always passes the id.

resource "aws_security_group_rule" "alb_http_in" {
  type                     = "ingress"
  description              = "HTTP from the ALB only"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.service.id
  source_security_group_id = var.alb_security_group_id
}
```

### Verification

- Lab 6.5 will pass `target_group_arn` and `alb_security_group_id`. Do **not** apply until then.  
- **Expected State:** Service module is ready to attach to the ALB.

### Troubleshooting References

¹ **Symptom:** You set `cidr_blocks = ["0.0.0.0/0"]` on the task SG.  
  **Resolution:** Delete that. Source must be the ALB SG.  
² **Symptom:** A slice looks wrong.  
  **Resolution:** Replace `modules/ecs-service/main.tf` (and `variables.tf`) with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.4 — Attach the service to the target group

---

## Lab 6.5 — Call the ALB from the root

### Objective

Wire the ALB into the root and pass its ids to the service. Do **not** apply in this lab. Lab 6.6 applies.

### Procedure

Open `terraform/main.tf`. **Keep** `vpc`, `ecr`, `ecs_cluster`, and `ecs_service`. **Add** `module "alb"` (public subnets). Then **update** `module "ecs_service"` so it receives `target_group_arn` and `alb_security_group_id`.

The service depends on the ALB. The ALB must **not** depend on the service.

### Your file must look like this — `terraform/main.tf`

If the two new lines look wrong, replace the whole file with this block. Do **not** delete `vpc`, `ecr`, or the ECS modules.

```hcl
# Root — calls only. Workflow 06 applies vpc + ecr + cluster + service + alb.

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

module "alb" {
  source = "./modules/alb"

  project           = local.project
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "ecs_service" {
  source = "./modules/ecs-service"

  project                = local.project
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  cluster_arn            = module.ecs_cluster.cluster_arn
  capacity_provider_name = module.ecs_cluster.capacity_provider_name
  image_uri              = "${module.ecr.repository_url}:latest"

  target_group_arn      = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id

  # Wait until the capacity provider is attached to the cluster.
  depends_on = [module.ecs_cluster]
}
```

Open `terraform/outputs.tf`. **Keep** the VPC, ECR, and ECS outputs. **Add** this one. Lab 6.8 opens it in a browser. It must start with `http://`.

```hcl
output "app_url" {
  description = "Open with http — not https"
  value       = "http://${module.alb.alb_dns_name}"
}
```

Save. **Do not** `terraform apply` yet.

### Verification

- Five modules. `ecs_service` depends on `alb`. `alb` does **not** depend on `ecs_service`.  
- **Expected State:** Graph is valid.

### Troubleshooting References

¹ **Symptom:** `Cycle: module.alb, module.ecs_service`.  
  **Resolution:** ALB module must not take `service_security_group_id`. Replace `terraform/main.tf` with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.5 — Call the ALB from the root

---

## Lab 6.6 — Apply the ALB

### Objective

Build reception. Wait for a healthy target. Do not open the browser yet — that is Lab 6.8.

### Procedure

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform init` does **not** build the ALB. It reads the new `alb` module. You should see **Terraform has been successfully initialized**.

```bash
terraform init
```

`terraform validate` is a grammar check. It still does **not** touch AWS. You should see **Success! The configuration is valid**. If you see `Cycle`, stop. Labs 6.3–6.5.

```bash
terraform validate
```

`terraform plan` is the preview. It does **not** create anything yet. **One** plan. **No** `-target`.

Read the plan. You should see one ALB, one target group (`ip`), one listener, and one ingress rule on the task SG. You should see **one** NAT (already there — not a second one). If you see two NATs, or `target_type = instance`, stop. Do not apply.

If plan dies with **Invalid count argument** on `alb_http_in`, your file still has `count =`. Replace `modules/ecs-service/main.tf` from Lab 6.4 **Your file must look like this**, then plan again.

```bash
terraform plan
```

`terraform apply` is the first time this lab **builds** reception. It will show a plan again, then ask you to type `yes`. Until you type `yes`, nothing is created. **No** `-target`.

```bash
terraform apply
```

Type `yes` and press **Enter**. Wait until **Apply complete!**

Attaching the ALB uses **100 / 0**: the old task stops, then the new one starts. The target group may be **empty** for a few minutes. That is expected. Do **not** add a second task by hand.

`terraform output app_url` prints the visitor address. It does **not** change AWS. Copy it. It must start with `http://`. Wait **2–5 minutes** for targets to go **healthy**. Do not open the browser yet — that is Lab 6.8.

```bash
terraform output app_url
```

### See it (root)

Reception exists. If the console is closed, sign in as in Lab 6.2 (account email, **N. Virginia**).

1. Top search: **EC2** → **Load Balancers**. Open **`accelerator-alb`**. State should become **Active**.  
   **Why it matters:** this is the public door. Its DNS name is what `app_url` printed.

2. **EC2 → Target Groups → `accelerator-tg` → Targets**. One IP may still be **initial** / **unhealthy**. Wait and refresh.  
   **Why it matters:** the ALB asks `GET /` before it will serve visitors. Lab 6.7 walks the full path and the security groups.

3. Confirm **one** NAT still (**VPC → NAT gateways**).  
   **Why it matters:** two public subnets for the ALB does **not** mean two NAT gateways.

### Verification

- Apply complete. `app_url` starts with `http://`.  
- You saw **`accelerator-alb`** as the account email.  
- **Expected State:** ALB created. Health checks in progress.

### Troubleshooting References

¹ **Symptom:** `Cycle: module.alb, module.ecs_service`.  
  **Resolution:** Stop. ALB module must not take the task SG. Re-paste Labs 6.3–6.5 **Your file must look like this**.  
² **Symptom:** Plan shows two NATs.  
  **Resolution:** Stop. Do not apply. Workflow 02 has one NAT.  
³ **Symptom:** ALB name already exists.  
  **Resolution:** Old ALB not destroyed. Destroy leftovers, then apply.  
⁴ **Symptom:** **Invalid count argument** on `alb_http_in`.  
  **Resolution:** `count` cannot use an ALB SG id that is unknown until apply. Replace Lab 6.4 **Your file must look like this** (no `count`). One full `terraform apply`. Do **not** `"-target=module.alb"` — from an empty account that skips the Internet Gateway.  
⁵ **Symptom:** New task stuck **PROVISIONING**. Target group **empty**.  
  **Resolution:** Default 200/100 tried two `awsvpc` tasks on one `t3.micro` (ENI limit 2). Confirm `deployment_maximum_percent = 100` and `deployment_minimum_healthy_percent = 0`. ECS → service → **Tasks** → stop the extra **PROVISIONING** task if it is still there. Wait for one **RUNNING** task, then one **healthy** target.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.6 — Apply the ALB

---

## Lab 6.7 — See the ALB and security groups (root)

### Objective

Walk reception, the two public subnets (front rooms), the locks, and the one task the ALB is allowed to talk to.

### Procedure

If the console is still open from Lab 6.6, skip to step 4. If not:

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → account **email** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

**Reception**

4. Top search: **EC2** → **Load Balancers** → **`accelerator-alb`**. State **Active**. Scheme **internet-facing**.  
   **Why it matters:** visitors hit this name, not the EC2 host.

5. Tab **Listeners**. **80:HTTP** forwards to **`accelerator-tg`**.  
   **Why it matters:** HTTP only. There is no certificate. Lab 6.8 must stay on `http://`.

6. Tab **Network mapping** (or **Availability Zones**). The ALB sits in **two public** subnets — **`accelerator-public-a`** and **`accelerator-public-b`**.  
   **Why these subnets:** front rooms, not back rooms. An Application Load Balancer must span **two Availability Zones** (two districts). That is why Workflow 02 drew two public subnets. Private subnets are not listed here.

**Who reception forwards to**

7. Top search: **EC2** → **Target Groups** → **`accelerator-tg`**. Target type **IP** (not instance).  
   **Why it matters:** `awsvpc` tasks have their own ENI. The ALB talks to the **task** address, not the EC2 instance ID.

8. Tab **Targets**. One IP, port **80**, state **healthy** (refresh; wait).  
   **Why it matters:** healthy = `GET /` on port 80 succeeded. Unhealthy = the URL in Lab 6.8 will time out.

9. Health check path should be **`/`**.  
   **Why it matters:** the app’s landing page is `/`. A wrong path marks the only task unhealthy.

**Locks**

10. **EC2 → Security Groups → `accelerator-alb-sg`**. Inbound: **80** from `0.0.0.0/0`.  
    **Why it matters:** anyone may knock on reception. That is the only place the internet is allowed in.

11. **EC2 → Security Groups → `accelerator-svc-sg`**. Inbound: **80**, source **`accelerator-alb-sg`** (a security group name, **not** `0.0.0.0/0`).  
    **Why it matters:** the task accepts HTTP only from the ALB. The internet cannot skip reception.

12. **EC2 → Security Groups → `accelerator-ecs-instance-sg`**. Still **no** inbound 80 from the internet.  
    **Why it matters:** this lock is on the **host**. Opening 80 here would be the junior mistake. The ALB never needed it.

**Task still private**

13. **EC2 → Instances → `accelerator-ecs-instance`**. **Public IPv4** still blank. Subnet still **private**.  
    **Why it matters:** you did not “fix” reachability by putting the host on a public subnet. The path is internet → IGW → ALB → task ENI.

### Verification

- ALB active on two public subnets. Target type **IP**, target **healthy**.  
- Task SG inbound source is **`accelerator-alb-sg`**, not the whole internet. Instance SG still closed.  
- **Expected State:** You can explain the path without Terraform.

### Troubleshooting References

¹ **Symptom:** Target **unhealthy**.  
  **Resolution:** Task still RUNNING? Health path `/`? Task SG inbound from ALB SG? Wait 2 more minutes. Stopped reason if the task died.  
² **Symptom:** Target type **instance**.  
  **Resolution:** Recreate TG as **ip**. Re-paste Lab 6.3.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.7 — See the ALB and security groups (root)

---

## Lab 6.8 — Open the URL in a browser

### Objective

Open the app over HTTP.

Stay in `terraform/` (Lab 6.6). `terraform output app_url` prints the address again. It does **not** change AWS. Copy the whole line. It must start with `http://`.

```bash
terraform output app_url
```

Paste the URL into a **new** browser tab (not the AWS console tab). If the browser upgrades to `https://`, change it back to **`http://`**. Press Enter.

### See it (browser)

The hostname in the address bar is the **load balancer**, not the EC2 instance.

- You did **not** paste an EC2 public IP (there isn’t one).  
- A padlock / certificate error means the browser forced **https**. This Accelerator has no certificate. Use **`http://`** exactly.  
  **Why it matters:** this is the visitor proof. Reception answered. The task stayed private.

### Verification

- The **#AWS ACCELERATOR** landing page loads.  
- **Expected State:** The app loads over HTTP.

### Troubleshooting References

¹ **Symptom:** Timeout.  
  **Resolution:** Target not healthy yet; wrong region; used https.  
² **Symptom:** Privacy / certificate error.  
  **Resolution:** This lab is HTTP only. No padlock.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.8 — Open the URL in a browser

---

## Lab 6.9 — Save the Terraform files (not the state)

Keep module files on disk. Do **not** push to GitHub. GitHub is Workflow 08.

Confirm `terraform/modules/alb/` has three files and `.gitignore` still lists `*.tfstate`.

### Verification

- ALB module on disk.  
- **Expected State:** Terraform files saved. No remote required yet.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.9 — Save the Terraform files (not the state)

---

## Lab 6.10 — Destroy

Keep the `.tf` files. **Always** run this lab. Do not leave the stack up for Workflow 07. Workflow 07 will apply again.

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform destroy` tears down the ALB, cluster, registry, and NAT. It will ask you to type `yes`. Until you type `yes`, nothing is deleted. Files in `terraform/` stay.

If destroy sits on **DRAINING** for more than about 10 minutes, and the instance is **InService** (not Terminating:Wait), do **not** wait for a timeout. Same unstick as Workflow 05 Lab 5.9 Troubleshooting ² (force-delete the service). If the instance is **Terminating:Wait**, use Troubleshooting ¹.

```bash
terraform destroy
```

Type `yes` and press **Enter**. Wait until **Destroy complete!** ALB, NAT, and instance hours stop only after that line.

### See it (root)

Same sign-in as Lab 6.7 if the console is closed: [https://console.aws.amazon.com](https://console.aws.amazon.com) → **Root user** → account email → **N. Virginia**.

1. **EC2 → Load Balancers** — `accelerator-alb` **gone**.  
2. **EC2 → Target Groups** — `accelerator-tg` **gone**.  
3. **EC2 → Instances** — `accelerator-ecs-instance` **terminated** (or gone).  
4. **VPC → NAT gateways** — NAT **gone**.  
5. **ECR → Repositories** — `accelerator` **gone**.  
6. **EC2 → Security Groups** — `accelerator-alb-sg` and `accelerator-svc-sg` **gone**.  
   **Why it matters:** reception, cluster, registry, and NAT were hourly. Files in `terraform/` stay. Workflow 07 applies again.

### Verification

- ALB hours stopped.  
- **Expected State:** Cloud dead. Code alive.

### Troubleshooting References

¹ **Symptom:** ALB stuck deleting.  
  **Resolution:** Re-run destroy. Wait; do not leave it “active.”  
² **Symptom:** Destroy sits on service **DRAINING**, instance **InService**, no hook (or times out at 20 min).  
  **Resolution:** Workflow 05 Lab 5.9 Troubleshooting ² (`delete-service --force`). Then `terraform destroy` again.  
³ **Symptom:** Instance **Terminating:Wait**.  
  **Resolution:** Workflow 05 Lab 5.9 Troubleshooting ¹. Then `terraform destroy` again.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 6.10 — Destroy

---

### Workflow Completion Criteria

Do not continue until all checks pass:

- [ ] Stack re-applied; image **pushed**; then ALB applied  
- [ ] **EC2 → Load Balancers → accelerator-alb** Active  
- [ ] **Target Groups → accelerator-tg** — target **healthy**  
- [ ] Task SG inbound source is **`accelerator-alb-sg`**, not `0.0.0.0/0`  
- [ ] Browser proof on **`http://`** `app_url`  
- [ ] Destroy completed  

### What We Have Accomplished

You put a real ALB in front of the task and proved the task is not public.

### Where We Are Now

**Artefact state:** ALB module + service wiring on disk. Nothing live after destroy. GitHub is Workflow 08.

### Where We Are Going Next

Every module is written. **Workflow 07** adds **no** Terraform folder. You re-apply 02–06, push the image, and run a full launch on purpose. Optional: change a line of text, rebuild, push, force a new deployment.

### Restart next time

1. `terraform apply` (all five modules)  
2. **Build + push**  
3. Wait for a healthy target  
4. Open `app_url`  

That **is** Workflow 07.

### Destroy

Lab 6.10. **Always.** Then Workflow 07 starts with apply + push. ALB + NAT + EC2 left up overnight is a bill.

### Common Errors & Resolutions (Workflow 06)

| # | Error / symptom | Likely cause | Resolution |
|---|-----------------|--------------|------------|
| 1 | Terraform `Cycle` | ALB module points at the service SG | Labs 6.3–6.5 only |
| 2 | Target type instance | Wrong TG | `target_type = "ip"` |
| 3 | Targets unhealthy | Task down, bad SG, https health | RUNNING; inbound from ALB SG; HTTP `/` |
| 4 | Browser https / certificate | Browser upgraded the URL | Use **`http://`** exactly |
| 5 | Timeout | Target not healthy yet | Lab 6.7; wait; re-check NAT + pull |
| 6 | Task SG `0.0.0.0/0` | Task opened to the internet | Rule source = ALB SG only |
| 7 | Instance SG opened 80 | Confused host with task | Close it; ALB talks to the **task** ENI |
| 8 | No `app_url` | Forgot output or apply | `terraform output app_url` |
| 9 | Wrong region | Console not N. Virginia | Switch region |
| 10 | Left ALB up | Skipped destroy | `terraform destroy` now |
| 11 | Invalid count argument on `alb_http_in` | `count` on an id unknown until apply | Lab 6.4 file with **no** `count`. One full apply. No `-target` |
| 12 | Task PROVISIONING / empty target group | Default 200/100 on t3.micro (ENI limit 2) | Service `100` / `0`. Stop the extra task. Wait for one healthy target |
| 13 | Destroy sits on service **DRAINING**, instance **InService** | Terraform waiter for **INACTIVE** (~20 min) | Workflow 05 Lab 5.9 Troubleshooting ² (`delete-service --force`) |
| 14 | Destroy timeout on Terminating:Wait | ECS drain hook still on | Workflow 05 Lab 5.9 Troubleshooting ¹ |

### Workflow Summary

Workflow 06 solved “there is no public URL.”  
The next problem is “do it once, end to end, on purpose.” Workflow 07 is that launch — no new module.

Open `workflow 7 - Manual Production Deployment.md` when you are ready.
