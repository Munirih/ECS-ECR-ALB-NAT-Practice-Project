# W1 — IAM and Terraform

**Region:** `us-east-1` only
**Prefix:** `accelerator`
**Project:** `accelerator-app`

Do not run `terraform apply`. Do not run `git init` or `git push`.

- [ ] Lab 1.1 — Confirm the console region (root)
- [ ] Lab 1.2 — Create IAM user `accelerator-cli`
- [ ] Lab 1.3 — Configure the AWS CLI
- [ ] Lab 1.4 — Create the Terraform root
- [ ] Lab 1.5 — Initialise and validate (do not apply)
- [ ] Lab 1.6 — Hygiene (nothing to destroy)

---

## Lab 1.1 — Confirm the console region (root)

1. Open [https://console.aws.amazon.com](https://console.aws.amazon.com).
2. Choose **Root user**.
3. Enter the **email that owns the AWS account**.
4. Enter that email’s password. Finish MFA if asked.
5. Top-right region: if it is not **N. Virginia**, select **US East (N. Virginia) `us-east-1`**.

Check:

- Signed in with the account email.
- Top-right region reads **N. Virginia**.

- [ ] Lab 1.1 — Confirm the console region (root)

---

## Lab 1.2 — Create IAM user `accelerator-cli`

1. Stay in the console from Lab 1.1 (account email, **N. Virginia**). If it is closed, sign in again as **Root user** with the account email, region **N. Virginia**.
2. Search **IAM**. Open **IAM** (not Identity Center).
3. **Users** → **Create user**.
4. User name: `accelerator-cli`.
5. **Next** → **Attach policies directly**.
6. Tick **AdministratorAccess**.
7. Leave **Provide user access to the AWS Management Console** unchecked.
8. **Next** → **Create user**.
9. Open **`accelerator-cli`** → **Security credentials**.
10. **Create access key** → **Command Line Interface (CLI)** → tick the confirmation box → **Create access key**.
11. **Download .csv file**. Store it outside `accelerator-app` (for example Documents).
12. **Done**.

Check:

- **IAM → Users → `accelerator-cli`** shows **AdministratorAccess**.
- The CSV is not inside `accelerator-app`.

- [ ] Lab 1.2 — Create IAM user `accelerator-cli`

---

## Lab 1.3 — Configure the AWS CLI

Open a terminal in VS Code at the `accelerator-app` folder.

```bash
aws configure
```

Answer:

- **AWS Access Key ID** → from the CSV
- **AWS Secret Access Key** → from the CSV
- **Default region name** → `us-east-1`
- **Default output format** → `json`

```bash
aws sts get-caller-identity
```

Check:

- `Arn` contains `user/accelerator-cli`.
- `Arn` does not contain `root`.

- [ ] Lab 1.3 — Configure the AWS CLI

---

## Lab 1.4 — Create the Terraform root

1. In the `accelerator-app` root, create `.gitignore` if it does not exist. Paste:

```gitignore
# Do not commit secrets, build output, or Terraform state.

node_modules
# Laptop packages. npm install recreates this folder.

dist
# Vite build output. npm run build recreates it.

.env
# Local secrets. Never GitHub.

*.csv
# Access-key download from Lab 1.2. Never GitHub.

.aws
# Local AWS config. Not the Terraform files.

**/.terraform/
# Plugin cache from terraform init. Not your code.

*.tfstate
# Live Terraform state. Workflow 08 must not push this.

*.tfstate.*
# State backups. Same rule.

crash.log
# Terraform crash log. Local only.

override.tf
# Local override. Not the shared files.

override.tf.json
# JSON override. Same rule.

*_override.tf
# Named override. Same rule.

*_override.tf.json
# Named JSON override. Same rule.
```

2. In the `accelerator-app` root, create a folder named `terraform`.

3. Create `terraform/versions.tf`:

```hcl
# Which Terraform and which AWS plugin these files need.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

4. Create `terraform/providers.tf`:

```hcl
# Talk to AWS in N. Virginia (us-east-1) only.

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Accelerator = "aws-graduate-cloud-skills-accelerator"
    }
  }
}
```

5. Create `terraform/variables.tf`:

```hcl
# Values this Accelerator uses. Defaults match the labs.

variable "project" {
  description = "Name prefix for all accelerator resources"
  type        = string
  default     = "accelerator"
}

variable "aws_region" {
  description = "AWS region — this Accelerator is us-east-1 only"
  type        = string
  default     = "us-east-1"
}
```

6. Create `terraform/outputs.tf`:

```hcl
# What this root can print. Workflow 02 adds VPC ids here.

output "project" {
  description = "Canonical prefix"
  value       = var.project
}

output "aws_region" {
  value = var.aws_region
}
```

7. Create `terraform/main.tf`:

```hcl
# Root — calls only. No resources in Workflow 01.
# Workflow 02 adds: module "vpc"

locals {
  project = var.project
  region  = var.aws_region
}

# No module blocks yet. First apply is Workflow 02 (VPC).
```

8. Save all files. Do not apply.

Check:

- `.gitignore` is in the `accelerator-app` root, not inside `terraform/`.
- `terraform/` contains `versions.tf`, `providers.tf`, `variables.tf`, `outputs.tf`, and `main.tf`.

- [ ] Lab 1.4 — Create the Terraform root

---

## Lab 1.5 — Initialise and validate (do not apply)

From `accelerator-app`:

```bash
cd terraform
terraform init
terraform validate
```

Check:

- `terraform init` prints **Terraform has been successfully initialized**.
- `.terraform.lock.hcl` is next to `versions.tf`. Keep it.
- `terraform validate` prints **Success! The configuration is valid**.
- You did not run `terraform apply`.

- [ ] Lab 1.5 — Initialise and validate (do not apply)

---

## Lab 1.6 — Hygiene (nothing to destroy)

Sign in as **Root user** with the account email. Region: **N. Virginia (`us-east-1`)**.

1. **VPC → Your VPCs.** Confirm there is no `accelerator-vpc`.
2. **EC2 → Instances.** Confirm there is no instance you created today.
3. **IAM → Users.** Confirm `accelerator-cli` still exists. Do not delete it.
4. Confirm the access-key CSV is not inside `accelerator-app`.

No `terraform destroy`.

- [ ] Lab 1.6 — Hygiene (nothing to destroy)

---

## Done

- [ ] Console region is **N. Virginia (`us-east-1`)** as root
- [ ] **IAM → Users → `accelerator-cli`** exists with **AdministratorAccess**
- [ ] `aws sts get-caller-identity` Arn is `user/accelerator-cli`
- [ ] Five `.tf` files are in `accelerator-app/terraform/`
- [ ] `terraform validate` succeeded
- [ ] `terraform apply` was not run
- [ ] `git init` and `git push` were not run

Do not delete `accelerator-cli`.

Next: Workflow 02.
