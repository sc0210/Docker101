# ---- Stage 1: build ----
# Full toolchain (Node) lives ONLY in this stage.
FROM node:22-alpine AS build
WORKDIR /src

# Deps first for layer caching (no deps here, but the pattern matters).
COPY package.json ./
RUN npm install --omit=dev || true

# Then the source, then produce static output in /src/dist
COPY build.js ./
COPY src ./src
RUN node build.js

# ---- Stage 2: runtime ----
# Tiny nginx serves the built static files. No Node, no source, no build cache.
FROM nginx:1.27-alpine
COPY --from=build /src/dist /usr/share/nginx/html
EXPOSE 80
