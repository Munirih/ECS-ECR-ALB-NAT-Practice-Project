# Workflow 07 — Manual Production Deployment
## One full launch. No new modules. Prove the URL.

**Programme:** AWS Graduate Cloud Skills Accelerator  
**Region:** `us-east-1` only  
**Prefix:** `accelerator`  
**Project:** the `accelerator-app` folder  

---

# Workflow Overview

Workflows 01–06 wrote every module. Workflow 06 added the ALB and then you destroyed. This chapter **adds no Terraform folder**. You apply the same files, push the image, and run a full launch on purpose: healthy targets, `http://` URL, optional manual deployment.

Then you teardown again. Workflow 08 is the **release train** so you stop building and pushing by hand.

---

### The 5 Codewrkx Engineer Questions

**What is the problem?**  
The Terraform files exist, but you have not run a full launch from empty AWS. You are still the person who applies, builds, and pushes. That is slow, and easy to skip a step.

A **region** is a geographic AWS location — a cluster of **data centres**. Light picture: the **city**. Stay in **N. Virginia (`us-east-1`)**. Wrong region = empty console after a successful apply. The **VPC** is still one **house** across two AZs (two **districts**). Reception sits in the **front rooms**; the task stays in a **back room**.

**Why solve it with these services?**  
No new AWS product. The problem is proving the whole path works together — like a go-live — then tearing it down. Same **VPC (Virtual Private Cloud)**, **ECR (Elastic Container Registry)**, **ECS (Elastic Container Service)**, and **ALB (Application Load Balancer)** you already wrote.

**When are these services used?**  
Every cold start: a new sitting, a rebuild from code, “can we recover?” Not a new module. Not every save.

**How does this work?**  
No new folder. You run the Terraform files you already have:

| Command | Today |
|---------|--------|
| `terraform init` | Plugins + existing modules. |
| `terraform validate` | Grammar check. |
| `terraform plan` | Preview **all five** modules. Confirm **no** CodePipeline. |
| `terraform apply` | Build house, registry, cluster, reception. Type `yes`. |
| `docker build` / `push` | Restock `accelerator:latest` (destroy deleted it). |
| `terraform output app_url` | Open **`http://`**. |
| `terraform destroy` | Take it down. Terraform files stay. |

Optional: change the tagline, push again, `aws ecs update-service --force-new-deployment`. Walk the console as root (N. Virginia).

**Who typically deploys them?**  
On a bad day the on-call engineer *is* the pipeline. This chapter is that job. Root **looks**. `accelerator-cli` **applies**, **pushes**, and **destroys**. Workflow 08 takes the manual deployment off you.

---

### Where We Came From

You have modules `vpc`, `ecr`, `ecs-cluster`, `ecs-service`, and `alb` on disk. You have seen **Running = 1** and a working ALB. AWS is empty. You destroyed at the end of Workflow 06. The image in AWS is gone. GitHub is Workflow 08.

### Where We Are Now

You will `terraform apply` the **whole** root, **build + push**, walk the console from VPC to ALB as root, and open `app_url`. Optional: change the tagline, rebuild, push, `--force-new-deployment`.

### Where We Are Going

When the URL works, you destroy. The problem left is manual toil. Workflow 08 is where you **publish the GitHub repo with git** and connect a pipeline so a push builds and ships.

### Launch context

The Terraform files are complete. Apply the full stack, push the artefact, wait for a healthy target, open `app_url`. Do not add a module. If you change app text, rebuild, push, and force a new deployment — still by hand. Workflow 08 automates that loop.

### Technical Context

Nothing new is declared. The graph is already:

```text
Laptop
        │
        ▼  you: docker build + push
       ECR  accelerator:latest
        │
        ▼
 VPC → ECS (private) → ALB (public) → browser

No GitHub yet. That is Workflow 08.
```

`--force-new-deployment` does not change the task definition JSON. It starts a new task that **re-pulls** `.../accelerator:latest`. If you did not push, the page will not change.

Use **`http://`**. There is still no certificate.

NAT + ALB + EC2 hours start at apply. Destroy when the launch is proven.

### Why This Workflow Matters

Provisioning without a deliberate prove is unfinished delivery. This is the portfolio launch you can narrate: “I applied the stack, pushed the image, and opened the load balancer URL.”

### What We Will Produce

Evidence of a healthy path and a live URL. No new module.

### Architecture Snapshot

When [`architecture.png`](architecture.png) is in this Accelerator folder, that is the full drawing. If it is not there yet, use the text snapshot below. This lab is the same to-be picture as the Accelerator Intro — and it is live.

```text
You (hands)
  terraform apply
  docker build + push
        │
        ▼
ECR → ECS task → ALB → http://ALB_DNS → browser
```

### SOFTWARE DELIVERY PROGRESS: ✓ 0 Intro → ✓ 01 Access → ✓ 02 VPC → ✓ 03 Docker → ✓ 04 ECR → ✓ 05 ECS → ✓ 06 ALB → ► 07 Prove → □ 08 Pipeline

### Learning Outcomes

- Re-apply the full module stack from an empty account  
- Restock ECR and wait for a healthy target  
- Prove the page in a browser  
- Optionally run a hand-made release loop  

### Key Terminology

| Term | Meaning |
|------|---------|
| Full apply | All root modules; no `-target` |
| Healthy target | ALB health check `GET /` returns 200 |
| Force new deployment | New task; pull `latest` again |
| Manual release | You are the pipeline |

### Labs

Tick as you finish. Change `- [ ]` to `- [x]`.

- [ ] Lab 7.1 — Confirm the project
- [ ] Lab 7.2 — Apply the full stack
- [ ] Lab 7.3 — Push the image to ECR again
- [ ] Lab 7.4 — Walk the path as root
- [ ] Lab 7.5 — Open the URL in a browser
- [ ] Lab 7.6 — Optional manual deployment
- [ ] Lab 7.7 — Save only if you changed the app
- [ ] Lab 7.8 — Teardown

---

## Lab 7.1 — Confirm the project

### Objective

Same IAM user, Docker up, console on N. Virginia, Terraform files present.

### Procedure

Open a terminal in the **accelerator-app** folder.

In Explorer, confirm these folders exist under `terraform/modules/`: `vpc`, `ecr`, `ecs-cluster`, `ecs-service`, `alb`. This lab does **not** create a sixth folder.

`aws sts get-caller-identity` asks AWS: “who am I?” It does **not** create anything. The `Arn` must contain `user/accelerator-cli`. If it contains `root`, stop. Workflow 01 Labs 1.2–1.3.

```bash
aws sts get-caller-identity
```

Docker Desktop must be **running**. You will build and push in Lab 7.3.

### See it (root)

Confirm the window you will use after apply. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → **email that owns the account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.  
   **Why it matters:** Lab 7.2 looks here. Wrong city = empty VPC list after apply.

### Verification

- Five modules on disk. CLI is not root. Console is N. Virginia as the account email.  
- Open `terraform/modules/ecs-service/main.tf`. You must see `deployment_maximum_percent = 100`, `force_delete = true`, and **no** `count =` on `alb_http_in`. If any of those is wrong, paste Workflow 06 Lab 6.4 **Your file must look like this**, then come back.  
- **Expected State:** Ready for a full launch.

### Troubleshooting References

¹ **Symptom:** A module folder is missing.  
  **Resolution:** Finish the workflow that creates it. Do not skip ahead.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 7.1 — Confirm the project

---

## Lab 7.2 — Apply the full stack

### Objective

Apply **all** modules. No new files.

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform init` does **not** launch anything. It re-reads the five modules you already wrote. You should see **Terraform has been successfully initialized**.

```bash
terraform init
```

`terraform validate` is a grammar check. It still does **not** touch AWS. You should see **Success! The configuration is valid**.

```bash
terraform validate
```

`terraform plan` is the preview. It does **not** create anything yet. **One** plan of **all five** modules. **No** `-target`.

Read the plan. You should see VPC, **one** NAT, ECR, cluster, service, and ALB. You should **not** see CodePipeline. If you see a sixth module, or two NATs, stop. Do not apply.

Do **not** run `terraform apply "-target=module.alb"`. Terraform may hint `-target` if your service still has `count` on `alb_http_in`. Targeting the ALB from empty AWS creates public subnets **without** the Internet Gateway, then fails: **InvalidSubnet: VPC has no internet gateway**. Fix the file (Lab 7.1), then one full apply.

```bash
terraform plan
```

`terraform apply` is a **full** apply of all five modules. **NAT and ALB hours start.** It will ask you to type `yes`. Until you type `yes`, nothing is created. **No** `-target`.

```bash
terraform apply
```

Type `yes` and press **Enter**. Wait until **Apply complete!**

### See it (root)

The whole house is back — VPC, cluster, and reception. The registry is still empty. **Root** = account email. **`accelerator-cli`** stays in the terminal.

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
   (or [https://aws.amazon.com](https://aws.amazon.com) → **Sign in to the Console**).  
2. **Root user** → **email that owns the account** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

4. Top search: **VPC** → **Your VPCs** → **`accelerator-vpc`**.  
   **Why it matters:** one house. Cluster and reception both sit here.

5. Left: **NAT gateways** → **`accelerator-nat`**. State **Available**. **One** row.  
   **Why it matters:** the host has no public IP. Pulls go through this service exit (NAT). The clock is running.

6. Top search: **ECR** → **Repositories** → **`accelerator`**. Empty (no `latest` yet).  
   **Why it matters:** Workflow 06 destroy deleted the image. **Running = 0** / `CannotPullContainerError` until Lab 7.3 is expected.

7. Top search: **EC2** → **Load Balancers** → **`accelerator-alb`**. State should become **Active**.  
   **Why it matters:** this lab applies **all five** modules. Unlike Lab 6.2, reception exists now — it just has nobody healthy to serve until you push.

8. **EC2 → Target Groups → `accelerator-tg` → Targets**. Empty or **unhealthy** is expected.  
   **Why it matters:** no image yet. Do not open `app_url` until Lab 7.5.

Lab 7.4 is the full path after the push. Do not skip it.

### Verification

- Apply finished.  
- You signed in as the **account email** and saw the VPC, one NAT, empty ECR, and an ALB.  
- **Expected State:** Stack exists. ECR is empty until Lab 7.3. **Running = 0** / `CannotPullContainerError` until that push is expected. NAT and ALB hours have started.

### Troubleshooting References

¹ **Symptom:** Plan wants to create only some modules.  
  **Resolution:** `main.tf` must call all five. See Workflows 02–06.  
² **Symptom:** Name conflicts (roles, ALB).  
  **Resolution:** Leftovers from a half-destroy. Destroy or delete orphans; re-apply.  
³ **Symptom:** **Invalid count argument** on `alb_http_in`.  
  **Resolution:** Lab 7.1 check. Paste Workflow 06 Lab 6.4 **Your file must look like this** (no `count`). Then one full `terraform apply`. Do **not** `-target`.  
⁴ **Symptom:** **InvalidSubnet: VPC has no internet gateway**.  
  **Resolution:** You targeted `module.alb`. Stop. Confirm Lab 7.1 file check. `terraform apply` with **no** `-target` (creates IGW with the VPC).

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 7.2 — Apply the full stack

---

## Lab 7.3 — Push the image to ECR again

### Objective

Push `accelerator:latest`. Destroy always deletes the image.

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

### See it (root)

If the console is closed, sign in again (Lab 7.2 steps 1–3). Region **N. Virginia**.

1. Top search: **ECR** → **Repositories** → **`accelerator`**. Tag **`latest`** is listed. **Pushed at** is recent.  
   **Why it matters:** the task can pull now. Empty registry was the fail in Lab 7.2.

2. You do **not** need a healthy target yet. Wait starts in Lab 7.4.  
   **Why it matters:** ECS retries the pull. Give it a few minutes before you call it broken.

### Verification

**ECR → Repositories → `accelerator`** → tag **`latest`**.  
- **Expected State:** The cluster can pull.

### Troubleshooting References

¹ **Symptom:** `name unknown`.  
  **Resolution:** Lab 7.2 must have created the repo.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 7.3 — Push the image to ECR again

---

## Lab 7.4 — Walk the path as root

### Objective

See every hop before you open the browser: house, NAT, cluster, reception, locks.

### Procedure

Wait 3–5 minutes after the push if the task was already starting. If the console is still open from Lab 7.3, skip to step 4. If not:

1. Browser: [https://console.aws.amazon.com](https://console.aws.amazon.com)  
2. **Root user** → account **email** (not `accelerator-cli`) → password → MFA if asked.  
3. Top-right region → **N. Virginia (`us-east-1`)**.

**House and service exit**

4. Top search: **VPC** → **Your VPCs** → **`accelerator-vpc`**. CIDR **`10.0.0.0/16`**.  
   **Why it matters:** one house. Everything live in this sitting sits here — not in AWS’s default network.

5. Left: **NAT gateways** → **`accelerator-nat`**. State **Available**. **One** row.  
   **Why it matters:** private rooms fetch `latest` through this service exit. Two public subnets for the ALB does **not** mean two NATs.

**Cluster**

6. Top search: **ECS** → **Clusters** → **`accelerator-cluster`**.  
   **Why it matters:** this is the named group. ECS uses this name.

7. Tab **Infrastructure**. **1** container instance **Active**.  
   **Why it matters:** that is your `t3.micro`. No Active instance = nowhere to run the task.

8. Tab **Services** → **`accelerator-service`**. **Running tasks = 1**.  
   **Why it matters:** the **service** is the standing order (keep one task). The **task** is the running copy.

9. **EC2 → Instances → `accelerator-ecs-instance`**. **running**. **Public IPv4** blank. Subnet **private**.  
   **Why it matters:** visitors never get the private address.

**Reception**

10. **EC2 → Load Balancers → `accelerator-alb`**. State **Active**. Scheme **internet-facing**.  
    **Why it matters:** visitors hit this DNS name. Lab 7.5 opens it with **`http://`**.

11. Tab **Network mapping** (or **Availability Zones**). Two **public** subnets: **`accelerator-public-a`** and **`accelerator-public-b`**.  
    **Why these subnets:** front rooms. An Application Load Balancer must span **two Availability Zones** (two districts). That is why Workflow 02 drew two public subnets. The task stays on the private subnets (back rooms).

12. **EC2 → Target Groups → `accelerator-tg`**. Target type **IP**. Tab **Targets**: one IP, port **80**, **healthy** (refresh; wait).  
    **Why it matters:** the ALB talks to the **task** ENI, not the EC2 instance ID. Healthy = `GET /` succeeded. Unhealthy = Lab 7.5 will time out.

**Locks**

13. **EC2 → Security Groups → `accelerator-alb-sg`**. Inbound **80** from `0.0.0.0/0`.  
    **Why it matters:** the internet may knock on reception. Nowhere else.

14. **EC2 → Security Groups → `accelerator-svc-sg`**. Inbound **80** from **`accelerator-alb-sg`** (a security group, **not** `0.0.0.0/0`).  
    **Why it matters:** the task accepts HTTP only from the ALB.

15. **EC2 → Security Groups → `accelerator-ecs-instance-sg`**. No public HTTP.  
    **Why it matters:** this lock is on the **host**. Opening 80 here would skip reception.

### Verification

- VPC, one NAT, 1 Active instance, Running = 1, ALB Active on two public subnets, target **healthy**, SG pair as above.  
- You can say the path: internet → IGW → ALB → task. The task stayed private.  
- **Expected State:** You can narrate the path.

### Troubleshooting References

¹ **Symptom:** Running = 0 or target unhealthy.  
  **Resolution:** Workflow 05–06 tables. Confirm Lab 7.3 finished before you wait forever.  
² **Symptom:** 0 container instances.  
  **Resolution:** Workflow 05 Lab 5.8.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 7.4 — Walk the path as root

---

## Lab 7.5 — Open the URL in a browser

### Objective

Open `app_url` over HTTP.

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform output app_url` prints the visitor address. It does **not** change AWS. Copy the whole line. It must start with `http://`.

```bash
terraform output app_url
```

Paste the URL into a **new** browser tab (not the AWS console tab). If the browser upgrades to `https://`, change it back to **`http://`**. Press Enter.

### See it (browser)

The hostname is the **load balancer**, not the EC2 instance.

- You did **not** paste an instance public IP (there isn’t one).  
- A padlock / certificate error means the browser forced **https**. This Accelerator has no certificate. Use **`http://`** exactly.  
  **Why it matters:** this is the launch proof. You applied, you pushed, reception answered. The task stayed private.

### Verification

- Landing page loads (**#AWS ACCELERATOR**).  
- **Expected State:** Manual launch proven.

### Troubleshooting References

¹ **Symptom:** https / certificate warning.  
  **Resolution:** `http://` only.  
² **Symptom:** Timeout.  
  **Resolution:** Target not healthy (Lab 7.4). Wait; retry.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 7.5 — Open the URL in a browser

---

## Lab 7.6 — Optional manual deployment

### Objective

If time allows: change copy, push a new `latest`, force ECS to re-pull. **No** new Terraform.

### Command Context

`aws ecs update-service --force-new-deployment` starts a new task against the **same** task definition and image URI (`:latest`).

### Professional Practice

This is a junior-shaped loop. Production pins an immutable tag. You are learning: **new artefact → registry → orchestrator**.

### Procedure

This lab is **optional**. Completion does not require it. If you skip, tick 7.6 anyway and go to 7.7.

Open `src/App.jsx`. Find the tagline. It currently says **Building the Next Generation of Cloud Engineers.** Change only that sentence. Do **not** change Terraform.

```jsx
<p className="tagline">
  AWS Graduate Cloud Skills Accelerator — manual launch.
</p>
```

Save.

Docker Desktop must be **running**. Work from the **accelerator-app** root (not `terraform/`). If you are still in `terraform/`:

```bash
cd ..
```

This prints your 12-digit AWS account id only. Copy it. Paste it in place of `ACCOUNT_ID` below.

```bash
aws sts get-caller-identity --query Account --output text
```

`docker build` packs the **new** tagline. It does **not** upload yet. Image name stays `accelerator:latest`.

```bash
docker build -t accelerator:latest .
```

`docker login` uses a short-lived ECR password. Replace `ACCOUNT_ID`. You should see **Login Succeeded**.

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

`docker tag` points the new image at the registry. It does **not** upload yet. Replace `ACCOUNT_ID`.

```bash
docker tag accelerator:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

`docker push` puts the new `latest` in the registry. Replace `ACCOUNT_ID`. If you skip this, the page will not change.

```bash
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/accelerator:latest
```

`aws ecs update-service --force-new-deployment` starts a **new task** against the **same** task definition. It does **not** change Terraform. It tells ECS: pull `accelerator:latest` again. Cluster name is `accelerator-cluster`. Service name is `accelerator-service`. Region is `us-east-1`.

Workflow 06 set deploy to **100 / 0** (one `t3.micro` cannot run two `awsvpc` tasks). That **stops the old task first**. **Running = 0** for several minutes. The `app_url` page goes **dark**. The ALB also waits as long as **300 seconds** (`deregistration_delay`) before it drops the old target. That is expected. Do **not** run a second force-deploy. Do **not** change Terraform to 200/100 — that stalls the new task in **PROVISIONING**.

```bash
aws ecs update-service --cluster accelerator-cluster --service accelerator-service --force-new-deployment --region us-east-1
```

You should see JSON that includes the service name. Wait in Lab 7.6 See it (root) until the **new** target is **healthy** — often **3–8 minutes**. Then hard-refresh.

### See it (root)

If the console is closed, sign in as in Lab 7.4 (account email, **N. Virginia**).

1. **ECS → Clusters → `accelerator-cluster` → Services → `accelerator-service`**.  
   **Running tasks** may show **0**. Then a **new** task becomes **RUNNING**.  
   **Why it matters:** **100 / 0** stops the old task before the new one starts. Dark URL is expected.

2. **EC2 → Target Groups → `accelerator-tg` → Targets**. Old IP **draining** / gone. **New** IP **healthy**. Wait. Do not open the browser while the list is empty.  
   **Why it matters:** the ALB only serves a healthy target. `--force-new-deployment` does not change Terraform. It re-pulls `accelerator:latest`. No push = same page (once it is back).

3. Hard-refresh the `app_url` tab (`Ctrl + F5`) **after** the new target is healthy.  
   **Why it matters:** the browser may still show the old tagline from cache. If you refresh while Running = 0, the page fails — wait, then try again.

### Verification

- New tagline visible.  
- **Expected State:** Release without changing the Terraform modules.

### Troubleshooting References

¹ **Symptom:** Page unchanged.  
  **Resolution:** Push finished? New target **healthy**? Hard refresh.  
² **Symptom:** Skipped this lab.  
  **Resolution:** Fine. Completion does not require it.  
³ **Symptom:** URL dark / **Running = 0** after force-deploy.  
  **Resolution:** Expected with **100 / 0**. Wait for one **RUNNING** task and one **healthy** target (often 3–8 min). Then `Ctrl+F5`.  
⁴ **Symptom:** New task stuck **PROVISIONING**.  
  **Resolution:** Service is still **200 / 100**. Paste Workflow 06 Lab 6.4 **Your file must look like this**, `terraform apply`, then force-deploy once.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 7.6 — Optional manual deployment

---

## Lab 7.7 — Save only if you changed the app

If you did Lab 7.6, keep the tagline change on disk. Do **not** push to GitHub. GitHub is Workflow 08.

If you did not change the app, skip.

### Verification

- **Expected State:** Files on the laptop match what you proved, if you changed copy.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 7.7 — Save only if you changed the app

---

## Lab 7.8 — Teardown

Keep the `.tf` files. **Always** run this lab. Do not leave the stack up for Workflow 08. Workflow 08 will apply again.

You must be in the `terraform/` folder. If the terminal is still in `accelerator-app`, move in. This does **not** talk to AWS.

```bash
cd terraform
```

`terraform destroy` tears down the ALB, cluster, registry, and NAT. It will ask you to type `yes`. Until you type `yes`, nothing is deleted. The five modules stay on disk.

If destroy sits on **DRAINING** for more than about 10 minutes, and the instance is **InService** (not Terminating:Wait), do **not** wait for a timeout. Same unstick as Workflow 05 Lab 5.9 Troubleshooting ² (force-delete the service). If the instance is **Terminating:Wait**, use Troubleshooting ¹.

```bash
terraform destroy
```

Type `yes` and press **Enter**. Wait until **Destroy complete!** ALB, NAT, and instance hours stop only after that line.

### See it (root)

Same sign-in as Lab 7.4 if the console is closed: [https://console.aws.amazon.com](https://console.aws.amazon.com) → **Root user** → account email → **N. Virginia**.

1. **EC2 → Load Balancers** — `accelerator-alb` **gone**.  
2. **EC2 → Target Groups** — `accelerator-tg` **gone**.  
3. **EC2 → Instances** — `accelerator-ecs-instance` **terminated** (or gone).  
4. **ECS → Clusters** — `accelerator-cluster` **gone**.  
5. **VPC → NAT gateways** — NAT **gone**.  
6. **ECR → Repositories** — `accelerator` **gone**.  
   **Why it matters:** reception, cluster, registry, and NAT were hourly. The five modules stay on disk. Workflow 08 applies again.

### Verification

- Hours stopped. Drawings remain.  
- **Expected State:** Teardown complete.

### Troubleshooting References

¹ **Symptom:** Destroy stuck on ALB or ASG.  
  **Resolution:** Re-run `terraform destroy`. Wait. Do not leave NAT or the ALB up.  
² **Symptom:** Destroy sits on service **DRAINING**, instance **InService**, no hook (or times out at 20 min).  
  **Resolution:** Workflow 05 Lab 5.9 Troubleshooting ² (`delete-service --force`). Then `terraform destroy` again.  
³ **Symptom:** Instance **Terminating:Wait**.  
  **Resolution:** Workflow 05 Lab 5.9 Troubleshooting ¹. Then `terraform destroy` again.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 7.8 — Teardown

---

### Workflow Completion Criteria

Do not continue until all checks pass:

- [ ] Full `terraform apply` with **no** new module  
- [ ] Image **pushed** after apply  
- [ ] Console walk: VPC, NAT, cluster instance, Running = 1, ALB, **healthy** target, SG pair  
- [ ] Browser proof on **`http://`** `app_url`  
- [ ] (Optional) Manual deployment completed
- [ ] Destroy completed  

### What We Have Accomplished

You ran a complete manual production path from empty AWS to a working URL — and you tore it down.

### Where We Are Now

**Artefact state:** Same five modules. You are the pipeline. Cloud is off.

### Where We Are Going Next

A new app change still means **you** build, push, and update ECS.

**Workflow 08** is where you **publish the GitHub repo with git**, **approve a GitHub connection in the console** (root — required click; Terraform cannot finish it), add `buildspec.yml` and `modules/cicd`, `git push` a commit, and watch CodePipeline → CodeBuild → ECR → ECS update the live URL.

### Restart next time

You need the stack **up** for the pipeline to deploy somewhere:

1. `terraform apply` (existing five modules)  
2. **Build + push** once so the first task can start  
3. Then add CI/CD on top  

### Destroy

Lab 7.8. **Always.** Do not leave the stack up for Workflow 08. Workflow 08 starts with apply + push.

### Common Errors & Resolutions (Workflow 07)

| # | Error / symptom | Likely cause | Resolution |
|---|-----------------|--------------|------------|
| 1 | Apply missing ALB or service | Incomplete earlier workflows | Open the workflow that adds that module |
| 2 | `CannotPullContainerError` | Forgot Lab 7.3 | Push `latest`; wait |
| 3 | Targets unhealthy | Task or SG | Lab 7.4; Workflow 06 table |
| 4 | https / certificate | Browser upgrade | `http://` from `app_url` |
| 5 | Optional update invisible | No push or cache | Push; force deploy; `Ctrl+F5` |
| 6 | `update-service` wrong names | Typo | `accelerator-cluster` / `accelerator-service` |
| 7 | Added a sixth module | This is prove-only | Revert; W08 is the pipeline |
| 8 | Wrong region | Console | **N. Virginia** |
| 9 | Root Arn on CLI | Wrong keys | Workflow 01 Lab 1.3 |
| 10 | Left the stack running | Skipped destroy | `terraform destroy` now. Workflow 08 will apply again |
| 11 | Invalid count argument on `alb_http_in` | Old `count` in the service module | Lab 7.1 file check. One full apply. No `-target` |
| 12 | InvalidSubnet: no internet gateway | `"-target=module.alb"` from empty AWS | Full `terraform apply`. Targeting ALB skips the IGW |
| 13 | URL dark after `--force-new-deployment` | **100 / 0** stops the old task first | Wait for a healthy target (3–8 min), then `Ctrl+F5` |
| 14 | Destroy sits on service **DRAINING**, instance **InService** | Terraform waiter for **INACTIVE** (~20 min) | Workflow 05 Lab 5.9 Troubleshooting ² (`delete-service --force`) |
| 15 | Destroy timeout on Terminating:Wait | ECS drain hook still on | Workflow 05 Lab 5.9 Troubleshooting ¹ |

### Workflow Summary

Workflow 07 solved “do it once, on purpose.”  
The next problem is “I am still doing the deployment manually.” Workflow 08 automates GitHub → build → ECR → ECS.

Open `workflow 8 - CI-CD.md` when you are ready.
