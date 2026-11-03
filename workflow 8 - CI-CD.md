# Workflow 08 — CI/CD
## The release train: GitHub push → live URL

**Programme:** AWS Graduate Cloud Skills Accelerator  
**Region:** `us-east-1` only  
**Prefix:** `accelerator`  
**Project:** the `accelerator-app` folder  
**GitHub:** you publish the repo with **git** **in this workflow** (suggested name `accelerator`)  

---

# Workflow Overview

Workflow 07 proved you can deploy manually as tedious as it was.

This chapter **publishes the GitHub repo with git**, adds `buildspec.yml` and `modules/cicd`, and **requires you to approve a GitHub connection as root in the console** (Terraform cannot finish that click). Then a **`git push`** builds the image, pushes it to the registry, and rolls ECS. You open `http://` the same ALB.

Then you destroy. The Accelerator story ends.

---

### The 5 Codewrkx Engineer Questions

**What is the problem?**  
Humans should not `docker build`, push, and roll **ECS (Elastic Container Service)** for every change. That is slow and easy to skip.

A **region** is a geographic AWS location — a cluster of **data centres**. Light picture: the **city**. The pipeline, the registry, and reception must all sit in **N. Virginia (`us-east-1`)**. Lab 8.2 in the wrong region = Source never sees GitHub.

**Why solve it with these services?**  
**CodePipeline (AWS CodePipeline)** is the **release train**. **CodeBuild (AWS CodeBuild)** is the build machine. **GitHub** holds the source. A **`git push`** to `main` is what Source watches (`DetectChanges = true`). The live URL stays the same **ALB (Application Load Balancer)** — you do not build a second door. `buildspec.yml` is the **recipe** CodeBuild runs. It is **not** the trigger.

**When are these services used?**  
On every push to the watched branch (here: `main`). The GitHub connection is created **once** (Lab 8.2 — required console click). You do not apply a new pipeline per page load.

**How does this work?**  
In this order:

| Command / click | Today |
|-----------------|--------|
| Lab 8.1 — publish with git | Empty repo `accelerator` on github.com, then `gh auth login` as **YOUR_USER**, then the git commands in that lab. |
| Lab 8.2 console click | Connection **Available**. Terraform cannot finish this handshake. |
| `git commit` + `git push` (recipe) | `buildspec.yml` must be on `main` **before** the pipeline apply. |
| `terraform init` | Read `modules/cicd`. |
| `terraform validate` | Grammar check. |
| `terraform plan` | Preview: S3, CodeBuild, CodePipeline. Confirm **not** a second NAT. |
| `terraform apply` | Build the pipeline. Type `yes`. |
| `git push origin main` (tagline) | Source → Build → Deploy. |
| `terraform output app_url` | Same **`http://`** reception. |
| `terraform destroy` | Pipeline, reception, cluster, NAT down. GitHub repo stays. |

**Who typically deploys them?**  
Platform engineers own the pipeline. Application engineers push code. You write both. Lab 8.2 is **root** in the browser. `accelerator-cli` **applies** and **destroys**. **git** is **you** shipping.

---

### Where We Came From

Five Terraform modules. A manual loop: apply, docker build, push, sometimes `force-new-deployment`. There is **no** GitHub repo yet. AWS is empty. You destroyed at the end of Workflow 07.

### Where We Are Now

You will publish a GitHub repo with **git**, bring the app stack up, create a **CodeStar / CodeConnections** link to GitHub **in the console** (required click), add the pipeline module, **push `buildspec.yml` before you apply**, then ship a tagline with `git push` and watch the console hop by hop.

### Where We Are Going

After a green pipeline and a browser proof, you teardown. You keep the Terraform files. That is the portfolio.

### Launch context

The product is still only on your laptop. Today you put it on GitHub and add the **release train**: CodeBuild produces a new artefact, pushes ECR, and ECS rolls the service. After that you do not build and push on your laptop for every change.

The GitHub App connection is a **required console click** (Lab 8.2). Terraform cannot finish that approval for you. Pending is not a Terraform bug.

### Technical Context

```text
git push origin main
    → CodePipeline Source  (CodeStar connection)
    → CodeBuild            (docker build, privileged)
    → ECR                  accelerator:latest
    → ECS Deploy           imagedefinitions.json
    → ALB                  same app_url
```

| Resource | Responsibility |
|-------|----------|
| GitHub connection | OAuth / GitHub App. Status must be **Available**. |
| `buildspec.yml` | What CodeBuild runs. Must live in the **repo root**. |
| CodeBuild | Privileged Linux image so Docker works. |
| `imagedefinitions.json` | Tells ECS which container name + image URI to roll. Name must be `accelerator`. |
| CodePipeline | Source → Build → Deploy. Artifacts in S3. |

CodeBuild is **not** in your VPC. It reaches ECR on the public AWS network. Your tasks still pull through the NAT.

### Why This Workflow Matters

This is the last interview sentence: “A `git push` ships a new image to ECS behind the ALB.”

### What We Will Build

`buildspec.yml`, a GitHub repo published with git, module `cicd`, one working pipeline (then destroyed).

### Architecture Snapshot

When [`architecture.png`](architecture.png) is in this Accelerator folder, that is the full drawing. If it is not there yet, use the text snapshot below.

```text
GitHub (YOUR_USER/accelerator)
        │
        ▼
accelerator-pipeline
        │
        ├─ Source
        ├─ Build   (accelerator-build)
        └─ Deploy  (accelerator-cluster / accelerator-service)
                │
                ▼
         http://ALB_DNS
```

### SOFTWARE DELIVERY PROGRESS: ✓ 0 Intro → ✓ 01 Access → ✓ 02 VPC → ✓ 03 Docker → ✓ 04 ECR → ✓ 05 ECS → ✓ 06 ALB → ✓ 07 Prove → ► 08 Pipeline

### Learning Outcomes

- Publish the GitHub repo with **git** and **approve** a GitHub connection in the console (required click)  
- Author a Docker `buildspec.yml`  
- Add a Terraform pipeline module  
- Prove a commit updates the live page  

### Key Terminology

| Term | Meaning |
|------|---------|
| CodeStar connection | Named link from AWS to GitHub (GitHub App) |
| CodeBuild | Managed build machine |
| Privileged mode | CodeBuild may start Docker |
| imagedefinitions.json | ECS deploy artefact |
| Pipeline stage | Source, Build, or Deploy |

### Labs

Tick as you finish. Change `- [ ]` to `- [x]`.

- [ ] Lab 8.1 — Publish the GitHub repo, then bring the stack back
- [ ] Lab 8.2 — GitHub connection (root, console) — required click
- [ ] Lab 8.3 — Root variables for GitHub
- [ ] Lab 8.4 — Create `buildspec.yml`
- [ ] Lab 8.5 — Create `modules/cicd`
- [ ] Lab 8.6 — Call `cicd` from the root
- [ ] Lab 8.7 — Put `buildspec.yml` on GitHub, then apply the pipeline
- [ ] Lab 8.8 — Push a commit and watch
- [ ] Lab 8.9 — Open the URL again
- [ ] Lab 8.10 — See the hops (root checklist)
- [ ] Lab 8.11 — Teardown

---

## Lab 8.1 — Publish the GitHub repo, then bring the stack back

### Objective

Put `accelerator-app` (and the Terraform files) on GitHub with **git**. Then restock AWS so the pipeline has somewhere to deploy.

Do **not** commit `terraform.tfstate`, `.terraform/`, or keys.

### Procedure — GitHub (git)

Windows and Mac use the same commands. Git, your git identity, and **GitHub CLI** (`gh`) must already be installed (**What to install**, including section 10).

1. In VS Code, confirm `.gitignore` still lists `*.tfstate`, `.terraform/`, and `.env` (Workflow 01). Do this **before** the first commit.

2. In a browser, sign in at [https://github.com](https://github.com). Click **New repository**.  
   - Name: **`accelerator`**.  
   - Private or public is fine.  
   - Do **not** add a README, `.gitignore`, or license — you already have files.  
   - Click **Create repository**.  
   - GitHub will show its own setup commands. **Ignore them.** Use the **HTTPS** URL, not SSH. Run only the commands below.

If this folder is already on GitHub as `YOUR_USER/accelerator`, check the website, then continue at Procedure — AWS stack.

Open a terminal in the **accelerator-app** root (not `terraform/`).

`git init` starts a Git database in this folder. It does **not** create a GitHub repo. It does **not** upload files. You should see **Initialized empty Git repository** (or that it already exists — that is fine).

```bash
git init
```

`git branch -M main` names this branch **main**. It does **not** push. The name must match `github_branch` in Lab 8.3.

```bash
git branch -M main
```

`git add .` stages every file that is **not** in `.gitignore`. It does **not** commit. It does **not** talk to GitHub.

```bash
git add .
```

`git status` lists what will be in the first commit. It does **not** change files. You should see `Dockerfile`, `src/`, `terraform/`, and **`.terraform.lock.hcl`** (Workflow 01 Lab 1.5 — keep it; it is **not** secrets). If you see `terraform.tfstate`, `.terraform/` (the **folder**), or `.env`, **stop**. Fix `.gitignore`. Then `git reset` (unstages; does **not** delete your files), `git add .`, and `git status` again until those files are gone.

```bash
git status
```

`git commit` writes the first snapshot on this laptop. It does **not** upload. You should see a commit hash.

```bash
git commit -m "Accelerator app and Terraform files"
```

Replace `YOUR_USER` with your GitHub username. Use this **HTTPS** URL, not SSH. `git remote add origin` stores the GitHub URL. It does **not** upload.

```bash
git remote add origin https://github.com/YOUR_USER/accelerator.git
```

If it says remote origin already exists, that is fine. Continue.

`git remote -v` prints where `origin` points. It does **not** upload. You should see `https://github.com/YOUR_USER/accelerator.git` twice (fetch and push).

```bash
git remote -v
```

`gh auth login` signs **this terminal** into GitHub. It does **not** upload files. It does **not** create the repo.

Sign in as **YOUR_USER** — the same GitHub username you put in the remote URL. That is the account you will authorise in Lab 8.2. If this laptop is already signed in as someone else, sign in again as **YOUR_USER**.

```bash
gh auth login
```

Choose **GitHub.com**. Choose **HTTPS**. Choose **Login with a web browser**. If it asks to authenticate Git with your GitHub credentials, say **yes**. A browser will open, or the terminal will ask you to press **Enter** for a GitHub page. Sign in there as **YOUR_USER**. Finish GitHub **2FA** if asked. You are done when the terminal says you are logged in as **YOUR_USER**.

`gh auth status` prints which GitHub user this terminal will use. It does **not** upload. The login must be **YOUR_USER**. If it is a different name, run `gh auth login` again as **YOUR_USER**.

```bash
gh auth status
```

`git push -u origin main` uploads `main` to GitHub. You should see **branch 'main' set up to track**.

```bash
git push -u origin main
```

Open github.com in a browser. Confirm `Dockerfile`, `src/`, and `terraform/` are there, and **no** `.tfstate`.

### Procedure — AWS stack

AWS is empty after Workflow 07. Bring the five modules back. Do **not** add `cicd` yet.

Open a terminal in the **accelerator-app** folder.

`aws sts get-caller-identity` asks AWS: “who am I?” It does **not** create anything. The `Arn` must contain `user/accelerator-cli`. If it contains `root`, stop. Workflow 01 Labs 1.2–1.3.

```bash
aws sts get-caller-identity
```

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

Open `modules/ecs-service/main.tf`. You must see `deployment_maximum_percent = 100` and **no** `count =` on `alb_http_in`. If either is wrong, paste Workflow 06 Lab 6.4 **Your file must look like this**, then continue. Same check as Workflow 07 Lab 7.1.

`terraform init` does **not** launch the pipeline. It re-reads the five app modules. You should see **Terraform has been successfully initialized**.

```bash
terraform init
```

`terraform validate` is a grammar check. It still does **not** touch AWS. You should see **Success! The configuration is valid**.

```bash
terraform validate
```

`terraform plan` is the preview. It does **not** create anything yet. **One** plan of the five app modules. **No** `-target`.

Read the plan. You should see vpc, ecr, cluster, service, and ALB. You should **not** see CodePipeline. If you see a pipeline, stop. Do not apply. `cicd` comes after `buildspec.yml` is on GitHub (Lab 8.7).

Do **not** run `terraform apply "-target=module.alb"`. That skips the Internet Gateway from empty AWS (**InvalidSubnet**). If plan dies with **Invalid count argument**, your service still has `count` — fix the file above, then plan again.

```bash
terraform plan
```

`terraform apply` is a **full** apply of vpc + ecr + ecs + alb. **NAT and ALB hours start.** There is still **no** pipeline. It will ask you to type `yes`. Until you type `yes`, nothing is created. **Running = 0** until you push is expected — ECR is empty after destroy. **No** `-target`.

```bash
terraform apply
```

Type `yes` and press **Enter**. Wait until **Apply complete!**

### See it (root) — after apply

The house, cluster, and reception are back. There is **no** pipeline yet. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
   (or [https://aws.amazon.com](https://aws.amazon.com) → **Sign in to the Console**).  
2. **Root user** → **email that owns the account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

4. **VPC → Your VPCs → `accelerator-vpc`**. **NAT gateways → `accelerator-nat`** **Available**. **One** row.  
   **Why it matters:** the host still pulls through this service exit (NAT). The clock is running.

5. **ECR → Repositories → `accelerator`**. Empty until you push below.  
   **Why it matters:** Workflow 07 destroy deleted `latest`.

6. **EC2 → Load Balancers → `accelerator-alb`**. State should become **Active**.  
   **Why it matters:** the live URL is this reception. The pipeline in Lab 8.7 will roll tasks **behind** it — it will not create a second ALB.

7. Top search: **CodePipeline → Pipelines**. There is **no** `accelerator-pipeline`.  
   **Why it matters:** this apply is the five app modules only.

### Procedure — restock the registry

Destroy in Workflow 07 deleted the image. Docker Desktop must be **running**. Work from the **accelerator-app** root (not `terraform/`). If you are still in `terraform/`:

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

`docker push` puts `latest` in the registry. Replace `ACCOUNT_ID`. Empty registry = the first task stays at Running = 0.

```bash
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

Wait until the target is healthy (See it below). Then print the visitor address. You must be in `terraform/` for this command. If you are in `accelerator-app`:

```bash
cd terraform
```

`terraform output app_url` prints the ALB URL. It does **not** change AWS. Copy it. Open it over **`http://`**.

```bash
terraform output app_url
```

### See it (root) — after push

If the console is closed, sign in again (steps 1–3 above). Region **N. Virginia**.

1. **ECR → Repositories → `accelerator`**. Tag **`latest`**.  
2. **EC2 → Target Groups → `accelerator-tg` → Targets**. One IP **healthy** (wait; refresh).  
3. `terraform output app_url` — open it over **`http://`**. Landing page loads.  
   **Why it matters:** the stack can serve visitors **before** the pipeline exists. Lab 8.8 proves a **`git push`** can change that same page.

### Verification

- GitHub shows the repo with `Dockerfile`, `src/`, and `terraform/` (no state files).  
- Running = 1. ALB healthy. `app_url` works.  
- **No** `accelerator-pipeline` yet.  
- **Expected State:** Repo exists. App stack is up. Pipeline is not installed yet.

### Troubleshooting References

¹ **Symptom:** `tfstate` in the GitHub file list.  
  **Resolution:** Remove it from the repo, fix `.gitignore`, rotate if it held secrets.  
² **Symptom:** Unhealthy / no pull.  
  **Resolution:** Workflow 07 Labs 7.2–7.5.  
³ **Symptom:** `git push` fails / sign-in loop / **Repository not found**.  
  **Resolution:** This terminal is signed in as the **wrong** GitHub user (GitHub hides a private repo). Run `gh auth login` as **YOUR_USER**. Finish 2FA. Then `gh auth status` must show **YOUR_USER**. Push again.  
⁴ **Symptom:** `failed to push` / rejected — remote already has a README.  
  **Resolution:** You added a README when creating the repo. Delete that file on github.com, or create a new empty repo named `accelerator`. Do not force-push in this Accelerator.  
⁵ **Symptom:** `Please tell me who you are`.  
  **Resolution:** **What to install** section 7. Set `git config --global user.name` and `user.email`.  
⁶ **Symptom:** `git@github.com` / Permission denied (publickey).  
  **Resolution:** You used SSH. Remove it (`git remote remove origin`), then add the **HTTPS** URL from Lab 8.1.  
⁷ **Symptom:** `gh: command not found`.  
  **Resolution:** **What to install** section 10. Install GitHub CLI. New terminal. `gh --version`.  
⁸ **Symptom:** **Invalid count argument** on `alb_http_in`.  
  **Resolution:** Paste Workflow 06 Lab 6.4 **Your file must look like this** (no `count`). One full `terraform apply`. No `-target`.  
⁹ **Symptom:** **InvalidSubnet: VPC has no internet gateway**.  
  **Resolution:** You targeted `module.alb`. Stop. Full `terraform apply` with **no** `-target`.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.1 — Publish the GitHub repo, then bring the stack back

---

## Lab 8.2 — GitHub connection (root, console) — required click

### Objective

**You must do this in the browser.** Make the connection **Available**. Copy its ARN. Terraform will only **store and use** that ARN — it cannot finish the GitHub handshake.

Skip this lab and Source fails. A **Pending** connection is not a Terraform bug.

### Why this lab exists

The GitHub App install is a browser handshake (sign in, install AWS Connector, grant the repo). Lab 8.1 published the repo with git. This lab is the **AWS** side of that link. A connection left in **Pending** means Source fails.

### Procedure

If the console is still open from Lab 8.1, skip to step 4. If not:

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → account **email** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**. Wrong region = you will create the connection in the wrong city.

4. Top search: **CodePipeline**. Open **CodePipeline**.  
5. Left: **Settings → Connections** (or search **Developer Tools → Connections**).  
6. Click **Create connection**.  
7. Choose **GitHub**.  
8. Connection name: **`accelerator-github`**.  
9. Click **Connect to GitHub**. A GitHub window opens. Sign in as **YOUR_USER** — the same GitHub account that owns the repo from Lab 8.1. Authorise if GitHub asks.  
10. You land back in **AWS**, on a **GitHub Apps** step. Click **Install a new app**.  
    AWS may mark this optional. It is **not** optional in this Accelerator. Authorise alone is not enough. Skip it and the connection can still go **Available**, but Source will not see a private `main`.  
11. GitHub opens the **AWS Connector for GitHub** install page. Choose **Only select repositories**. Pick **`accelerator`**. Click **Install**.  
12. Back in **AWS**, the new install is selected. Click **Connect**.  
13. Wait until status is **Available**. Do **not** paste a **Pending** ARN into Terraform.  
    **Why it matters:** Terraform can only **store** this ARN. It cannot finish the GitHub App handshake. **Pending** = Source will fail in Lab 8.8. That is not a Terraform bug.

14. Open the connection **`accelerator-github`**. Copy the **ARN**  
    (looks like `arn:aws:codeconnections:us-east-1:ACCOUNT:connection/xxxxxxxx`).  
    **Why it matters:** Lab 8.3 puts this ARN in `terraform.tfvars`. The pipeline Source stage uses it to read `main`.

### Verification

**CodePipeline → Settings → Connections → `accelerator-github`** → status **Available**. You signed in as the **account email**.  
On GitHub (as **YOUR_USER**): **Settings → Applications → Installed GitHub Apps** shows **AWS Connector for GitHub** with **Configure** (not only **Revoke** on Authorised apps).  
- **Expected State:** Handshake done. App installed. ARN on your clipboard. Ready for Lab 8.3.

### Troubleshooting References

¹ **Symptom:** Status **Pending**.  
  **Resolution:** Finish **Install a new app**, pick the repo, then **Connect** in AWS. Refresh. Do not apply the pipeline yet. Do not paste this ARN.  
² **Symptom:** Repo not listed / **Install a new app** shows the wrong GitHub user.  
  **Resolution:** You authorised the wrong GitHub user. Sign out of github.com, sign in as the account that owns `YOUR_USER/accelerator`, run **Connect to GitHub** again.  
³ **Symptom:** Connection **Available**, but GitHub **Installed GitHub Apps** is empty, or Source says **No Branch [main] found**.  
  **Resolution:** You authorised and skipped **Install a new app**. Delete this connection. Create it again. This time click **Install a new app**, pick **`accelerator`**, then **Connect**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.2 — GitHub connection (root, console) — required click

---

## Lab 8.3 — Root variables for GitHub

### Objective

Tell Terraform which connection and repo to use. Do **not** apply in this lab.

### Why this lab exists

The pipeline Source stage needs three values: the **Available** connection ARN from Lab 8.2, the GitHub `owner/repo`, and the branch. Those live in `terraform.tfvars` so you do not paste the ARN into `main.tf`.

You add **one slice at a time**. If a slice goes wrong, skip to **Your file must look like this**.

### Slice 1 — three new variables

Open `terraform/variables.tf`. **Keep** `project` and `aws_region`. Paste these three at the **bottom**.

```hcl
# Pipeline Source. ARN from Lab 8.2. Repo from git in Lab 8.1.

variable "codestar_connection_arn" {
  type        = string
  description = "ARN of the Available GitHub connection from Lab 8.2"
}

variable "github_repository" {
  type        = string
  description = "GitHub owner/repo, e.g. myuser/accelerator"
}

variable "github_branch" {
  type    = string
  default = "main"
}
```

Save.

### Your file must look like this — `terraform/variables.tf`

```hcl
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

# Pipeline Source. ARN from Lab 8.2. Repo from git in Lab 8.1.

variable "codestar_connection_arn" {
  type        = string
  description = "ARN of the Available GitHub connection from Lab 8.2"
}

variable "github_repository" {
  type        = string
  description = "GitHub owner/repo, e.g. myuser/accelerator"
}

variable "github_branch" {
  type    = string
  default = "main"
}
```

### Slice 2 — `terraform.tfvars`

Create `terraform/terraform.tfvars`. This is **not** a secret file — only names and the connection ARN. Do **not** put IAM keys here.

Replace `PASTE_ARN_FROM_LAB_8_2` with the ARN you copied. Replace `YOUR_USER` with your GitHub username. The repo name must match what you published in Lab 8.1.

```hcl
# Values for this laptop. Not IAM keys.

codestar_connection_arn = "PASTE_ARN_FROM_LAB_8_2"
github_repository       = "YOUR_USER/accelerator"
github_branch           = "main"
```

Save.

Confirm `.gitignore` includes `*.tfstate`. You **may** commit `terraform.tfvars` if it has no keys. If you prefer not to, keep it local.

### Verification

- ARN starts with `arn:aws:` and the connection is Available.  
- `github_repository` matches the repo you published with git in Lab 8.1 (`YOUR_USER/accelerator`).  
- **Expected State:** Root can pass values into `cicd`.

### Troubleshooting References

¹ **Symptom:** Wrong branch (`master` vs `main`).  
  **Resolution:** GitHub → repo → default branch. Set `github_branch` to match.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.3 — Root variables for GitHub

---

## Lab 8.4 — Create `buildspec.yml`

### Objective

Put the build recipe in the **accelerator-app root** (next to `Dockerfile`), not inside `terraform/`. Do **not** apply in this lab.

### Why this lab exists

CodeBuild runs this file from the **commit on `main`**. Lab 8.7 will push it **before** you apply the pipeline. The JSON `name` must be **`accelerator`** — same as the container in the task definition.

`$ECR_REGISTRY` and `$ECR_REPOSITORY` are set on the CodeBuild project (Lab 8.5). They survive every command. Do **not** assign `IMAGE_URI` in `pre_build` — CodeBuild runs each command in a new shell, so that variable would be empty in `build` / `post_build`.

You add **one slice at a time** (paste each slice at the **bottom**, then save). If a slice goes wrong, skip to **Your file must look like this** and replace the whole file.

### Procedure — file

In Explorer, right-click the **accelerator-app** folder (the project root, not `terraform/`). **New File** → name it `buildspec.yml`.

### Slice 1 — login

This phase only logs CodeBuild into ECR. It does **not** build the image yet.

```yaml
# Recipe for the build machine. Lives next to Dockerfile. Not inside terraform/.

version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
```

Save.

### Slice 2 — build and tag

**Why this is next:** this is `docker build` on the build machine, not on your laptop. Tag stays `latest`.

Paste at the **bottom** of `buildspec.yml`. Keep the same indent as `pre_build` (two spaces before `build:`).

```yaml
  build:
    commands:
      - echo Build started
      - docker build -t $ECR_REPOSITORY:latest .
      - docker tag $ECR_REPOSITORY:latest $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

Save.

### Slice 3 — push and the ECS ticket

**Why this is next:** `docker push` puts the image in the registry. `imagedefinitions.json` tells ECS which container to roll. The `"name"` must be **`accelerator`**. `artifacts` is what CodePipeline Deploy reads.

Paste at the **bottom** of `buildspec.yml`:

```yaml
  post_build:
    commands:
      - echo Pushing $ECR_REGISTRY/$ECR_REPOSITORY:latest
      - docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
      - printf '[{"name":"accelerator","imageUri":"%s"}]' "$ECR_REGISTRY/$ECR_REPOSITORY:latest" > imagedefinitions.json
      - cat imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

Save.

### Your file must look like this — `buildspec.yml`

If a slice went wrong (especially indent), replace the whole file with this block.

```yaml
# Recipe for the build machine. Lives next to Dockerfile. Not inside terraform/.

version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
  build:
    commands:
      - echo Build started
      - docker build -t $ECR_REPOSITORY:latest .
      - docker tag $ECR_REPOSITORY:latest $ECR_REGISTRY/$ECR_REPOSITORY:latest
  post_build:
    commands:
      - echo Pushing $ECR_REGISTRY/$ECR_REPOSITORY:latest
      - docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
      - printf '[{"name":"accelerator","imageUri":"%s"}]' "$ECR_REGISTRY/$ECR_REPOSITORY:latest" > imagedefinitions.json
      - cat imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

### Verification

- `buildspec.yml` is in the same folder as `Dockerfile`.  
- **Expected State:** Build machine has a script.

### Troubleshooting References

¹ **Symptom:** File inside `terraform/`.  
  **Resolution:** Move it to the repo root. CodeBuild looks at the source root.  
² **Symptom:** Indent looks wrong.  
  **Resolution:** Replace the whole file with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.4 — Create `buildspec.yml`

---

## Lab 8.5 — Create `modules/cicd`

### Objective

Build the pipeline: S3 artefact bucket, CodeBuild (privileged), CodePipeline (Source → Build → Deploy). Do **not** apply in this lab. Lab 8.7 applies after `buildspec.yml` is on GitHub.

### Why this lab exists

The root stays a list of calls. The pipeline lives in `modules/cicd`. CodeBuild is **not** in your VPC. Privileged mode lets it start Docker.

You add **one slice at a time** to `main.tf` (paste each slice at the **bottom**, then save). If a slice goes wrong, skip to **Your file must look like this** and replace the whole `main.tf`.

### Procedure — folder and variables

1. In Explorer, right-click the existing `terraform` folder.  
2. Open `modules`. Right-click `modules` → **New Folder** → name it `cicd`.

### Slice 1 — variables

Create `terraform/modules/cicd/variables.tf`. The root will pass the connection ARN, the GitHub repo, and the cluster and service names.

Paste:

```hcl
# Values the root will pass in.

variable "project" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "codestar_connection_arn" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "ecr_repository_url" {
  type        = string
  description = "Full URL without tag"
}

variable "ecr_repository_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}
```

Save.

### Slice 2 — artefact bucket

Create `terraform/modules/cicd/main.tf`. Leave it empty, then paste this slice.

This bucket holds pipeline zip files. `force_destroy = true` so `terraform destroy` can delete it. Block public access. The `ecr_registry` local is the registry address CodeBuild will use.

```hcl
# 1. Who we are, then the S3 bucket for pipeline zip files.

data "aws_caller_identity" "current" {}

locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "${var.project}-pipeline-artifacts"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

Save.

### Slice 3 — CodeBuild

**Why this is next:** this is the build machine. `privileged_mode = true` so Docker works. Environment variables `ECR_REGISTRY` and `ECR_REPOSITORY` are what `buildspec.yml` uses. The role may log, talk to ECR, and write to the artefact bucket.

Paste at the **bottom** of `main.tf`:

```hcl
# 2. Build machine. Privileged so Docker works. Not in your VPC.

resource "aws_iam_role" "codebuild" {
  name = "${var.project}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.project}-codebuild"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      }
    ]
  })
}

resource "aws_codebuild_project" "app" {
  name         = "${var.project}-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "ECR_REGISTRY"
      value = local.ecr_registry
    }

    environment_variable {
      name  = "ECR_REPOSITORY"
      value = var.ecr_repository_name
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}
```

Save.

### Slice 4 — pipeline IAM

**Why this is next:** the pipeline needs a badge. It may read GitHub through the Lab 8.2 connection, start CodeBuild, write S3, and update ECS.

Paste at the **bottom** of `main.tf`:

```hcl
# 3. Badge the pipeline wears.

resource "aws_iam_role" "pipeline" {
  name = "${var.project}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "pipeline" {
  name = "${var.project}-pipeline"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:UseConnection", "codeconnections:UseConnection"]
        Resource = var.codestar_connection_arn
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.app.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:TagResource",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "*"
      }
    ]
  })
}
```

Save.

### Slice 5 — the pipeline

**Why this is next:** three stages: Source (GitHub), Build (CodeBuild), Deploy (ECS). `DetectChanges = true` so a **`git push`** starts the pipeline. `FileName = imagedefinitions.json` is what Lab 8.4 wrote.

Paste at the **bottom** of `main.tf`:

```hcl
# 4. The pipeline: Source → Build → Deploy.

resource "aws_codepipeline" "this" {
  name     = "${var.project}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repository
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
```

Save.

### Your file must look like this — `modules/cicd/main.tf`

If a slice went wrong (especially IAM JSON), replace the whole file with this block.

```hcl
# 1. Who we are, then the S3 bucket for pipeline zip files.

data "aws_caller_identity" "current" {}

locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "${var.project}-pipeline-artifacts"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# 2. Build machine. Privileged so Docker works. Not in your VPC.

resource "aws_iam_role" "codebuild" {
  name = "${var.project}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.project}-codebuild"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      }
    ]
  })
}

resource "aws_codebuild_project" "app" {
  name         = "${var.project}-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "ECR_REGISTRY"
      value = local.ecr_registry
    }

    environment_variable {
      name  = "ECR_REPOSITORY"
      value = var.ecr_repository_name
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}
# 3. Badge the pipeline wears.

resource "aws_iam_role" "pipeline" {
  name = "${var.project}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "pipeline" {
  name = "${var.project}-pipeline"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:UseConnection", "codeconnections:UseConnection"]
        Resource = var.codestar_connection_arn
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.app.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:TagResource",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "*"
      }
    ]
  })
}
# 4. The pipeline: Source → Build → Deploy.

resource "aws_codepipeline" "this" {
  name     = "${var.project}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repository
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
```

### Slice 6 — outputs

Create `terraform/modules/cicd/outputs.tf`. The root will print the pipeline name.

```hcl
# What the root may ask this pipeline for.

output "pipeline_name" {
  value = aws_codepipeline.this.name
}

output "codebuild_project_name" {
  value = aws_codebuild_project.app.name
}
```

Save.

### Verification

- Three files under `modules/cicd`.  
- **Expected State:** Pipeline module on disk.

### Troubleshooting References

¹ **Symptom:** Paste cut off in the IAM JSON.  
  **Resolution:** Replace `modules/cicd/main.tf` with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.5 — Create `modules/cicd`

---

## Lab 8.6 — Call `cicd` from the root

### Objective

Wire the pipeline into the root. Do **not** apply in this lab. Lab 8.7 pushes `buildspec.yml` first, then applies.

### Procedure

Open `terraform/main.tf`. **Keep** `vpc`, `ecr`, `ecs_cluster`, `alb`, and `ecs_service`. **Add** `module "cicd"` at the bottom.

### Your file must look like this — `terraform/main.tf`

If the new call looks wrong, replace the whole file with this block. Do **not** delete the five app modules.

```hcl
# Root — calls only. Workflow 08 applies the five app modules plus the pipeline.

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

module "cicd" {
  source = "./modules/cicd"

  project                 = local.project
  aws_region              = local.region
  codestar_connection_arn = var.codestar_connection_arn
  github_repository       = var.github_repository
  github_branch           = var.github_branch
  ecr_repository_url      = module.ecr.repository_url
  ecr_repository_name     = module.ecr.repository_name
  ecs_cluster_name        = module.ecs_cluster.cluster_name
  ecs_service_name        = module.ecs_service.service_name
}
```

Open `terraform/outputs.tf`. **Keep** the existing outputs. **Add**:

```hcl
output "pipeline_name" {
  value = module.cicd.pipeline_name
}
```

Save. **Do not** `terraform apply` yet. `buildspec.yml` must land on GitHub first (Lab 8.7).

### Verification

- Six modules.  
- **Expected State:** Ready to apply.

### Troubleshooting References

¹ **Symptom:** Missing `cluster_name` output.  
  **Resolution:** Workflow 05 `ecs-cluster` outputs `cluster_name`.  
² **Symptom:** The `cicd` call looks wrong.  
  **Resolution:** Replace `terraform/main.tf` with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.6 — Call `cicd` from the root

---

## Lab 8.7 — Put `buildspec.yml` on GitHub, then apply the pipeline

### Objective

CodeBuild reads `buildspec.yml` from the **commit on `main`**. If you apply the pipeline first, the first run often starts immediately and fails because Lab 8.1 published the repo **without** this file.

Push the recipe and the Terraform pipeline files with **git**, then apply.

### Procedure

Work from the **accelerator-app** root (not `terraform/`).

`git add .` stages the new recipe and pipeline files. It does **not** commit. It does **not** talk to GitHub.

```bash
git add .
```

`git status` lists what will go in this commit. It does **not** change files. You should see `buildspec.yml` and Terraform pipeline files (`terraform/modules/cicd`, `terraform/main.tf`, `terraform/outputs.tf`, `terraform/variables.tf`). If you see `terraform.tfstate`, `.terraform/`, or `.env`, **stop**. Fix `.gitignore`. Then `git reset`, `git add .`, and `git status` again until those files are gone.

```bash
git status
```

`git commit` writes the snapshot on this laptop. It does **not** upload.

```bash
git commit -m "Add CodeBuild recipe and pipeline module"
```

`git push origin main` uploads the commit to GitHub. Source will be able to read `buildspec.yml` from `main`.

```bash
git push origin main
```

On github.com, open the repo. Confirm `buildspec.yml` is in the **root** (next to `Dockerfile`).

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform init` does **not** start the pipeline. It reads the new `cicd` module. You should see **Terraform has been successfully initialized**.

```bash
terraform init
```

`terraform validate` is a grammar check. It still does **not** touch AWS. You should see **Success! The configuration is valid**.

```bash
terraform validate
```

`terraform plan` is the preview. It does **not** create anything yet.

Read the plan. You should see S3, CodeBuild, and CodePipeline. You should **not** see a second NAT. If you see two NATs, stop. Do not apply.

```bash
terraform plan
```

`terraform apply` builds the pipeline. It will ask you to type `yes`. Until you type `yes`, nothing is created. Apply often starts a first pipeline run — that is why `buildspec.yml` had to be on `main` first.

```bash
terraform apply
```

Type `yes` and press **Enter**. Wait until **Apply complete!**

### See it (root)

The pipeline exists. If the console is closed, sign in as in Lab 8.2 (account email, **N. Virginia**).

1. Top search: **CodePipeline** → **Pipelines** → **`accelerator-pipeline`**.  
   **Why it matters:** this is the pipeline. A first execution may already be **In progress** (apply often starts one).

2. Open the latest execution. Stages: **Source**, **Build**, **Deploy**.  
   **Why it matters:** Source reads GitHub through the Lab 8.2 connection. Build runs `buildspec.yml` from `main`. Deploy rolls ECS. Lab 8.8 is the **app** proof — a first-run hiccup is not “skip 8.8.”

3. Top search: **CodeBuild** → **Build projects** → **`accelerator-build`**.  
   **Why it matters:** this is the build machine. Privileged so Docker works. It is **not** in your VPC.

4. **VPC → NAT gateways** — still **one** NAT.  
   **Why it matters:** the pipeline did not add a second NAT.

5. If Build already failed with missing `buildspec.yml`: you applied before **`git push`**. Finish the GitHub steps, then on the pipeline click **Release change**.

### Verification

**CodePipeline → Pipelines → `accelerator-pipeline`**.  
**CodeBuild → Build projects → `accelerator-build`**.  
- **Expected State:** Pipeline exists. A first run may start on apply. It should find `buildspec.yml`. Lab 8.8 is the app-change proof — do not treat a first-run hiccup as “skip 8.8.”

### Troubleshooting References

¹ **Symptom:** Connection not found / not authorised.  
  **Resolution:** Lab 8.2 status **Available**; ARN in `terraform.tfvars` has no extra quotes/spaces.  
² **Symptom:** Bucket name taken.  
  **Resolution:** Account id suffix should be unique. Re-read apply error; do not use a global bare name.  
³ **Symptom:** First Build failed — missing `buildspec.yml`.  
  **Resolution:** You applied before **`git push`**. Finish the git steps, then on the pipeline click **Release change**.  
⁴ **Symptom:** Deploy failed — **sufficient permissions to access ECS**.  
  **Resolution:** The pipeline role must include `ecs:TagResource` (with the other ECS actions). Re-apply, then **Release change**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.7 — Put `buildspec.yml` on GitHub, then apply the pipeline

---

## Lab 8.8 — Push a commit and watch

### Objective

Push an **app** change with **git**. Watch every hop. Pipeline files are already on `main` from Lab 8.7.

### Procedure

Work from the **accelerator-app** root (not `terraform/`). If you are still in `terraform/` from Lab 8.7:

```bash
cd ..
```

In VS Code, change the tagline in `src/App.jsx` to something you have not shipped yet, for example:

```jsx
<p className="tagline">
  Shipped by CodePipeline — AWS Graduate Cloud Skills Accelerator.
</p>
```

`git add src/App.jsx` stages only the app change. It does **not** commit. It does **not** talk to GitHub.

```bash
git add src/App.jsx
```

`git status` lists what will go in this commit. It does **not** change files. You should see `src/App.jsx`. If you see `terraform.tfstate`, `.terraform/`, or `.env`, **stop**. Fix `.gitignore` and do not add those files.

```bash
git status
```

`git commit` writes the snapshot on this laptop. It does **not** upload.

```bash
git commit -m "Ship a tagline via CI/CD"
```

`git push origin main` uploads the commit. Source watches this branch (`DetectChanges = true`).

```bash
git push origin main
```

### See it (root)

Watch the pipeline. If the console is closed, sign in as in Lab 8.2 (account email, **N. Virginia**).

1. Top search: **CodePipeline** → **Pipelines** → **`accelerator-pipeline`**.  
2. Open the **latest** execution (refresh). Wait until **Source** is green.  
   **Why it matters:** Source used the Lab 8.2 connection to fetch the commit you just pushed with git.

3. Wait until **Build** is green. If it fails: click the failed action → **Details** → **CodeBuild → Build history** → open the build → **Logs**.  
   **Why it matters:** this machine ran `docker build` and pushed `accelerator:latest`. You did **not** run those commands on your laptop for this change.

4. Wait until **Deploy** is green.  
   **Why it matters:** CodePipeline handed ECS `imagedefinitions.json`. The container name must be **`accelerator`**. Deploy uses **100 / 0** (Workflow 06): the old task stops first. **Running** may show **0**. The `app_url` page goes **dark** for several minutes. That is expected. Do **not** click **Release change** again while it is dark.

5. **ECR → Repositories → `accelerator`**. Tag **`latest`**. **Pushed at** is recent.  
   **Why it matters:** CodeBuild stocked the registry, not your laptop.

6. **ECS → Clusters → `accelerator-cluster` → Services → `accelerator-service`**. Wait until **Running tasks = 1** again.  
   **Why it matters:** a new task. Same service name. Same ALB.

7. **EC2 → Target Groups → `accelerator-tg` → Targets**. The new IP **healthy**. Wait. Do not open the browser while the list is empty.  
   **Why it matters:** the ALB forwards to the new task before Lab 8.9 can show the tagline.

### Verification

- Pipeline all green. Fresh `latest`. New ECS deployment. Target healthy.  
- **Expected State:** The pipeline built, pushed, and deployed.

### Troubleshooting References

¹ **Symptom:** Source failed.  
  **Resolution:** Connection **Available**? `FullRepositoryId` is `owner/repo`? Branch is `main`? Lab 8.2 was a required console click.  
² **Symptom:** Build failed — Docker / privileged.  
  **Resolution:** `privileged_mode = true`. Re-apply. Read CodeBuild **Logs**.  
³ **Symptom:** Build failed — ECR denied.  
  **Resolution:** CodeBuild role policy from Lab 8.5; repo name `accelerator`.  
⁴ **Symptom:** Deploy failed — imagedefinitions.  
  **Resolution:** JSON `name` is `accelerator`. `imageUri` must be the full ECR URL. Use `$ECR_REGISTRY/$ECR_REPOSITORY:latest` (do not set `IMAGE_URI` in `pre_build`). File produced in `post_build`.  
⁵ **Symptom:** Pipeline never starts.  
  **Resolution:** Did `git push origin main` land on `main`? Click **Release change** on the pipeline.  
⁶ **Symptom:** Build failed — no `buildspec.yml`.  
  **Resolution:** Lab 8.7 push did not land. Confirm the file on github.com, then **Release change**.  
⁷ **Symptom:** URL dark / **Running = 0** after Deploy is green.  
  **Resolution:** Expected with **100 / 0**. Wait for one **RUNNING** task and one **healthy** target (often 3–8 min). Then Lab 8.9.  
⁸ **Symptom:** New task stuck **PROVISIONING**.  
  **Resolution:** Service is still **200 / 100**. Paste Workflow 06 Lab 6.4 **Your file must look like this**, `terraform apply`, then **Release change** once.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.8 — Push a commit and watch

---

## Lab 8.9 — Open the URL again

Stay in `terraform/` (Lab 8.7). `terraform output app_url` prints the same ALB URL as Lab 8.1. It does **not** change AWS. Copy the whole line. It must start with `http://`.

```bash
terraform output app_url
```

Paste the URL into a **new** browser tab (not the AWS console tab). If the browser upgrades to `https://`, change it back to **`http://`**. Hard refresh (`Ctrl + F5`).

### See it (browser)

The hostname is still the **same load balancer**. You did not apply a new ALB.

- The tagline is the one you committed in Lab 8.8 — not a `docker push` from your laptop.  
- A padlock / certificate error means the browser forced **https**. Use **`http://`** exactly.  
  **Why it matters:** **git** is how you ship. The task stayed private. Reception answered.

### Verification

- New tagline visible.  
- **Expected State:** git is how you ship.

### Troubleshooting References

¹ **Symptom:** Old page.  
  **Resolution:** Deploy not green yet; cache; wait for healthy target.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.9 — Open the URL again

---

## Lab 8.10 — See the hops (root checklist)

### Objective

Walk every hop so you can narrate the interview line without Terraform.

### Procedure

If the console is still open from Lab 8.8, skip to step 4. If not:

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → account **email** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

**The handshake**

4. **CodePipeline → Settings → Connections → `accelerator-github`**. Status **Available**.  
   **Why it matters:** no Available connection = Source never starts. Lab 8.2 was the required click.

**The pipeline**

5. **CodePipeline → Pipelines → `accelerator-pipeline`**. Latest execution **Succeeded**.  
   **Why it matters:** one pipeline: Source → Build → Deploy.

6. **CodeBuild → Build history**. Latest **Succeeded**. Open **Logs** if you need to prove Docker ran here.  
   **Why it matters:** this machine replaced `docker build` on your laptop.

**Registry, cluster, reception**

7. **ECR → Repositories → `accelerator`**. Tag **`latest`** is fresh.  
   **Why it matters:** CodeBuild pushed this. ECS pulled it.

8. **ECS → Clusters → `accelerator-cluster` → Services → `accelerator-service`**. New deployment. **Running = 1**.  
   **Why it matters:** the **service** kept one running task. The **task** is the new copy.

9. **EC2 → Load Balancers → `accelerator-alb`**. **Active**. Two **public** subnets.  
   **Why it matters:** same door as Lab 8.1. Two Availability Zones (two districts) because an Application Load Balancer needs **high availability**.

10. **EC2 → Target Groups → `accelerator-tg`**. Target type **IP**. Target **healthy**.  
    **Why it matters:** the ALB talks to the task ENI, not the EC2 instance.

11. **EC2 → Instances → `accelerator-ecs-instance`**. Still **no** public IPv4.  
    **Why it matters:** a push from GitHub did not put the host on a public subnet.

| Hop | Path | Good |
|-----|------|------|
| Connection | **CodePipeline → Settings → Connections → `accelerator-github`** | **Available** |
| Pipeline | **CodePipeline → Pipelines → `accelerator-pipeline`** | Latest execution **Succeeded** |
| Build | **CodeBuild → Build history** | Latest **Succeeded** — use **Logs** if not |
| Image | **ECR → Repositories → `accelerator`** | `latest` fresh |
| Service | **ECS → Clusters → `accelerator-cluster` → Services → `accelerator-service`** | New deployment; Running = 1 |
| Door | **EC2 → Load Balancers → `accelerator-alb`** | Active |
| Targets | **EC2 → Target Groups → `accelerator-tg`** | Healthy |

### Verification

- You walked that table as the account email.  
- **Expected State:** Story complete.

### Troubleshooting References

¹ **Symptom:** Wrong region.  
  **Resolution:** **N. Virginia** on every page.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.10 — See the hops (root checklist)

---

## Lab 8.11 — Teardown

### Objective

Stop ALB, NAT, EC2, pipeline, and the artefact bucket.

Keep the `.tf` files and the GitHub repo. **Always** run this lab.

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform destroy` tears down the pipeline, ALB, cluster, registry, and NAT. It will ask you to type `yes`. Until you type `yes`, nothing is deleted. The GitHub repo **stays**. IAM user **stays**. Files in `terraform/` stay.

If destroy sits on **DRAINING** for more than about 10 minutes, and the instance is **InService** (not Terminating:Wait), do **not** wait for a timeout. Same unstick as Workflow 05 Lab 5.9 Troubleshooting ² (force-delete the service). If the instance is **Terminating:Wait**, use Troubleshooting ¹.

```bash
terraform destroy
```

Type `yes` and press **Enter**. Wait until **Destroy complete!** ALB, NAT, instance, and pipeline hours stop only after that line.

### See it (root)

Same sign-in as Lab 8.10 if the console is closed: [https://console.aws.amazon.com](https://console.aws.amazon.com) → **Root user** → account email → **N. Virginia**.

1. **CodePipeline → Pipelines** — `accelerator-pipeline` **gone**.  
2. **CodeBuild → Build projects** — `accelerator-build` **gone**.  
3. Top search: **S3** → **Buckets**. **`accelerator-pipeline-artifacts-`** plus your account id is **gone**.  
   **Why it matters:** that bucket held pipeline zip files. `force_destroy` lets Terraform delete it. If a name remains, re-run destroy.  
4. **EC2 → Load Balancers** — `accelerator-alb` **gone**.  
5. **EC2 → Instances** — `accelerator-ecs-instance` **terminated** (or gone).  
6. **VPC → NAT gateways** — NAT **gone**.  
7. **ECR → Repositories** — `accelerator` **gone**.  
   **Why it matters:** pipeline, reception, cluster, registry, and NAT were hourly. The GitHub repo **stays**. IAM user **stays**. `.tf` files **stay**.

8. **Optional:** **CodePipeline → Settings → Connections** — you may **delete** `accelerator-github` or keep it for later practice. It is not in Terraform state if you created it only in the console.

### Verification

- Paid hours stopped. GitHub repo **stays**. IAM user **stays**. `.tf` files **stay**.  
- **Expected State:** Accelerator cloud hygiene done.

### Troubleshooting References

¹ **Symptom:** S3 bucket not empty.  
  **Resolution:** `force_destroy = true` is set; re-run destroy.  
² **Symptom:** Pipeline leftover.  
  **Resolution:** Re-run destroy; delete the pipeline in the console only if state is gone.  
³ **Symptom:** Destroy sits on service **DRAINING**, instance **InService**, no hook (or times out at 20 min).  
  **Resolution:** Workflow 05 Lab 5.9 Troubleshooting ² (`delete-service --force`). Then `terraform destroy` again.  
⁴ **Symptom:** Instance **Terminating:Wait**.  
  **Resolution:** Workflow 05 Lab 5.9 Troubleshooting ¹. Then `terraform destroy` again.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 8.11 — Teardown

---

### Workflow Completion Criteria

Do not continue until all checks pass:

- [ ] GitHub repo published with git (no `tfstate`)  
- [ ] Stack was up; image could serve `app_url`  
- [ ] Connection **Available** (Lab 8.2 console click); ARN in `terraform.tfvars`  
- [ ] `buildspec.yml` on GitHub `main` **before** the pipeline apply (Lab 8.7)  
- [ ] `modules/cicd` applied  
- [ ] A **`git push`** produced a green Source → Build → Deploy  
- [ ] Browser showed the new tagline on **`http://`**  
- [ ] Destroy completed  

### What We Have Accomplished

You automated the walk you used to do by hand. A commit is enough.

### Where We Are Now

**Artefact state:** Full Terraform files in GitHub. AWS empty. You can say the interview line from the Accelerator Intro.

### Where We Are Going Next

There is no Workflow 09. If something broke, the tables in each workflow **are** the troubleshooting chapter.

Rebuild any time: apply → (first image if needed) → **`git push origin main`**.

### Restart next time

1. Lab 8.2 connection still **Available** (or recreate it)  
2. `terraform apply` (all six modules)  
3. If ECS has no image yet, one manual push **or** **Release change** on the pipeline after `buildspec.yml` is on `main`  
4. Destroy when you leave  

### Destroy

Lab 8.11. Do not leave NAT + ALB + EC2 + a pipeline that can start builds.

### Common Errors & Resolutions (Workflow 08)

| # | Error / symptom | Likely cause | Resolution |
|---|-----------------|--------------|------------|
| 1 | Connection **Pending** | GitHub App not finished (skipped Lab 8.2 click) | Lab 8.2 in the console; do not debug the pipeline first |
| 13 | Source: **No Branch [main] found** | Authorised GitHub but skipped **Install a new app** | Lab 8.2: install the App, grant the repo, then **Release change** |
| 2 | Source failed | Wrong repo/branch/ARN | `owner/repo`; branch `main`; Available ARN |
| 3 | Build: cannot connect Docker | Privileged off | `privileged_mode = true`; re-apply |
| 4 | Build: ECR login/push denied | Role too thin or wrong repo | Lab 8.5 policy; **Logs** tab |
| 5 | Deploy: imagedefinitions | Wrong container `name` or empty image URI | Must be `accelerator`. URI is `$ECR_REGISTRY/$ECR_REPOSITORY:latest` |
| 14 | Deploy: permissions to access ECS | Pipeline role missing `ecs:TagResource` | Add it in Lab 8.5, re-apply, **Release change** |
| 6 | Build: no `buildspec.yml` | Applied pipeline before Lab 8.7 **`git push`** | Push the recipe (Lab 8.7), then **Release change** |
| 7 | Pipeline idle | Push not on watched branch | **`git push origin main`**, or **Release change** |
| 8 | Page unchanged | Deploy not done / cache | Wait for green Deploy; `Ctrl+F5` |
| 9 | https error | Browser upgrade | `http://` `app_url` |
| 10 | `terraform.tfvars` missing | Variables unset | Lab 8.3 |
| 11 | Left stack up | Skipped destroy | Lab 8.11 now |
| 12 | `git push`: **Repository not found** | Terminal signed in as the wrong GitHub user | Lab 8.1: `gh auth login` as **YOUR_USER**, then push |
| 15 | Invalid count argument on `alb_http_in` | Old `count` in the service module | Workflow 06 Lab 6.4 file. One full apply. No `-target` |
| 16 | InvalidSubnet: no internet gateway | `"-target=module.alb"` from empty AWS | Full `terraform apply`. Targeting ALB skips the IGW |
| 17 | URL dark after pipeline Deploy | **100 / 0** stops the old task first | Wait for a healthy target (3–8 min), then `Ctrl+F5` |
| 18 | Destroy sits on service **DRAINING**, instance **InService** | Terraform waiter for **INACTIVE** (~20 min) | Workflow 05 Lab 5.9 Troubleshooting ² (`delete-service --force`) |
| 19 | Destroy timeout on Terminating:Wait | ECS drain hook still on | Workflow 05 Lab 5.9 Troubleshooting ¹ |

### Workflow Summary

Workflow 08 solved “I am still deploying manually.”

You finished the **AWS Graduate Cloud Skills Accelerator**:

1. Access, Terraform root  
2. A real VPC  
3. Docker  
4. ECR  
5. ECS on EC2 (cluster, host, task, service)  
6. ALB + SG pair  
7. A manual launch  
8. git + a pipeline on that repo  

Stop “learning AWS services.” You have run how they work together. Destroy when you leave. The Terraform files are what you keep.

# Accelerator complete
