# Workflow 03 — React → Docker
## Pack the image. Prove it locally. Do not use ECR.

**Programme:** AWS Graduate Cloud Skills Accelerator  
**Region:** `us-east-1` only  
**Prefix:** `accelerator`  
**Project:** the `accelerator-app` folder  
**Image:** `accelerator:latest`  

---

# Workflow Overview

Workflow 02 applied the house and tore it down. The product is still a React app on your laptop. ECS will not run a folder.

This chapter packages accelerator-app into a Docker image and proves it at `http://localhost:8080`.

You do **not** apply the VPC. You do **not** create ECR. That is Workflow 04.

---

### The 5 Codewrkx Engineer Questions

**What is the problem?**  
A React folder is not what ECS (Elastic Container Service) runs. AWS needs a packed **image** — the same bits every time, not “it works on my laptop.”

A **region** is a geographic AWS location — a cluster of **data centres**. Light picture: the **city** (N. Virginia). You do **not** use it today. This sitting stays on your laptop. If you `terraform apply` the VPC from Workflow 02, you start a NAT bill for nothing.

**Why solve it with these services?**  
**Docker** packs the app and a web server (**nginx**) into one **image** named `accelerator:latest`. You prove it at `http://localhost:8080` before any registry or cluster exists in AWS. This is laptop work. It is not a room of the house.

**When are these services used?**  
You build an image when the app must ship. You prove it locally **before** you put it in a registry. You do not rebuild for every console click.

**How does this work?**  
You author a `Dockerfile` and `.dockerignore` in the **accelerator-app** root, then:

| Command | Today |
|---------|--------|
| `docker build -t accelerator:latest .` | Pack the app. |
| `docker run -d -p 8080:80 --name accelerator-container accelerator:latest` | Serve it on your laptop. |
| Browser `http://localhost:8080` | Prove **#AWS ACCELERATOR**. |

No `terraform apply`. No **ECR (Elastic Container Registry)**. That is Workflow 04.

**Who typically deploys them?**  
Application engineers own the Dockerfile. You write it. Building on the laptop does not need AWS keys. Root does not look today — there is nothing in AWS.

---

### Where We Came From

You have keys (`accelerator-cli`) and a `vpc` module on disk. Terraform state is empty. The house (`accelerator-vpc`) is gone. That is correct.

### Where We Are Now

You will author `Dockerfile` and `.dockerignore`, build `accelerator:latest`, and prove nginx on port 8080.

### Where We Are Going

Workflow 04 puts this image in Amazon ECR (the private **registry** in your account — not a room of the VPC).

### Technical Context

A container image is a portable filesystem plus a start command — not a virtual machine.

This Accelerator uses a **multi-stage** Dockerfile: **Node** compiles the Vite app to `dist/`, then **nginx** serves those static files on port **80**. The final image does not include Node.

### What We Will Build

`Dockerfile`, `.dockerignore`, local image `accelerator:latest`. No AWS apply.

### Architecture Snapshot

When [`architecture.png`](architecture.png) is in this Accelerator folder, that is the full drawing. If it is not there yet, use the text snapshot below.

```text
accelerator-app (React)
        │
        ▼
   docker build  →  accelerator:latest
        │
        └─► localhost:8080  (local proof)

No VPC. No ECR. No ECS.  That is correct.
```

### SOFTWARE DELIVERY PROGRESS: ✓ 0 Intro → ✓ 01 Access → ✓ 02 VPC → ► 03 Docker → □ 04 ECR → □ 05 ECS → □ 06 ALB → □ 07 Prove → □ 08 Pipeline

### Learning Outcomes

- Author a multi-stage Dockerfile for the Vite app  
- Prove the page on port 8080 before AWS  

### Labs

Tick as you finish. Change `- [ ]` to `- [x]`.

- [ ] Lab 3.1 — Confirm Docker Engine
- [ ] Lab 3.2 — Create `Dockerfile`
- [ ] Lab 3.3 — Create `.dockerignore`
- [ ] Lab 3.4 — Build `accelerator:latest`
- [ ] Lab 3.5 — Prove the image at localhost
- [ ] Lab 3.6 — Remove the test container

---

## Lab 3.1 — Confirm Docker Engine

### Procedure

1. Open **Docker Desktop**.  
2. Wait until the engine status shows **running**.  
3. Open a **new** terminal in VS Code (the engine must be up before this command works).

`docker version` asks the engine: “are you there?” It does **not** build an image. You should see a **Client** section and a **Server** section. If Server is missing, Desktop is not running yet.

```bash
docker version
```

### Verification

- Docker Desktop reports the engine running.  
- `docker version` shows a **Server** section.  
- **Expected State:** Ready to build an image. No AWS.

### Troubleshooting References

¹ **Symptom:** Cannot connect to the Docker daemon.  
  **Resolution:** Start Docker Desktop; wait; open a **new** terminal.  
² **Symptom:** `docker: command not found` / Docker is not installed.  
  **Resolution:** Open `What to install.md`. Do not invent a Dockerfile until Docker Desktop works.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 3.1 — Confirm Docker Engine

---

## Lab 3.2 — Create `Dockerfile`

### Objective

Build the Dockerfile in order: pack the app (Node), then serve it (nginx). This file lives in the **accelerator-app** root, not inside `terraform/`. Do **not** run `docker build` in this lab — that is Lab 3.4.

### Why this lab exists

Vite’s production output is static files. The second stage is a small web server (nginx) on port 80. The Node compiler is **not** in the final image.

You add **one slice at a time** (paste each slice at the **bottom**, then save). If a slice goes wrong, skip to **Your file must look like this** and replace the whole `Dockerfile`.

### Procedure — create the file

1. Right-click the **accelerator-app** project root.  
2. **New File** → name it exactly `Dockerfile` (no `.txt`).  
3. Leave it empty. You will add two slices below, in order.

### Slice 1 — pack the app (Node builder)

**Why this is next:** compile first. The final image should not include Node — only the static files. `FROM` pulls the Node image from **ECR Public** (AWS), so this laptop and later CodeBuild do not pull from Docker Hub.

Paste into `Dockerfile`:

```dockerfile
# 1. Builder. Node compiles the Vite app to static files.
# This stage is not what visitors run.

FROM public.ecr.aws/docker/library/node:22-alpine AS builder
# ECR Public (AWS). Small Linux + Node 22. Matches What to install.

WORKDIR /app
# Folder inside this stage. COPY paths below are relative to here.

COPY package*.json ./
# Dependencies first so Docker can reuse this layer when only app code changes.

RUN npm install
# Installs packages from package.json. Still this stage — not AWS.

COPY . .
# Rest of the app. .dockerignore keeps terraform/ and node_modules out.

RUN npm run build
# Vite writes static files to dist/. That is what nginx will serve.
```

Save.

### Slice 2 — serve the files (nginx)

**Why this is next:** visitors need a web server, not a compiler. `COPY --from=builder` takes only `dist/`, not Node.

Paste **at the bottom** of `Dockerfile`:

```dockerfile
# 2. Runtime. nginx serves dist/ on port 80.
# ECS later pulls this image — not the Node compiler.

FROM public.ecr.aws/docker/library/nginx:alpine
# ECR Public (AWS). New stage. Everything from stage 1 is discarded except what we COPY.

COPY --from=builder /app/dist /usr/share/nginx/html
# Only the built files. Not Node. Not source.

EXPOSE 80
# Documents that nginx listens on 80. Does not publish a port by itself.

CMD ["nginx", "-g", "daemon off;"]
# Start nginx in the foreground so the container stays running.
```

Save. **Do not** `docker build` yet. That is Lab 3.4.

### Your file must look like this — `Dockerfile`

Open `Dockerfile` in the accelerator-app root. It must match this block (both stages, same order). If it does not, **select all**, delete, paste this whole block, save.

```dockerfile
# 1. Builder. Node compiles the Vite app to static files.
# This stage is not what visitors run.

FROM public.ecr.aws/docker/library/node:22-alpine AS builder
# ECR Public (AWS). Small Linux + Node 22. Matches What to install.

WORKDIR /app
# Folder inside this stage. COPY paths below are relative to here.

COPY package*.json ./
# Dependencies first so Docker can reuse this layer when only app code changes.

RUN npm install
# Installs packages from package.json. Still this stage — not AWS.

COPY . .
# Rest of the app. .dockerignore keeps terraform/ and node_modules out.

RUN npm run build
# Vite writes static files to dist/. That is what nginx will serve.

# 2. Runtime. nginx serves dist/ on port 80.
# ECS later pulls this image — not the Node compiler.

FROM public.ecr.aws/docker/library/nginx:alpine
# ECR Public (AWS). New stage. Everything from stage 1 is discarded except what we COPY.

COPY --from=builder /app/dist /usr/share/nginx/html
# Only the built files. Not Node. Not source.

EXPOSE 80
# Documents that nginx listens on 80. Does not publish a port by itself.

CMD ["nginx", "-g", "daemon off;"]
# Start nginx in the foreground so the container stays running.
```

### Verification

- Project root contains `Dockerfile` (no `.txt`).  
- The file has two `FROM` lines: `builder` then `nginx`.  
- **Expected State:** Dockerfile on disk. No image built yet.

### Troubleshooting References

¹ **Symptom:** File named `Dockerfile.txt`.  
  **Resolution:** Rename to `Dockerfile` with no extension.  
² **Symptom:** Duplicate stages / paste landed twice.  
  **Resolution:** Replace with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 3.2 — Create `Dockerfile`

---

## Lab 3.3 — Create `.dockerignore`

### Objective

Keep the image small. Do not pack `terraform/`, `node_modules`, or `dist/` from the laptop — the builder stage installs and compiles inside the image.

### Why this lab exists

`COPY . .` in the Dockerfile copies the whole folder unless this file says otherwise. `terraform/` is **infrastructure as code**, not the app. Laptop `node_modules` and `dist/` must stay out — the builder stage installs and compiles inside the image.

This is **one** paste. If it goes wrong, skip to **Your file must look like this**.

### Procedure

1. Right-click the **accelerator-app** project root → **New File** → name it exactly `.dockerignore`.  
2. Paste (these names are **not** packed into the image):

```dockerignore
# Do not copy these into the image.

node_modules
# Laptop packages. The builder stage runs npm install itself.

dist
# Laptop Vite output. The builder stage runs npm run build itself.

.git
# Git history. Not needed to serve the page.

.gitignore
# Git ignore rules. Not the app.

Dockerfile
# The Dockerfile itself. Not files nginx should serve.

terraform
# Terraform files. Infrastructure as code — not the React app.

*.md
# Accelerator notes and README. Not the app.

.oxlintrc.json
# Local lint config. Not needed in the image.
```

3. Save. **Do not** `docker build` yet. That is Lab 3.4.

### Your file must look like this — `.dockerignore`

Open `.dockerignore` in the accelerator-app root. It must match this block. If it does not, **select all**, delete, paste this whole block, save.

```dockerignore
# Do not copy these into the image.

node_modules
# Laptop packages. The builder stage runs npm install itself.

dist
# Laptop Vite output. The builder stage runs npm run build itself.

.git
# Git history. Not needed to serve the page.

.gitignore
# Git ignore rules. Not the app.

Dockerfile
# The Dockerfile itself. Not files nginx should serve.

terraform
# Terraform files. Infrastructure as code — not the React app.

*.md
# Accelerator notes and README. Not the app.

.oxlintrc.json
# Local lint config. Not needed in the image.
```

### Verification

- `.dockerignore` sits beside `Dockerfile`.  
- **Expected State:** Ignore list on disk. Image not built yet.

### Troubleshooting References

¹ **Symptom:** File named `dockerignore.txt` or the leading dot is missing.  
  **Resolution:** Rename to `.dockerignore`.  
² **Symptom:** A line looks wrong.  
  **Resolution:** Replace with **Your file must look like this**.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 3.3 — Create `.dockerignore`

---

## Lab 3.4 — Build `accelerator:latest`

### Objective

Pack the app into a local image named `accelerator:latest`. This does **not** talk to AWS.

### Procedure

The terminal must be in the **accelerator-app** root — the folder with `package.json` and `Dockerfile`. If the prompt is still inside `terraform/` from Workflow 02, move up one folder (this only changes folder; it does not build):

```bash
cd ..
```

If a new terminal already opened on `accelerator-app`, skip that `cd`. You are in the right place if you can see `package.json`.

`docker build` reads the Dockerfile, runs the Node stage, then the nginx stage, and stores an image on **this laptop**. `-t accelerator:latest` is the name:tag. `.` means “use this folder as the build context.” It does **not** push to ECR. First build can take a few minutes.

When it finishes you should see **one** of these (both mean the image is tagged):

- **Successfully tagged accelerator:latest.** (classic Docker)
- **naming to docker.io/library/accelerator:latest** (BuildKit — default on Docker Desktop)

Either line is a pass. Then `docker images` must show **accelerator** / **latest**.

```bash
docker build -t accelerator:latest .
```

`docker images` lists images on the laptop. It does **not** start a container. You should see a row named **accelerator** with tag **latest**.

```bash
docker images
```

### Verification

- Build exits without error.  
- **Expected State:** Local image `accelerator:latest`.

### Troubleshooting References

¹ **Symptom:** Fails at `npm run build`.  
  **Resolution:** `npm install` then `npm run build` from the same root; fix app errors; rebuild.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 3.4 — Build `accelerator:latest`

---

## Lab 3.5 — Prove the image at localhost

### Objective

Start one container from that image and open it in a browser. Still no AWS.

### Procedure

`docker run` starts a **container** — a running copy of the image. `-d` means in the background (your terminal stays free). `-p 8080:80` maps laptop port **8080** to nginx port **80** inside the container. `--name accelerator-container` gives it a name so you can stop it later. It does **not** publish to the internet.

If a container with that name already exists, the command fails. Lab 3.6 (or the troubleshooting line) removes it, then you run this again.

```bash
docker run -d -p 8080:80 --name accelerator-container accelerator:latest
```

You should get a long container id. That means it started. The page is Lab **See it (browser)** next — not this terminal.

### See it (browser)

1. Open a **new** browser tab.  
2. Go to **`http://localhost:8080`** exactly (`http`, not `https`).  
3. You should see the **#AWS ACCELERATOR** landing page.  
   **Why it matters:** this is the packed **image** on your laptop. There is no ECR registry or ECS cluster yet. A padlock / certificate error means the browser forced **https** — change it back.

### Verification

- The **#AWS ACCELERATOR** landing page loads.  
- **Expected State:** The image serves the product locally.

### Troubleshooting References

¹ **Symptom:** Port or name conflict.  
  **Resolution:** `docker rm -f accelerator-container` then re-run Lab 3.5.

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 3.5 — Prove the image at localhost

---

## Lab 3.6 — Remove the test container

### Objective

Stop and delete the **container**. Keep the **image** `accelerator:latest` for Workflow 04.

### Procedure

`docker stop` tells the running container to shut down. It does **not** delete the image. It does **not** delete the container record yet.

```bash
docker stop accelerator-container
```

`docker rm` deletes that stopped container. Port 8080 is free again. The image **accelerator:latest** stays on the laptop.

```bash
docker rm accelerator-container
```

`docker ps -a` lists containers, including stopped ones. You should **not** see `accelerator-container`.

```bash
docker ps -a
```

`docker images` lists images. You should still see **accelerator** / **latest**. That is what Workflow 04 will tag and push.

```bash
docker images
```

### Verification

- `docker ps -a` does not list `accelerator-container`.  
- Image `accelerator:latest` still exists (`docker images`).

<p><strong style="color:#16a34a">Tick this when you finish this lab.</strong> Change <code>- [ ]</code> to <code>- [x]</code>.</p>

- [ ] Lab 3.6 — Remove the test container

---

### Workflow Completion Criteria

- [ ] `Dockerfile` and `.dockerignore` in the accelerator-app root  
- [ ] `http://localhost:8080` showed the landing page  
- [ ] Test container removed; local image kept  
- [ ] You did **not** apply Terraform  

### Where We Are Going Next

**Workflow 04** creates ECR, pushes `accelerator:latest`, then **destroys** the repo. Workflow 05 will apply again.

Open `workflow 4 - Amazon ECR.md` when you are ready.
