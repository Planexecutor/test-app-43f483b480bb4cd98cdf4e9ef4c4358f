# ── Stage 1: Build ───────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build 2>/dev/null; mkdir -p /app/out && \
    if [ -d /app/dist ]; then cp -r /app/dist/. /app/out/; \
    elif [ -d /app/build ]; then cp -r /app/build/. /app/out/; \
    else cp -r /app/public/. /app/out/; fi

# ── Stage 2: Serve ───────────────────────────────────────
FROM nginx:alpine AS runtime
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY --from=builder /app/out/ .
RUN printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]