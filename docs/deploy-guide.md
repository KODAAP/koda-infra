# Guide de déploiement continu — Build → Push → Deploy (VM OVH)

Ce document décrit l'architecture et la procédure de déploiement continu automatisé pour le projet **KODAAP**.
Le pipeline repose intégralement sur **GitHub Actions**, le registre **GHCR** (*GitHub Container Registry*) et une connexion **SSH** vers la machine virtuelle OVH, **sans nécessiter de script `deploy.sh` sur le serveur**.

---

## 1. Vue d'ensemble de l'architecture

### Deux images applicatives sur GHCR, zéro duplication
Pour optimiser les temps de compilation CI et l'espace de stockage sur le registre :
- **`ghcr.io/kodaap/koda-api`** : Image unique pour tous les services Django (`api`, `celeryworker`, `celerybeat`, `flower`).
  - Ils partagent le même code source (`backend/`) et les mêmes dépendances Python.
  - Chaque conteneur instancie cette image en surchargeant simplement sa commande d'exécution (`/start`, `/start-celeryworker`, `/start-celerybeat`, `/start-flower`).
- **`ghcr.io/kodaap/koda-client`** : Image pour le frontend web.
- **Services tiers (`postgres`, `redis`)** : Utilisent directement les images certifiées officielles depuis Docker Hub (`postgres:16-bullseye`, `redis:7.0-alpine3.19`). Inutile de les re-builder ou de les héberger sur GHCR.

```
       [ Push sur main / dispatch ]
                     │
                     ▼
       ┌───────────────────────────┐
       │   GitHub Actions (CI/CD)  │
       └─────────────┬─────────────┘
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
┌──────────────────┐    ┌──────────────────┐
│ Build Backend    │    │ Build Frontend   │
│ (Django)         │    │ (Client)         │
└────────┬─────────┘    └────────┬─────────┘
         │                       │
         └───────────┬───────────┘
                     ▼
        [ Push sur ghcr.io ]
        • koda-api:<sha> & latest
        • koda-client:<sha> & latest
                     │
                     ▼ (SSH automatique)
        ┌────────────────────────┐
        │        VM OVH          │
        │ • Copie prod.yml       │
        │ • docker compose pull  │
        │ • docker compose up -d │
        │ • migrate & static     │
        │ • docker image prune   │
        └────────────────────────┘
```

---

## 2. Arborescence du projet

```
koda-infra/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Pipeline CI/CD complet (Build, Push & SSH Deploy)
├── backend/                    # Submodule Git (code Django)
├── client/                     # Submodule Git (code Frontend)
├── docker/
│   └── prod/
│       ├── django/
│       │   ├── Dockerfile      # Dockerfile unique pour api, celery, flower
│       │   ├── entrypoint      # Script d'initialisation
│       │   ├── start           # Lancement Gunicorn/Django
│       │   └── celery/         # Scripts pour worker, beat, flower
│       └── client/
│           └── Dockerfile      # Dockerfile frontend
├── docs/
│   └── deploy-guide.md         # Cette documentation
└── prod.yml                    # Compose de production
```

---

## 3. Configuration de production (`prod.yml`)

Le fichier `prod.yml` fait référence dynamiquement au tag publié par la CI via la variable `${IMAGE_TAG:-latest}` :

```yaml
services:
  api: &api
    image: ghcr.io/kodaap/koda-api:${IMAGE_TAG:-latest}
    container_name: koda_api
    restart: unless-stopped
    volumes:
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    expose:
      - "8000"
    env_file:
      - ./backend/.envs/.env.prod
    depends_on:
      - postgres
      - redis
    command: /start
    networks:
      - reverseProxy_nw

  postgres:
    image: postgres:16-bullseye
    container_name: koda_postgres
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
    env_file:
      - ./backend/.envs/.env.prod
    networks:
      - reverseProxy_nw

  client:
    image: ghcr.io/kodaap/koda-client:${IMAGE_TAG:-latest}
    container_name: koda_client
    restart: unless-stopped
    env_file:
      - "./client/.env.prod"
    networks:
      - reverseProxy_nw

  redis:
    image: redis:7.0-alpine3.19
    container_name: koda_redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - reverseProxy_nw

  celeryworker:
    <<: *api
    container_name: koda_celeryworker
    command: /start-celeryworker

  flower:
    <<: *api
    container_name: koda_flower
    ports:
      - "5555:5555"
    command: /start-flower

networks:
  reverseProxy_nw:
    external: true

volumes:
  media_volume:
  static_volume:
  postgres_data:
  redis_data:
```

---

## 4. Secrets GitHub Actions requis

Dans GitHub (`Settings` > `Secrets and variables` > `Actions`), configurez les secrets suivants :

| Secret | Description | Exemple |
| :--- | :--- | :--- |
| `GH_PAT` | GitHub Personal Access Token avec droit `repo` pour cloner les submodules `backend` et `client` | `ghp_xxxxxxxxxxxx` |
| `GHCR_PULL_TOKEN` | GitHub PAT avec le scope `read:packages` permettant à la VM de télécharger les images GHCR | `ghp_yyyyyyyyyyyy` |
| `SSH_HOST` | Adresse IP ou domaine de la VM OVH | `ns526301.ip-149-56-16.net` |
| `SSH_USER` | Utilisateur SSH de déploiement sur la VM | `ubuntu` |
| `SSH_PORT` | Port SSH du serveur | `22` (ou port personnalisé ex: `49160`) |
| `SSH_KEY` | Clé privée SSH (l'équivalent public doit être dans `~/.ssh/authorized_keys` sur la VM) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DEPLOY_PATH` *(optionnel)* | Chemin du dossier projet sur la VM | `/home/ubuntu/koda-infra` (valeur par défaut) |

---

## 5. Préparation initiale de la VM OVH

À exécuter **une seule fois** sur la machine virtuelle :

### 1. Installer Docker & Docker Compose v2
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
# Suivre l'installation officielle Docker pour Ubuntu/Debian
# S'assurer que l'utilisateur appartient au groupe docker :
sudo usermod -aG docker $USER
```

### 2. Créer le réseau Docker externe
Le reverse proxy (Traefik, Nginx Proxy Manager, etc.) et Kodaap communiquent via le réseau externe `reverseProxy_nw` :
```bash
docker network create reverseProxy_nw
```

### 3. Créer l'arborescence et les variables d'environnement
Sur la VM, créez le répertoire de l'application et les fichiers d'environnement secrets :
```bash
mkdir -p /home/ubuntu/koda-infra/backend/.envs
mkdir -p /home/ubuntu/koda-infra/client

# Créer les fichiers d'environnement :
nano /home/ubuntu/koda-infra/backend/.envs/.env.prod
nano /home/ubuntu/koda-infra/client/.env.prod
```

---

## 6. Déroulement du déploiement automatisé

À chaque commit sur `main` (ou déclenchement manuel via l'onglet **Actions** > **Run workflow**) :

1. **Job `build-push-docker`** :
   - Récupère le dépôt racine et les sous-modules Git via `GH_PAT`.
   - Calcule le tag de version court `sha-<commit>`.
   - Compile l'image `koda-api` avec Docker Buildx et le cache GitHub Actions (`cache-to: type=gha`).
   - Compile l'image `koda-client`.
   - Publie les images sur `ghcr.io/kodaap/...` avec les tags `sha-<commit>` et `latest`.
2. **Job `deploy`** :
   - Transfère automatiquement la dernière version de `prod.yml` sur la VM OVH via `appleboy/scp-action`.
   - Ouvre une session SSH sécurisée via `appleboy/ssh-action` et exécute séquentiellement :
     ```bash
     # 1. Authentification au registre
     echo "$GHCR_PULL_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin
     
     # 2. Assignation du tag de version
     export IMAGE_TAG="$IMAGE_TAG"
     
     # 3. Récupération des images
     docker compose -f prod.yml pull
     
     # 4. Redémarrage des conteneurs
     docker compose -f prod.yml up -d --remove-orphans
     
     # 5. Migrations Django
     docker compose -f prod.yml exec -T api python manage.py migrate --noinput
     
     # 6. Fichiers statiques Django
     docker compose -f prod.yml exec -T api python manage.py collectstatic --noinput
     
     # 7. Nettoyage des vieilles images (> 7 jours)
     docker image prune -af --filter "until=168h"
     ```

---

## 7. Commandes utiles pour la maintenance sur la VM

```bash
cd /home/ubuntu/koda-infra

# Vérifier l'état de tous les conteneurs
docker compose -f prod.yml ps

# Consulter les logs en temps réel
docker compose -f prod.yml logs -f api
docker compose -f prod.yml logs -f celeryworker

# Relancer manuellement un service
docker compose -f prod.yml restart api

# Exécuter une commande Django ponctuelle
docker compose -f prod.yml exec api python manage.py createsuperuser
```
