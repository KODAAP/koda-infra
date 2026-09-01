# === BASE ===
FROM node:20-alpine AS base

# Active corepack pour gérer pnpm proprement
RUN corepack enable && corepack prepare pnpm@10.15.1 --activate

# Ajoute compatibilité souvent nécessaire
RUN apk add --no-cache libc6-compat

# === DEPS (juste les dépendances - excellent pour le cache) ===
FROM base AS deps
WORKDIR /app

# Copie uniquement les fichiers de lock & package
COPY client/package.json client/pnpm-lock.yaml ./

# Cache pnpm store → énorme gain de temps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile \
        --store-dir=/pnpm/store \
        --fetch-timeout=120000

# === DEVELOPMENT (image finale pour dev) ===
FROM base AS development

# Sécurité : utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 -G nodejs

WORKDIR /app

# Copie les dépendances installées depuis deps
COPY --from=deps /app/node_modules ./node_modules

# Crée le dossier .next avec les bonnes permissions AVANT de monter le volume
# Cela permet au volume anonyme d'hériter des permissions correctes
RUN mkdir -p /app/.next/cache && \
    chown -R nextjs:nodejs /app

USER nextjs

# On ne COPY PAS le code source ici → on le monte via volume dans compose

# Lancement du serveur dev (Turbopack par défaut en Next 16+)
CMD ["pnpm", "dev"]