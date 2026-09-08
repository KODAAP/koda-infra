# Guide de déploiement — Build → Push → Deploy (VM OVH)

Ce document rassemble toute la configuration et les explications nécessaires pour :
- builder et pousser les images Docker listées dans `docker/services.yaml` (manifest-driven),
- déployer sur une VM OVH via SSH (sans Kubernetes), en exécutant des commandes distantes depuis GitHub Actions.

Le fichier PDF généré à partir de ce Markdown sera créé via le workflow `.github/workflows/generate-pdf.yml` (exécution manuelle `workflow_dispatch`).

---

## Arborescence recommandée

- docker/
  - services.yaml        # manifeste central (liste des services + meta)
  - prod/
    - api/
      - Dockerfile
      - .dockerignore
    - client/
      - Dockerfile
      - .dockerignore
    - worker/            # optionnel
      - Dockerfile
  - README.md            # conventions

- infra/
  - docker-compose.yml  # versionné (compose de référence pour la VM)

- .github/
  - workflows/
    - deploy.yml         # build & push & deploy via SSH
    - generate-pdf.yml   # convertit docs/deploy-guide.md -> docs/deploy-guide.pdf (manually)

- docs/
  - deploy-guide.md      # ce fichier (source)
  - deploy-guide.pdf     # généré par le workflow (OPTIONNEL)

---

## Fichiers essentiels expliqués

1) `docker/services.yaml`

  - Single source of truth pour les services à builder.
  - Exemple minimal :

```yaml
services:
  - name: api
    context: docker/prod/api
    dockerfile: Dockerfile
    platforms: ["linux/amd64","linux/arm64"]

  - name: client
    context: docker/prod/client
    dockerfile: Dockerfile
    platforms: ["linux/amd64","linux/arm64"]

  - name: worker
    context: docker/prod/worker
    dockerfile: Dockerfile
    platforms: ["linux/amd64"]
```

2) Workflow `.github/workflows/deploy.yml` (manifest-driven, build & push, puis deploy via SSH)

- Ce workflow lit `docker/services.yaml`, génère une matrix, build/push chaque image sur GHCR
  (`ghcr.io/${{ github.repository_owner }}/${{ service }}`), puis exécute des commandes sur la VM via SSH :
  il génère un `docker-compose.override.yml` localement contenant les images taggées (`sha-${{ github.sha }}`),
  transfère ce fichier sur la VM et exécute `docker compose pull && docker compose up -d`.

- Pré-requis secrets GitHub :
  - `SERVER_HOST` (IP ou hostname)
  - `SERVER_USER` (ex: deploy)
  - `SSH_PRIVATE_KEY` (clé privée pour l'utilisateur deploy)
  - `GHCR_PAT_SERVER` (PAT minimal `read:packages` pour pull depuis GHCR)

3) `infra/docker-compose.yml`

- Compose « source of truth » pour la VM. Contient la configuration complète des services (ports, volumes, envs,
  réseaux). Le workflow ne change rien d’autre que l’image via `docker-compose.override.yml` généré.

4) (Optionnel) `deploy.sh` sur la VM

- Si tu préfères un script réutilisable côté serveur, tu peux placer un `deploy.sh` qui :
  - effectue `docker login ghcr.io`,
  - `envsubst` un template `docker-compose.tpl.yml` en `docker-compose.yml`,
  - `docker compose pull` puis `docker compose up -d`.

---

## Contenu du workflow `deploy.yml` (rappels)

Le workflow principal (`.github/workflows/deploy.yml`) construit et push :
- Utilise `docker/setup-buildx-action`, `docker/build-push-action`, cache `type=gha`.
- Login à GHCR avec `secrets.GITHUB_TOKEN` (ou `GHCR_PAT` si tu préfères).
- Génère `docker-compose.override.yml` (base64) puis SSH sur la VM et applique `docker compose pull && up -d`.

> Voir le fichier concret dans le repo `.github/workflows/deploy.yml` (si déjà présent). Sinon, je peux
> générer ce workflow à partir du manifeste `docker/services.yaml`.

---

## Exemple de `docker-compose.tpl.yml` (template côté serveur si tu utilises `deploy.sh`)

```yaml
version: "3.8"
services:
  api:
    image: ${IMAGE_api}
    restart: always
    environment:
      - NODE_ENV=production
    ports:
      - "3000:3000"

  client:
    image: ${IMAGE_client}
    restart: always
    ports:
      - "80:80"

  worker:
    image: ${IMAGE_worker}
    restart: always
```

---

## Exemple minimal `deploy.sh` (sur la VM) — optionnel

```bash
#!/usr/bin/env bash
set -euo pipefail
OWNER="$1"
TAG_SHA="$2"
APP_DIR="/home/deploy/app"
COMPOSE_TEMPLATE="$APP_DIR/docker-compose.tpl.yml"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

cd "$APP_DIR"
export IMAGE_api="ghcr.io/${OWNER}/api:${TAG_SHA}"
export IMAGE_client="ghcr.io/${OWNER}/client:${TAG_SHA}"
export IMAGE_worker="ghcr.io/${OWNER}/worker:${TAG_SHA}"

echo "$GHCR_PAT" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
envsubst < "$COMPOSE_TEMPLATE" > "$COMPOSE_FILE"
docker compose pull
docker compose up -d --remove-orphans
```

---

## Génération automatique du PDF (workflow `generate-pdf.yml`)

Pour fournir le PDF demandé directement dans le dépôt, j'ajoute un workflow `generate-pdf.yml` qui :
- est déclenchable manuellement (workflow_dispatch),
- installe `pandoc` + `texlive-xetex` sur le runner,
- convertit `docs/deploy-guide.md` en `docs/deploy-guide.pdf`,
- commit & push `docs/deploy-guide.pdf` sur `main`.

Tu pourras lancer cette conversion depuis l'onglet Actions > `Generate PDF from Markdown` > Run workflow.

---

## Sécurité minimale & bonnes pratiques

- Ne stocke PAS les secrets dans le repo ; utilise GitHub Secrets.
- `GHCR_PAT_SERVER` doit avoir uniquement le scope `read:packages`.
- Créé un utilisateur SSH dédié `deploy` et limite ses permissions (membre du groupe docker).
- Sur la VM, restreins l'accès réseau (UFW) et garde le système à jour.

---

## Prochaine étape

1. Si tu veux que j'engage ces fichiers dans le repo (`docs/deploy-guide.md` + workflow de génération PDF),
   je peux les ajouter directement sur la branche `main` (comme demandé). Ensuite, tu pourras lancer le
   workflow manuellement pour générer `docs/deploy-guide.pdf`.

2. Optionnel : je peux également générer/commiter le workflow `deploy.yml` (build/push/deploy) si tu veux
   que je mette en place l'intégration complète.

---

Fin du document.
