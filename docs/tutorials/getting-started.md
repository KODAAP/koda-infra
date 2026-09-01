# Installation locale

Ce tutoriel vous guide pas à pas pour lancer Koda en environnement de développement local avec Docker Compose.

## Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) ≥ 24
- [Git](https://git-scm.com/)
- Accès à une instance ODK Central (ex. `https://test-odk.insuco.net`)
- Compte Google OAuth (optionnel, pour le SSO)

---

## Étape 1 — Cloner le dépôt

```bash
git clone https://github.com/insuco/koda.git
cd koda
```

---

## Étape 2 — Configurer les variables d'environnement

Copiez le fichier d'exemple et adaptez-le :

```bash
cp backend/.envs/.env.local.example backend/.envs/.env.local
```

Éditez `backend/.envs/.env.local` avec vos valeurs :

```env
# Django
DJANGO_SECRET_KEY="votre-clé-secrète-longue"
DJANGO_SETTINGS_MODULE=config.settings.local
DOMAIN=localhost:8080

# Base de données
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=koda
POSTGRES_USER=admin
POSTGRES_PASSWORD=votre-mot-de-passe

# ODK Central
ODK_CENTRAL_URL=https://votre-odk.domaine.net/v1
ODK_ADMIN_EMAIL=admin@votre-domaine.com
ODK_ADMIN_PASSWORD=votre-mot-de-passe-odk
ODK_VERIFY_SSL=False  # True en production

# Enketo
ENKETO_API_URL=http://enketo:8005/-/api/v2
ENKETO_API_KEY=votre-clé-enketo
ENKETO_PUBLIC_BASE_URL=http://localhost:8080

# Redis / Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
```

> **Note** : Le fichier `.env` à la racine contient uniquement `COMPOSE_BAKE=true` et `DOMAIN=localhost:8080`.

---

## Étape 3 — Créer le réseau Docker

```bash
docker network create koda_network
```

---

## Étape 4 — Construire et démarrer les services

```bash
docker compose -f local.yml up --build
```

Les services démarrés sont :

| Service | Rôle | Port local |
|---|---|---|
| `koda_nginx` | Reverse proxy (point d'entrée) | `8080` |
| `koda_api` | Backend Django | interne `8001` |
| `koda_client` | Frontend Next.js | interne `3000` |
| `koda_postgres` | Base de données | `5432` |
| `koda_redis` | Broker Celery + cache | interne |
| `koda_celeryworker` | Traitement des exports async | — |
| `koda_enketo` | Formulaires web ODK | interne `8005` |
| `koda_flower` | Monitoring Celery | `5555` |
| `koda_mailpit` | Serveur mail de dev | `8025` |

---

## Étape 5 — Initialiser la base de données

Dans un autre terminal :

```bash
docker exec -it koda_api python manage.py migrate
docker exec -it koda_api python manage.py createsuperuser
```

---

## Étape 6 — Accéder à l'application

| URL | Description |
|---|---|
| `http://localhost:8080` | Application Koda |
| `http://localhost:8080/secret/` | Interface d'administration Django |
| `http://localhost:5555` | Flower (monitoring Celery) |
| `http://localhost:8025` | Mailpit (emails de dev) |

---

## Vérification rapide

```bash
# Vérifier que tous les conteneurs sont UP
docker compose -f local.yml ps

# Consulter les logs du backend
docker compose -f local.yml logs api -f

# Consulter les logs du worker Celery
docker compose -f local.yml logs celeryworker -f
```

---

## Problèmes courants

??? failure "Erreur `network koda_network not found`"
    Créez le réseau manuellement :
    ```bash
    docker network create koda_network
    ```

??? failure "Erreur de connexion à ODK Central"
    Vérifiez `ODK_CENTRAL_URL`, `ODK_ADMIN_EMAIL` et `ODK_ADMIN_PASSWORD` dans `.env.local`.  
    Si votre ODK utilise un certificat auto-signé, passez `ODK_VERIFY_SSL=False`.

??? failure "Le frontend ne se recharge pas automatiquement"
    Assurez-vous que `WATCHPACK_POLLING=true` et `CHOKIDAR_USEPOLLING=true` sont bien définis dans `local.yml` (déjà configuré par défaut).
