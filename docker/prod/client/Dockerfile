FROM docker.io/node:20.13-alpine3.18@sha256:53108f67824964a573ea435fed258f6cee4d88343e9859a99d356883e71b490c AS base

# stage 1. Install dependencies only when needed
FROM base AS deps

RUN apk add --no-cache libc6-compat

ARG APP_HOME=/app
WORKDIR ${APP_HOME}

COPY ./client/package.json ./
COPY ./client/pnpm-lock.yaml ./

RUN \
  echo "=== Available files ===" && ls -la && \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then \
    echo "=== Node/NPM versions ===" && \
    node --version && npm --version && \
    echo "=== Corepack check ===" && \
    corepack --version && \
    echo "=== Enabling pnpm ===" && \
    corepack enable pnpm && \
    pnpm --version && \
    echo "=== Installing ===" && \
    pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Stage 2 Rebuild the source code when needed

FROM base AS builder
ARG APP_HOME=/app
WORKDIR ${APP_HOME}

# Variables publiques Next.js baked dans le bundle au build
ARG NEXT_PUBLIC_DOMAIN
ENV NEXT_PUBLIC_DOMAIN=${NEXT_PUBLIC_DOMAIN}

COPY --from=deps /app/node_modules ./node_modules

COPY ./client ${APP_HOME}

RUN corepack enable pnpm && pnpm run build

# Stage 3: Create a production image. copy all the files and run next as a non root user
FROM base AS runner

ARG APP_HOME=/app
WORKDIR ${APP_HOME}

ENV NODE_ENV=production

RUN addgroup -g 1001 -S nodejs && \
  adduser -S nextjs -u 1001 -G nodejs

COPY --from=builder /app/public ./public

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

RUN chown -R nextjs:nodejs ${APP_HOME}

USER nextjs

ENV PORT 3000

CMD HOSTNAME=client node server.js

