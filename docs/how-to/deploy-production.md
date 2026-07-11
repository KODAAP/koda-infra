# Déployer Sycosur en production

Ce guide décrit le déploiement de Sycosur sur un serveur de production avec Docker Compose, Nginx et HTTPS.

## Prérequis

- Serveur Linux avec Docker et Docker Compose installés
- Nom de domaine pointant vers le serveur (ex. `sycosur.insuco.net`)
- Certificat SSL (Let's Encrypt recommandé)
- Accès SSH au serveur
- Instance ODK Central accessible depuis le serveur

---

## Étape 1 — Cloner le dépôt sur le serveur

```bash
git clone https://github.com/insuco/sycosur.git /opt/sycosur
cd /opt/sycosur
```

---

## Étape 2 — Configurer les variables d'environnement

### Fichier racine `.env`

```env
COMPOSE_BAKE=true
DOMAIN=sycosur.insuco.net
```

### Fichier `backend/.envs/.env.production`

```env
# Django
SITE_NAME="Sycosur"
DJANGO_SECRET_KEY="CHANGEZ-MOI-clé-très-longue-et-aléatoire"
DJANGO_ADMIN_URL="votre-url-admin-secrète/"
DJANGO_SETTINGS_MODULE=config.settings.production
DOMAIN=sycosur.insuco.net

# Email
EMAIL_PORT=587
EMAIL_HOST=smtp.votre-fournisseur.com
DEFAULT_FROM_EMAIL="support-sycosur@insuco.com"

# Base de données
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=sycosur
POSTGRES_USER=sycosur_prod
POSTGRES_PASSWORD=MOT-DE-PASSE-FORT

# Redis / Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
CELERY_FLOWER_USER=admin
CELERY_FLOWER_PASSWORD=MOT-DE-PASSE-FLOWER

# Sécurité
COOKIE_SECURE=True
SIGNING_KEY="CHANGEZ-MOI-clé-signing"

# Google OAuth
GOOGLE_CLIENT_ID="votre-client-id.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="votre-secret"
REDIRECT_URIS="https://sycosur.insuco.net/api/v1/auth/google"

# ODK Central
ODK_CENTRAL_URL=https://odk.insuco.net/v1
ODK_ADMIN_EMAIL=admin@insuco.com
ODK_ADMIN_PASSWORD=MOT-DE-PASSE-ODK
ODK_VERIFY_SSL=True

# Enketo
ENKETO_API_URL=http://enketo:8005/-/api/v2
ENKETO_API_KEY=votre-clé-enketo-longue
ENKETO_PUBLIC_BASE_URL=https://sycosur.insuco.net

# Google Drive (exports)
GOOGLE_DRIVE_FOLDER_ID=votre-folder-id
```

---

## Étape 3 — Créer le réseau Docker

```bash
docker network create sycosur_network
```

---

## Étape 4 — Construire et démarrer

```bash
docker compose -f prod.yml up --build -d
```

---

## Étape 5 — Initialiser la base de données

```bash
docker exec -it sycosur_api python manage.py migrate
docker exec -it sycosur_api python manage.py collectstatic --noinput
docker exec -it sycosur_api python manage.py createsuperuser
```

---

## Étape 6 — Configurer Nginx (reverse proxy externe)

Si vous utilisez un Nginx hôte (en dehors de Docker) pour gérer le SSL :

```nginx
server {
    listen 80;
    server_name sycosur.insuco.net;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name sycosur.insuco.net;

    ssl_certificate /etc/letsencrypt/live/sycosur.insuco.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sycosur.insuco.net/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Augmenter la taille max pour les uploads XLSForm et médias
    client_max_body_size 100M;
}
```

---

## Étape 7 — Vérifier le déploiement

```bash
# Statut des conteneurs
docker compose -f prod.yml ps

# Santé de l'API
curl -f https://sycosur.insuco.net/api/v1/health/ || echo "KO"

# Logs en temps réel
docker compose -f prod.yml logs -f api celeryworker
```

---

## Mise à jour de l'application

```bash
cd /opt/sycosur
git pull origin main
docker compose -f prod.yml up --build -d
docker exec -it sycosur_api python manage.py migrate
docker exec -it sycosur_api python manage.py collectstatic --noinput
```

---

## Sauvegardes

### Base de données PostgreSQL

```bash
# Sauvegarde
docker exec sycosur_postgres pg_dump -U sycosur_prod sycosur > backup_$(date +%Y%m%d).sql

# Restauration
docker exec -i sycosur_postgres psql -U sycosur_prod sycosur < backup_20260101.sql
```

### Fichiers médias

```bash
# Sauvegarder le dossier media (photos, exports)
tar -czf media_backup_$(date +%Y%m%d).tar.gz /opt/sycosur/backend/media/
```

---

## Permissions des fichiers statiques

Si les fichiers statiques ne sont pas servis correctement, consultez [`docs/staticfiles_permissions.md`](../staticfiles_permissions.md) pour les permissions Docker à appliquer.
