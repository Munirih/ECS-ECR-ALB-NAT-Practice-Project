# Workflow 04 — Amazon ECR
## Put the image in the registry. Do not start ECS.

**Programme:** AWS Graduate Cloud Skills Accelerator  
**Region:** `us-east-1` only  
**Prefix:** `accelerator`  
**Project:** the `accelerator-app` folder  
**Image:** `accelerator:latest`  

---

# Workflow Overview

Workflow 03 built `accelerator:latest` on your laptop. ECS cannot pull a laptop image.

This chapter creates an ECR repository with Terraform, pushes the image, and proves the tag in the console.

You do **not** apply the VPC. A registry does not need a NAT. You do **not** create a cluster.

---

### The 5 Codewrkx Engineer Questions

**What is the problem?**  
The image lives only on your laptop. ECS (Elastic Container Service) in AWS cannot pull your hard drive.

A **region** is a geographic AWS location — a cluster of **data centres**. This registry must sit in **N. Virginia (`us-east-1`)** — the same region as later ECS. Light picture: the **city**. Wrong region = the cluster will not see the image.

**Why solve it with these services?**  
**ECR (Elastic Container Registry)** is a private **registry** in your account, in this region. Named `accelerator`. It is **not** a room of the VPC. The cluster will pull `accelerator:latest` from here — not from your laptop, and not from Docker Hub as the running copy.

**When are these services used?**  
Push when the image must be available to the cluster. After every destroy in this Accelerator you push again. You do not push on every keystroke.

**How does this work?**  
You add an `ecr` module, call it from `main.tf`, then:

| Command | Today |
|---------|--------|
| `terraform init` | Read the new module. |
| `terraform validate` | Grammar check. |
| `terraform plan "-target=module.ecr"` | Preview: **only** the registry. Confirm **no** NAT. |
| `terraform apply "-target=module.ecr"` | Create the empty repository. Type `yes`. |
| `docker build` / `login` / `tag` / `push` | Pack on this laptop, then upload `accelerator:latest`. |
| `terraform destroy "-target=module.ecr"` | Delete the repository. Dockerfile stays. |

Walk the console as root (N. Virginia). Empty repository after apply; tag **`latest`** after push. No cluster today.

**Who typically deploys them?**  
Platform engineers own the registry. Application engineers push images. You do both. Root **looks** in the Console. `accelerator-cli` **applies** and **pushes**.

---

### Where We Came From

Dockerfile and a local image exist. AWS has no `accelerator` repository.

### Where We Are Now

Add `modules/ecr`, apply **only** that module, then **build**, login, tag, and push.

### Where We Are Going

When you destroy, the **repo and the image in AWS die**. The Dockerfile stays. Workflow 05 always applies VPC + ECR, **pushes again**, then adds ECS.

### Technical Context

Amazon ECR is a private registry in your account. ECS later pulls:

```text
ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

Apply uses `-target=module.ecr` so Terraform does **not** recreate the NAT.

### Architecture Snapshot

When [`architecture.png`](architecture.png) is in this Accelerator folder, that is the full drawing. If it is not there yet, use the text snapshot below.

```text
accelerator:latest (laptop)
        │
        └─► ECR  accelerator:latest

No VPC. No NAT. No ECS.  That is correct.
```

### SOFTWARE DELIVERY PROGRESS: ✓ 0 Intro → ✓ 01 Access → ✓ 02 VPC → ✓ 03 Docker → ► 04 ECR → □ 05 ECS → □ 06 ALB → □ 07 Prove → □ 08 Pipeline

### Labs

Tick as you finish. Change `- [ ]` to `- [x]`.

- [ ] Lab 4.1 — Confirm CLI and Docker
- [ ] Lab 4.2 — Create `modules/ecr` and call it
- [ ] Lab 4.3 — Apply ECR only (no NAT)
- [ ] Lab 4.4 — Build, login, tag, push
- [ ] Lab 4.5 — See the image in the console (root)
- [ ] Lab 4.6 — Destroy the ECR repository

---

## Lab 4.1 — Confirm CLI and Docker

### Procedure

Open a terminal in the **accelerator-app** folder.

`aws sts get-caller-identity` asks AWS: “who am I?” It does **not** create anything. Terraform will use the same answer. The `Arn` must contain `user/accelerator-cli`. If it contains `root`, stop. Workflow 01 Labs 1.2–1.3.

```bash
aws sts get-caller-identity
```

Docker Desktop must be **running** (Workflow 03). `docker images` lists images on this laptop. It does **not** start a container. You should see **accelerator** with tag **latest**. If that row is missing, repeat Workflow 03 Lab 3.4.

```bash
docker images
```

### See it (root)

Confirm the window you will use after apply. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → **email that owns the account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.  
   **Why it matters:** Lab 4.3 looks here. Wrong region = no `accelerator` repository after apply.

### Verification

- CLI Arn contains `user/accelerator-cli`. Docker running. Local image present. Console is N. Virginia as the account email.  
- **Expected State:** Ready to apply and push.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 4.1 — Confirm CLI and Docker

---

## Lab 4.2 — Create `modules/ecr` and call it

### Objective

Add the ECR module and call it from the root. Do **not** apply in this lab. Next lab applies **ECR only**.

### Why this lab exists

The root stays a list of calls. The registry lives in `modules/ecr` so later workflows can push `accelerator:latest` here.

You add **one slice at a time**. If a slice goes wrong, use **Your file must look like this**.

### Procedure — folder

1. In Explorer, right-click the existing `terraform` folder (Workflow 01).  
2. Open `modules` (Workflow 02). Right-click `modules` → **New Folder** → name it `ecr`.

### Slice 1 — variables

**Why this is next:** the root will pass the project name. That becomes the repository name `accelerator`.

Create `terraform/modules/ecr/variables.tf`.

Paste:

```hcl
# Values the root will pass in. Repository name = project name.

variable "project" {
  type = string
}
```

Save.

### Slice 2 — the registry

**Why this is next:** this is the repository itself. `MUTABLE` lets you push `latest` again after destroy. `force_delete` lets `terraform destroy` remove a repo that still has images.

Create `terraform/modules/ecr/main.tf`. Leave it empty, then paste this slice.

```hcl
# 1. Private registry in this account, in this region.
# Not a room of the VPC. ECS later pulls accelerator:latest from here — not from your laptop.

resource "aws_ecr_repository" "this" {
  name                 = var.project
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    Name = var.project
  }
}
```

Save.

### Your file must look like this — `modules/ecr/main.tf`

If the repository resource looks wrong, replace the whole file with this block.

```hcl
# 1. Private registry in this account, in this region.
# Not a room of the VPC. ECS later pulls accelerator:latest from here — not from your laptop.

resource "aws_ecr_repository" "this" {
  name                 = var.project
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    Name = var.project
  }
}
```

### Slice 3 — outputs

Create `terraform/modules/ecr/outputs.tf`. Later labs need the URL to tag and push.

```hcl
# What the root may ask this registry for.

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  value = aws_ecr_repository.this.name
}
```

Save.

### Call it from the root

Open `terraform/main.tf`. **Keep** `module "vpc"`. **Add** `module "ecr"` underneath. Do not delete the VPC call — today you still will not apply it.

### Your file must look like this — `terraform/main.tf`

```hcl
# Root — calls only. Workflow 04 applies ECR only (-target). VPC stays on disk.

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
```

Open `terraform/outputs.tf`. **Keep** the VPC outputs. **Add** these two:

```hcl
output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}
```

Save. **Do not** `terraform apply` yet.

### Verification

- Root calls **both** `vpc` and `ecr`.  
- **Expected State:** ECR module on disk. Nothing applied.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 4.2 — Create `modules/ecr` and call it

---

## Lab 4.3 — Apply ECR only (no NAT)

### Objective

Create the empty repository. Do **not** create a NAT.

### Procedure

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform init` does **not** create the repository. It reads the new `ecr` module and downloads anything missing. You should see **Terraform has been successfully initialized**.

```bash
terraform init
```

`terraform validate` is a grammar check. It still does **not** touch AWS. You should see **Success! The configuration is valid**.

```bash
terraform validate
```

`terraform plan "-target=module.ecr"` is the preview **for the registry only**. It does **not** create it yet. `-target` means: ignore the VPC module this sitting.

**PowerShell:** quote `"-target=module.ecr"`. PowerShell splits on `.`, so the unquoted command fails with **Too many command line arguments** / Invalid target `module`. Quotes work in PowerShell, Git Bash, and cmd — copy the quoted commands below.

Read the plan. You should see **`aws_ecr_repository`**. You should **not** see `aws_nat_gateway`. If you see a NAT, you omitted `-target`. Stop. Do not apply.

Terraform may print **Warning: Resource targeting is in effect.** That is expected. It is **not** a failure. The plan is still correct if it is **one** ECR resource and **no** NAT.

```bash
terraform plan "-target=module.ecr"
```

`terraform apply "-target=module.ecr"` creates **only** the registry. It will ask you to type `yes`. Until you type `yes`, nothing is created. A bare `terraform apply` (no `-target`) would start a NAT bill. Do not do that. First full VPC re-apply is Workflow 05.

```bash
terraform apply "-target=module.ecr"
```

Type `yes` and press **Enter**. Wait until **Apply complete!**

`terraform output ecr_repository_url` prints the registry URL. It does **not** change AWS. Copy it. You will use the account id from that URL (or Lab 4.4) when you tag and push.

```bash
terraform output ecr_repository_url
```

### See it (root)

Terraform said it created the repository. It should be **empty** — you have not pushed yet. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
   (or [https://aws.amazon.com](https://aws.amazon.com) → **Sign in to the Console**).  
2. **Root user** → the **email that owns the AWS account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**. Wrong region = empty list.

4. Top search bar: type **ECR** (or **Elastic Container Registry**). Open **Elastic Container Registry**.  
5. Left: **Repositories** (Private).  
6. Open the repository named **`accelerator`**.  
7. You should see the repo, and **no** image tag yet (or an empty image list).  
   **Why it matters:** this is the private registry in your account, in this region. It does not serve visitors. ECS later pulls from here — not from your laptop.  
8. Left or top: **VPC → NAT gateways**. Still **empty**.  
   **Why it matters:** you used `-target=module.ecr`. A full apply would have started a NAT bill. No NAT today.

Lab 4.4 pushes `latest`. Lab 4.5 is the look after the push.

### Verification

- Output like `ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator`.  
- You opened **ECR → Repositories → `accelerator`** as the account email. Empty repository. No NAT.  
- **Expected State:** Empty ECR repo. No NAT bill.

### Troubleshooting References

¹ **Symptom:** Plan includes `aws_nat_gateway`.  
  **Resolution:** You omitted `-target`. Stop. Re-run `terraform plan "-target=module.ecr"`.

² **Symptom:** **Too many command line arguments** / Invalid target `module`.  
  **Resolution:** PowerShell split on `.`. Re-run with quotes: `terraform plan "-target=module.ecr"` (same quotes on apply).

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 4.3 — Apply ECR only (no NAT)

---

## Lab 4.4 — Build, login, tag, push

### Objective

Pack `accelerator:latest` on this laptop if it is missing, then upload it to ECR.

### Procedure

Docker Desktop must be **running**. Work from the **accelerator-app** root (not `terraform/`). If you are still in `terraform/`:

```bash
cd ..
```

This prints your 12-digit AWS account id only. Copy it. Paste it in place of `ACCOUNT_ID` below (login, tag, and push).

```bash
aws sts get-caller-identity --query Account --output text
```

`docker build` packs the app on this laptop. It does **not** upload yet. Run it even if you built in Workflow 03 — a prune would have deleted that image.

```bash
docker build -t accelerator:latest .
```

`docker login` uses a **short-lived ECR password**, not your IAM access key. Replace `ACCOUNT_ID`. Region must be `us-east-1`. You should see **Login Succeeded**.

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

`docker tag` gives the local image the registry URL. It does **not** upload yet. Replace `ACCOUNT_ID` again.

```bash
docker tag accelerator:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

`docker push` uploads the image to ECR. Replace `ACCOUNT_ID` again. You should see layers pushed, then a digest. `name unknown` means the repo is missing — finish Lab 4.3.

```bash
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

### See it (root)

If the console is closed, sign in as in Lab 4.1 (account email, **N. Virginia**).

1. Top search: **ECR** → **Repositories** → **`accelerator`**.  
2. Tag **`latest`** is listed. **Pushed at** is recent.  
   **Why it matters:** the registry now holds `accelerator:latest`. Lab 4.5 is the slower walk of the same page. Empty list = the push did not land.

### Verification

- Push completes without `name unknown`.  
- You opened the repo as the **account email** and saw tag **`latest`**.  
- **Expected State:** Tag `latest` is in ECR.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 4.4 — Build, login, tag, push

---

## Lab 4.5 — See the image in the console (root)

### Objective

Prove the packed image is in ECR, not only on your laptop.

### Procedure

If the console is still open from Lab 4.4, skip to step 4. If not:

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → account **email** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

4. Top search: **ECR** → **Elastic Container Registry**.  
5. Left: **Repositories**. Open **`accelerator`**.  
6. Open the **Images** (or tags) list. You should see tag **`latest`**.  
7. Note **Pushed at** (recent) and the image size.  
   **Why it matters:** this is `accelerator:latest` in **your** registry. Workflow 05’s ECS tasks will pull this tag. If this page is empty, the cluster will fail with `CannotPullContainerError`.  
8. You do **not** need a URL or a cluster today. A registry does not serve visitors.

### Verification

- Tag **`latest`** is listed on repository **`accelerator`**.  
- **Expected State:** The image is in AWS. Nothing is running it yet.

### Troubleshooting References

¹ **Symptom:** Repository missing.  
  **Resolution:** Region is not N. Virginia; or Lab 4.3 apply did not finish.  
² **Symptom:** Repo exists, no `latest`.  
  **Resolution:** Lab 4.4 push did not complete. Re-run build, login, tag, push.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 4.5 — See the image in the console (root)

---

## Lab 4.6 — Destroy the ECR repository

Delete the repo (and the image in AWS). **Always** do this. Keep the Dockerfile and the local image.

Do **not** skip this lab. Workflow 05 will apply ECR again and push.

You must be in the `terraform/` folder. If the terminal is in `accelerator-app`, move in. This does **not** destroy anything by itself.

```bash
cd terraform
```

`terraform destroy "-target=module.ecr"` removes **only** the registry (and the image in AWS). It does **not** delete the Dockerfile or the local image `accelerator:latest`. It does **not** create or destroy a NAT (there is no NAT today). It will ask you to type `yes`. Until you type `yes`, nothing is deleted.

Quote `"-target=module.ecr"` in PowerShell (same reason as Lab 4.3).

```bash
terraform destroy "-target=module.ecr"
```

Type `yes` and press **Enter**. Wait until **Destroy complete!**

### See it (root) — registry gone, still no NAT

1. Same sign-in as Lab 4.5 if the console is closed: [https://console.aws.amazon.com](https://console.aws.amazon.com) → **Root user** → account email → **N. Virginia**.  
2. Top search: **ECR** → **Repositories**. **`accelerator`** should be **gone**.  
   **Why it matters:** destroy deleted the repository and the image in AWS. Your Dockerfile and local image `accelerator:latest` stay on the laptop.  
3. Top search: **VPC** → **NAT gateways**. Still **empty**.  
   **Why it matters:** you never applied the VPC today. No leftover bill from this workflow.

### Verification

- **Expected State:** Dockerfile on disk. AWS registry empty.

### Troubleshooting References

¹ **Symptom:** **Too many command line arguments** / Invalid target `module`.  
  **Resolution:** Quote the flag: `terraform destroy "-target=module.ecr"`.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 4.6 — Destroy the ECR repository

---

### Workflow Completion Criteria

- [ ] Targeted apply created **only** ECR (no NAT)  
- [ ] **ECR → Repositories → accelerator → latest** (before destroy)  
- [ ] Targeted destroy removed the repo  

### Where We Are Going Next

**Workflow 05** is **all of ECS**: cluster, one `t3.micro` in an ASG, task definition, and service. Running tasks = 1. No URL.

You will apply **VPC + ECR** (full apply — NAT starts), **push the image again**, then add the ECS modules.

Open `workflow 5 - ECS on EC2.md` when you are ready.
