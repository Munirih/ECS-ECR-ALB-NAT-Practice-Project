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
