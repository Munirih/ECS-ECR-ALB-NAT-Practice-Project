# Workflow 02 — VPC Networking
## Apply the house — then teardown

**Programme:** AWS Graduate Cloud Skills Accelerator  
**Region:** `us-east-1` only  
**Prefix:** `accelerator`  
**Project:** the `accelerator-app` folder  

---

# Workflow Overview

Workflow 01 gave you CLI access and Terraform files that validate. AWS still has no network of your own.

This is the first `terraform apply`. You build a custom VPC: two public subnets, two private subnets, an Internet Gateway, and **one** NAT Gateway. Then you prove it in the console as root. Then you **destroy**. Workflow 03 is local Docker — it does not need this VPC.

There is still no release artefact in AWS. That is the next chapter — not this one.

---

### The 5 Codewrkx Engineer Questions

**What is the problem?**  
AWS gives every account a **default VPC**. That is not a network you designed. You have nowhere honest to put a private server or a public load balancer that you control.

A **region** is a geographic AWS location — a cluster of **data centres**. This Accelerator uses only **N. Virginia (`us-east-1`)**. Light picture: the **city** you build in.

An **Availability Zone (AZ)** is an isolated data centre (or group of them) **inside** that region (names look like `us-east-1a`, `us-east-1b`). Light picture: a **district** of the city. **Not** a house. **Not** a room. Two AZs means two districts. If one data centre fails, the other can still run — that is **high availability**. This lab uses two AZs so the load balancer later can span both, but only **one** NAT (service exit) to keep the bill down. Terraform picks the **first two available** AZs in `us-east-1` — usually `us-east-1a` and `us-east-1b`. If your console shows a different pair, that is still correct.

**Why solve it with these services?**  
A **VPC (Virtual Private Cloud)** is your **house** — a private network in your account (the yard). One house, drawn across **two AZs** (two data centres) on purpose.

**Public subnets** are **front rooms** (later: ALB and this NAT). **Private subnets** are **back rooms** (later: ECS). An **Internet Gateway (IGW)** is the **front gate** — house ↔ internet. A **NAT (Network Address Translation) Gateway** is the **service exit**: back rooms can fetch (images) without visitors coming in. The hatch sits in a **front room**.

**When are these services used?**  
You draw the house **once** per environment. Every request uses it after that. You do not create a new VPC for each page load.

**How does this work?**  
You add a `vpc` module, call it from `main.tf`, then:

| Command | Today |
|---------|--------|
| `terraform init` | Read the new module. |
| `terraform validate` | Grammar check. |
| `terraform plan` | Preview: VPC, subnets, IGW, **one** NAT. Confirm it is **not** a second NAT. |
| `terraform apply` | Build it. Type `yes`. |
| `terraform destroy` | Take the house down before you leave. Terraform files stay. The yard and the clerk stay. |

Walk the console as root (N. Virginia). Then destroy. Workflow 03 (Docker) does not need this VPC live.

**Who typically deploys them?**  
Network or platform engineers own the VPC. You write the module. Root **looks** in the Console. `accelerator-cli` runs `apply` and `destroy`.

---

### Where We Came From

You have IAM user `accelerator-cli` in the CLI. `aws sts get-caller-identity` is not root. The Terraform root validates. There is **no** `accelerator-vpc`. GitHub is Workflow 08.

### Where We Are Now

You will add `terraform/modules/vpc`, call it from `main.tf`, apply, and walk the console: VPCs, subnets, IGW, NAT, route tables.

### Where We Are Going

When the sitting ends, the house comes down (`terraform destroy`). The module files stay. Workflow 03 packages the app on your laptop. You do **not** need this VPC to build Docker. Workflow 04 is ECR only (`-target=module.ecr`) — do **not** full-apply there. You **will** need to apply this VPC module again from **Workflow 05** onward (ECS needs the network).

### Launch context

Access and the Terraform files exist. Today you apply the **house**: public subnets (later the ALB and NAT), private subnets (later ECS), an IGW, and **one** NAT. A NAT Gateway in every Availability Zone (AZ) is production **high availability** — if one data centre fails, private traffic still has a service exit. It is also a second bill. Tonight you teardown. The files stay.

### Technical Context

The **default VPC** is not your house. This Accelerator uses a **custom VPC** so later labs can put the ALB on public subnets and ECS tasks on private subnets.

| Resource | Responsibility |
|-------|----------|
| VPC `10.0.0.0/16` | The house — your network boundary |
| Public subnets | Front rooms. IGW route. Later: ALB + this NAT |
| Private subnets | Back rooms. NAT route. Later: ECS hosts and tasks |
| IGW | Front gate. Internet ↔ public subnets |
| **One** NAT in **one** AZ | Service exit. Private → out (ECR pulls). Not a pair. |

**Why one NAT?** A NAT Gateway in every Availability Zone (AZ) is how teams get **high availability**: if one data centre fails, the other still has a service exit. It also doubles the hourly bill. This Accelerator uses one NAT in the **first public subnet** (`accelerator-public-a` — usually `us-east-1a`). Both private subnets send outbound traffic through that single NAT.

**Why two public and two private?** The ALB (Workflow 06) requires two AZs. You create the four rooms now so you do not redesign the house later. One house, two districts — say it once: a VPC spans AZs; each subnet sits in **one** AZ.

NAT Gateway **hours are not Free Tier**. Apply, verify, destroy in the same sitting.

### Why This Workflow Matters

Without this VPC, later workflows have nowhere honest to put an ALB or a private task. Default-VPC shortcuts hide the story employers ask about.

### What We Will Build

Module `vpc` and a live (then destroyed) `accelerator-vpc`.

### Architecture Snapshot

When [`architecture.png`](architecture.png) is in this Accelerator folder, that is the full drawing. If it is not there yet, use the text snapshot below.

```text
Internet
    │
    ▼
accelerator-igw
    │
    ├──────── public-a 10.0.0.0/24   (first AZ, often us-east-1a)  ← NAT lives here
    ├──────── public-b 10.0.1.0/24   (second AZ, often us-east-1b) ← no second NAT
    │
    └──── NAT (one) ◄── private-a 10.0.10.0/24
                   ◄── private-b 10.0.11.0/24
```

### SOFTWARE DELIVERY PROGRESS: ✓ 0 Intro → ✓ 01 Access → ► 02 VPC → □ 03 Docker → □ 04 ECR → □ 05 ECS → □ 06 ALB → □ 07 Prove → □ 08 Pipeline

### Learning Outcomes

- Author a Terraform VPC module (not a dump in `main.tf`)  
- Apply and read the plan before you type `yes`  
- Prove subnets, IGW, NAT, and routes in the console  
- Destroy the stack so NAT hours stop  

### Key Terminology

| Term | Meaning |
|------|---------|
| VPC | Isolated network in your account. Light picture: the **house** |
| Subnet | Slice of the VPC CIDR in **one** AZ. Light picture: a **room** |
| AZ | Isolated **data centre** inside the region (names like `us-east-1a`). Light picture: a **district**. Not a house |
| Internet Gateway | Front **gate** — VPC path to the internet |
| NAT Gateway | **Service exit** — outbound-only for private subnets. Sits in a public subnet |
| Route table | **Corridor** — where packets go next (IGW vs NAT vs local) |
| Elastic IP | Public IPv4 address attached to the NAT |

### Labs

Tick as you finish. Change `- [ ]` to `- [x]`.

- [ ] Lab 2.1 — Restart: confirm CLI identity
- [ ] Lab 2.2 — Create `modules/vpc`
- [ ] Lab 2.3 — Call the module from the root
- [ ] Lab 2.4 — Init, validate, plan
- [ ] Lab 2.5 — Apply
- [ ] Lab 2.6 — See the house in the console (root)
- [ ] Lab 2.7 — Save the Terraform files (not the state)
- [ ] Lab 2.8 — Destroy

---

## Lab 2.1 — Restart: confirm CLI identity

### Objective

Prove the terminal is still `accelerator-cli` before you apply.

### Why this lab exists

Terraform uses the same credentials as the CLI. If you are on root keys, stop.

### Procedure

1. Open the **accelerator-app** folder in VS Code. Open a terminal there (**Terminal → New Terminal**).

This command asks AWS: “who am I?” It does **not** create anything. Terraform will use the same answer. The `Arn` must contain `user/accelerator-cli`. If it contains `root`, stop — you pasted the account owner’s keys. Fix that in Workflow 01 Labs 1.2–1.3 before you apply.

```bash
aws sts get-caller-identity
```

2. Read the JSON. Confirm `Arn` contains `user/accelerator-cli`.

### See it (root)

Confirm the window you will use after apply. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → **email that owns the account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.  
   **Why it matters:** Lab 2.5 looks here. Wrong city = empty VPC list after apply.

### Verification

- CLI Arn contains `user/accelerator-cli`. Console is N. Virginia as the account email.  
- **Expected State:** Same identity as Workflow 01.

### Troubleshooting References

¹ **Symptom:** Credentials missing or root Arn.  
  **Resolution:** Repeat Workflow 01 Labs 1.2–1.3. Do not continue.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 2.1 — Restart: confirm CLI identity

---

## Lab 2.2 — Create `modules/vpc`

### Objective

Build `modules/vpc` in order: variables, then house, rooms, gate, service exit, corridors. Do **not** apply in this lab.

### Why this lab exists

The root `main.tf` stays short. The network lives in `modules/vpc` so Workflow 05 onward can consume outputs (`vpc_id`, subnet IDs) without copying CIDRs by hand.

You add **one slice at a time** to `main.tf` (paste each slice at the **bottom**, then save). If a slice goes wrong, skip to **Your file must look like this** and replace the whole `main.tf`.

### Procedure — folders and variables

1. In Explorer, right-click the existing `terraform` folder (Workflow 01 Lab 1.4).  
2. **New Folder** → name it `modules`.  
3. Right-click `modules` → **New Folder** → name it `vpc`.  
4. Create `terraform/modules/vpc/variables.tf`. Paste:

```hcl
# Values the root will pass in. Defaults match this Accelerator.

variable "project" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16" # the house address range
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"] # two front rooms
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"] # two back rooms
}
```

5. Save.  
6. Create `terraform/modules/vpc/main.tf`. Leave it empty. You will add five slices below, in order.

### Slice 1 — the house (VPC)

**Why this is next:** nothing else can exist until there is a VPC.

Paste into `main.tf`:

```hcl
# 1. The house. Everything later sits inside this VPC.
# DNS on so later names (ECR, ECS) resolve inside the house.
# Two AZs only — first two available in us-east-1 (often 1a + 1b). The ALB later needs two.

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}
```

Save.

### Slice 2 — four rooms (subnets)

**Why this is next:** a house with no rooms is empty. Two front, two back, two AZs.

Paste **at the bottom** of `main.tf`:

```hcl
# 2. Four rooms in that house.
# Public = front rooms (ALB + this NAT later). Private = back rooms (ECS later).
# count = 2 → one room per AZ (one per data centre).

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-${count.index == 0 ? "a" : "b"}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.project}-private-${count.index == 0 ? "a" : "b"}"
    Tier = "private"
  }
}
```

Save.

### Slice 3 — front gate (Internet Gateway)

**Why this is next:** front rooms must reach the internet. Back rooms will not use this gate.

Paste **at the bottom** of `main.tf`:

```hcl
# 3. Front gate. Attached to the house.
# Public route table (slice 5) will send 0.0.0.0/0 here.

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-igw"
  }
}
```

Save.

### Slice 4 — one service exit (EIP + NAT)

**Why this is next:** back rooms have no public IP. They fetch through this exit. **One** only — bill. The hatch sits in the first front room (`public-a`).

Paste **at the bottom** of `main.tf`:

```hcl
# 4. One service exit, on the first front room (public-a).
# depends_on IGW: a NAT needs the gate before it can talk out.

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-nat-eip"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}
```

Save.

### Slice 5 — how packets leave (route tables)

**Why this is next:** corridors name the gate and the service exit. Those must exist first.

Paste **at the bottom** of `main.tf`:

```hcl
# 5. Two corridors.
# Front rooms → IGW (front gate). Back rooms → NAT (service exit). Not the other way round.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.project}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

Save. **Do not** `terraform apply` yet. That is Lab 2.5.

### Your file must look like this — `modules/vpc/main.tf`

Open `terraform/modules/vpc/main.tf`. It must match this block (same resources, same names, slices 1–5 in order). If it does not, **select all**, delete, paste this whole block, save.

```hcl
# 1. The house. Everything later sits inside this VPC.
# DNS on so later names (ECR, ECS) resolve inside the house.
# Two AZs only — first two available in us-east-1 (often 1a + 1b). The ALB later needs two.

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

# 2. Four rooms in that house.
# Public = front rooms (ALB + this NAT later). Private = back rooms (ECS later).
# count = 2 → one room per AZ (one per data centre).

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-${count.index == 0 ? "a" : "b"}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.project}-private-${count.index == 0 ? "a" : "b"}"
    Tier = "private"
  }
}

# 3. Front gate. Attached to the house.
# Public route table (slice 5) will send 0.0.0.0/0 here.

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-igw"
  }
}

# 4. One service exit, on the first front room (public-a).
# depends_on IGW: a NAT needs the gate before it can talk out.

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-nat-eip"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

# 5. Two corridors.
# Front rooms → IGW (front gate). Back rooms → NAT (service exit). Not the other way round.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.project}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

### Procedure — outputs

Create `terraform/modules/vpc/outputs.tf`. These names are what later modules read. Paste:

```hcl
# What the root (and later modules) may ask this house for.

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.this.id
}
```

Save.

### Verification

- `terraform/modules/vpc/` contains `main.tf`, `variables.tf`, `outputs.tf`.  
- `main.tf` has slices 1–5 (VPC, subnets, IGW, NAT, route tables).  
- **Expected State:** Module on disk. Nothing applied.

### Troubleshooting References

¹ **Symptom:** Folder named `VPC` or `modules vpc`.  
  **Resolution:** Path must be `terraform/modules/vpc`.  
² **Symptom:** Duplicate resources / paste landed twice.  
  **Resolution:** Replace `main.tf` with **Your file must look like this**.  
³ **Symptom:** You applied in this lab.  
  **Resolution:** Stop. Lab 2.5 is apply. If a NAT already exists, destroy in Lab 2.8 after you finish 2.3–2.5, or destroy now and continue writing files.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 2.2 — Create `modules/vpc`

---

## Lab 2.3 — Call the module from the root

### Objective

Replace the empty root `main.tf` and grow `outputs.tf` so apply has something to build.

### Procedure

1. Open `terraform/main.tf`.  
2. **Replace the entire file** with:

```hcl
# =============================================================================
# AWS Graduate Cloud Skills Accelerator
# Root module — calls only.
# =============================================================================

locals {
  project = var.project
  region  = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  project = local.project
}
```

3. Save.  
4. Open `terraform/outputs.tf`.  
5. **Replace the entire file** with:

```hcl
output "project" {
  value = var.project
}

output "aws_region" {
  value = var.aws_region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  value = module.vpc.nat_gateway_id
}
```

6. Save.

### Verification

- Root `main.tf` contains only `module "vpc"`.  
- **Expected State:** Ready to init / plan / apply.

### Troubleshooting References

¹ **Symptom:** You left the old “no module blocks” comments and also added a module.  
  **Resolution:** Use the replacement file above only.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 2.3 — Call the module from the root

---

## Lab 2.4 — Init, validate, plan

### Objective

Refresh providers if needed, then read the plan before you spend NAT hours.

### Procedure

You must be in the `terraform/` folder — the one that already has `main.tf` and `modules/vpc`. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS. It only changes which folder the next commands use.

```bash
cd terraform
```

`terraform init` does **not** build a VPC. It reads this folder, sees the new `vpc` module, and downloads the AWS plugin if needed. Run it whenever you add a module. You should see **Terraform has been successfully initialized**.

```bash
terraform init
```

`terraform validate` is a grammar check. It asks: “Do these files make sense together?” It still does **not** touch AWS. You should see **Success! The configuration is valid**.

```bash
terraform validate
```

`terraform plan` is the preview. Terraform talks to AWS with `accelerator-cli` and prints what it **would** create if you applied. It does **not** create it yet.

Read the plan. You should see: one VPC, four subnets, one Internet Gateway, **one** NAT Gateway, one Elastic IP, two route tables, four associations. You should **not** see a second NAT, an ALB, or ECS.

If the plan looks wrong, stop. Do not apply. Fix Lab 2.2 / 2.3, then plan again.

```bash
terraform plan
```

### Verification

- Validate succeeds.  
- Plan shows **one** `aws_nat_gateway` and **no** load balancer.  
- **Expected State:** Eyes open. Ready to apply.

### Troubleshooting References

¹ **Symptom:** `Unreadable module directory`.  
  **Resolution:** `modules/vpc` path relative to `terraform/`.  
² **Symptom:** Plan shows two NATs.  
  **Resolution:** Re-paste `modules/vpc/main.tf` from Lab 2.2.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 2.4 — Init, validate, plan

---

## Lab 2.5 — Apply

### Objective

Create the VPC in `us-east-1`.

### Procedure

Stay in `terraform/` (Lab 2.4). `terraform apply` is the first time this sitting **builds** in AWS. It will show a plan again, then ask you to type `yes`. NAT can take a few minutes. Until you type `yes`, nothing is created.

```bash
terraform apply
```

Type `yes` and press **Enter**. Wait until the output says **Apply complete!** If you type anything else, it cancels — that is safe.

`terraform output` prints values Terraform stored after apply (VPC id, NAT id). It does **not** change AWS. Copy `vpc_id` if you want it for the console search in **See it (root)**.

```bash
terraform output
```

### See it (root)

Terraform said it built the house. Prove it in the browser. **Root** = the email that owns the AWS account. **`accelerator-cli`** stays in the terminal.

1. Open a browser. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)  
   (or [https://aws.amazon.com](https://aws.amazon.com) → **Sign in to the Console**).  
2. Choose **Root user**.  
3. Type the **email address that owns the AWS account** (the one you used to create it). Not `accelerator-cli`.  
4. Continue. Enter that email’s **password**. Finish MFA / 2FA if AWS asks.  
5. You should land in the AWS Management Console. Top-right: account menu (email or account name).  
6. Top-right **region**. If it is not **N. Virginia**, click it → **US East (N. Virginia) `us-east-1`**.  
   Wrong region = you will not see what Terraform just built.

7. Top search bar: type **VPC**. Open **VPC**.  
8. Left menu: **Your VPCs**. Open **`accelerator-vpc`**.  
   IPv4 CIDR should be **`10.0.0.0/16`**.  
   **Why it matters:** this is your house. Later workflows put the ALB and ECS here — not in AWS’s default VPC.

9. Left menu: **NAT gateways**. Find **`accelerator-nat`**. State **Available**. **One** row, not two.  
   **Why it matters:** this is the service exit (private rooms can fetch images). It bills by the hour. That is why you destroy before you leave.

10. Left menu: **Subnets**. Filter by VPC **`accelerator-vpc`**. You should see **four** names: two **public**, two **private**.  
    **Why it matters:** public = front rooms (ALB later, and this NAT). Private = back rooms (ECS later). Lab 2.6 explains each name.

Lab 2.6 walks the Internet Gateway, route tables, and why there are four subnets. Do not skip it.

### Verification

- Apply finished without error.  
- Outputs include `vpc_id` and `nat_gateway_id`.  
- You signed in as the **account email** and saw `accelerator-vpc`, one NAT, four subnets.  
- **Expected State:** The house exists. Clock is running on the NAT. You have looked with your eyes.

### Troubleshooting References

¹ **Symptom:** `No valid credential sources`.  
  **Resolution:** Lab 2.1.  
² **Symptom:** `UnauthorizedOperation`.  
  **Resolution:** **IAM → Users → accelerator-cli → Permissions** — **AdministratorAccess**; wait one minute; retry.  
³ **Symptom:** AddressLimitExceeded on EIP.  
  **Resolution:** Release unused Elastic IPs (**EC2 → Elastic IPs**); retry apply.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 2.5 — Apply

---

## Lab 2.6 — See the house in the console (root)

### Objective

Walk every network object so you can describe it without Terraform: what it is, and **why** it is there.

### Procedure

If the console is still open from Lab 2.5, skip to step 5 (your house and the four rooms). If not, sign in again:

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → account **email** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.  
4. Top search: **VPC** → open **VPC**.

**Your house**

5. Left: **Your VPCs** → **`accelerator-vpc`**. CIDR **`10.0.0.0/16`**.  
   **Why it matters:** one house. Everything in this Accelerator that lives in AWS sits inside this VPC.

**Four rooms — why these subnets**

6. Left: **Subnets**. Filter by VPC **`accelerator-vpc`**. Confirm four:

   | Name | Room | AZ (data centre) | Why this one |
   |------|------|------------------|--------------|
   | `accelerator-public-a` | Front | First available AZ (often `us-east-1a`) | ALB later. The **one** NAT (service exit) lives here. |
   | `accelerator-public-b` | Front | Second available AZ (often `us-east-1b`) | Second front room for the ALB. Workflow 06 needs **two** AZs. No second NAT. |
   | `accelerator-private-a` | Back | Same as public-a | ECS later. No street door. |
   | `accelerator-private-b` | Back | Same as public-b | ECS’s second AZ. Same reason: two data centres. |

   Terraform uses `slice(..., 0, 2)` — the **first two available** AZs, not a hardcoded `1a` / `1b`. Match the **names** (`accelerator-public-a`). If your AZ column is not `us-east-1a` / `us-east-1b`, still tick this lab.  
   **Why four, not two:** an Application Load Balancer must span two Availability Zones. You draw two public and two private **now** so you do not redesign the house in Workflow 06. One house, two districts.  
   **Why public vs private:** public has a route to the Internet Gateway (front gate). Private does **not** — it only goes out through the NAT (service exit). Visitors never get the private address.

**Front gate**

7. Left: **Internet gateways** → **`accelerator-igw`**. State **Attached**.  
   **Why it matters:** this is how the front rooms (public subnets) reach the internet. The back rooms do not use this gate.

**Service exit**

8. Left: **NAT gateways** → **`accelerator-nat`**. State **Available**. **One** row.  
   **Why it matters:** private rooms can pull images from ECR without being reachable from the internet. One AZ on purpose (bill). Production high availability would put a NAT in every AZ — a second bill.

**How packets leave**

9. Left: **Route tables** → **`accelerator-public-rt`**. Routes: `10.0.0.0/16` local, `0.0.0.0/0` → **Internet Gateway**.  
   **Why it matters:** front-room traffic “out” goes through the front gate.

10. Open **`accelerator-private-rt`**. Routes: `10.0.0.0/16` local, `0.0.0.0/0` → **NAT**.  
    **Why it matters:** back-room traffic “out” goes through the service exit, not the front gate.

11. Top search: **EC2** → **Elastic IPs**. One address tagged **`accelerator-nat-eip`**, associated to the NAT.  
    **Why it matters:** the service exit’s public number. Still one. Still billing.

### Verification

- Four named subnets, one IGW, one NAT, public vs private routes as above.  
- You can say **why** there are four subnets (two AZs for the ALB later) and **why** private does not use the IGW.  
- **Expected State:** You can point at the VPC, subnets, IGW, NAT, and routes — and explain front rooms vs back rooms.

### Troubleshooting References

¹ **Symptom:** VPC “missing”.  
  **Resolution:** Region is not N. Virginia; or apply did not finish.  
² **Symptom:** Two NAT gateways.  
  **Resolution:** Wrong module. Destroy, fix `main.tf` in the module, re-apply only if you still need the lab — otherwise destroy and stop.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 2.6 — See the house in the console (root)

---

## Lab 2.7 — Save the Terraform files (not the state)

### Objective

Keep module files on disk. Do **not** commit `terraform.tfstate`. GitHub is Workflow 08.

### Procedure

1. Confirm `terraform/modules/vpc/` has `main.tf`, `variables.tf`, `outputs.tf`.  
2. Confirm `.gitignore` still lists `*.tfstate` and `.terraform/`.  
3. Do **not** push to GitHub.

### Verification

- VPC module files are saved.  
- **Expected State:** Terraform files on disk. No remote required yet.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 2.7 — Save the Terraform files (not the state)

---

## Lab 2.8 — Destroy

### Objective

Teardown the house so NAT and EIP hours stop. **Keep the `.tf` files.**

### Procedure

You must be in the `terraform/` folder again. If the terminal is in `accelerator-app`, move in. This does **not** destroy anything by itself.

```bash
cd terraform
```

`terraform destroy` removes what this root manages: VPC, subnets, IGW, NAT, Elastic IP. It does **not** delete IAM user `accelerator-cli`, and it does **not** delete the `.tf` files on disk. It will show a destroy plan, then ask you to type `yes`. Until you type `yes`, nothing is deleted.

```bash
terraform destroy
```

Type `yes` and press **Enter**. Wait until the output says **Destroy complete!** NAT and EIP hours stop only after that line.

### See it (root)

Terraform said the house is gone. Prove it in the browser. If the console is still open from Lab 2.6, skip to step 4. If not:

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → account **email** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

4. Top search: **VPC** → **Your VPCs**. **`accelerator-vpc`** is **gone**.  
   **Why it matters:** the house you applied in Lab 2.5 is down. The module files in `terraform/modules/vpc/` stay.

5. Left: **NAT gateways**. No **`accelerator-nat`** (or status **Deleted**).  
   **Why it matters:** the service exit billed by the hour. That clock must stop.

6. Top search: **EC2** → **Elastic IPs**. **`accelerator-nat-eip`** is **gone** (not sitting “available” unused).  
   **Why it matters:** an unused Elastic IP still bills. “Available” here is not free — it means leftover.

7. **EC2 → Instances** — nothing you launched (you launched none today).  
   **Why it matters:** Workflow 02 is the house only. The EC2 server starts in Workflow 05.

### Verification

- Destroy completed.  
- You signed in as the **account email** and saw no accelerator VPC, NAT, or leftover EIP.  
- **Expected State:** Cloud dead. Code alive.

### Troubleshooting References

¹ **Symptom:** Destroy fails on NAT or EIP.  
  **Resolution:** Re-run `terraform destroy`. Wait for NAT to delete; do not delete the VPC by hand unless destroy keeps failing.  
² **Symptom:** EIP left behind.  
  **Resolution:** **EC2 → Elastic IPs** → select → **Release**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 2.8 — Destroy

---

### Workflow Completion Criteria

Do not continue until all checks pass:

- [ ] `modules/vpc` created by you  
- [ ] `terraform apply` succeeded and you saw the VPC in the console  
- [ ] Public RT → IGW; private RT → NAT; **one** NAT  
- [ ] `terraform destroy` completed; console confirms the VPC / NAT are gone  

### What We Have Accomplished

You applied a real VPC from a module, proved it as root, and tore it down.

### Where We Are Now

**Artefact state:** VPC module on disk. Terraform state empty. **No** live NAT. The product is still only a React app on the laptop.

### Where We Are Going Next

The house can come back any time you `apply`. There is no container in AWS. ECS cannot run a laptop folder.

**Workflow 03** is Docker on your laptop only. You do **not** apply the VPC. You do **not** create ECR yet.

### Restart next time

- Keep `accelerator-cli` and the `terraform/` files  
- For Docker-only work: skip apply  
- First VPC re-apply is **Workflow 05** (with ECR and ECS). Workflow 04 uses `-target=module.ecr` only — a full apply here would create a NAT you then fail to destroy.

### Destroy

Done in Lab 2.8. If you skipped it, run it **now**. NAT left up is a bill.

### Common Errors & Resolutions (Workflow 02)

| # | Error / symptom | Likely cause | Resolution |
|---|-----------------|--------------|------------|
| 1 | `No configuration files` | Not in `terraform/` | `cd terraform` |
| 2 | Module path error | Folder not `modules/vpc` | Create the path from Lab 2.2 |
| 3 | Credentials / `UnauthorizedOperation` | CLI not `accelerator-cli` | Workflow 01 Labs 1.2–1.3 |
| 4 | Plan shows ALB or ECS | Wrong files pasted | Use only this workflow’s HCL |
| 5 | Two NAT gateways in console | Extra resource in module | Destroy; fix; do not “just leave it” |
| 6 | EIP limit | Old unused Elastic IPs | **EC2 → Elastic IPs** → Release |
| 7 | VPC missing in console | Wrong region | **N. Virginia** |
| 8 | Public and private routes swapped | Associations wrong | Compare Lab 2.6 steps 8–9; re-paste module |
| 9 | Accidentally committed `tfstate` | `.gitignore` skipped | Remove from disk backup; never push state |
| 10 | Forgot destroy | Left the sitting | `terraform destroy` immediately; confirm NAT gone |

### Workflow Summary

Workflow 02 solved “there is no house.”  
The next problem is “there is no container.” Workflow 03 packages the app in Docker on your laptop.

Open `workflow 3 - React to Docker.md` when you are ready.
