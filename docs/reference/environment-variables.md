# Variables d'environnement

Toutes les variables de configuration de Koda sont définies dans `backend/.envs/.env.local` (développement) ou `backend/.envs/.env.production` (production).

!!! danger "Sécurité"
    Ne committez jamais les fichiers `.env*` contenant des secrets réels. Le fichier `.gitignore` exclut déjà `backend/.envs/`.

---

## Django

| Variable | Obligatoire | Exemple | Description |
|---|:---:|---|---|
| `SITE_NAME` | ✅ | `"Koda2.0"` | Nom affiché dans les emails et l'interface |
| `DJANGO_SECRET_KEY` | ✅ | `"clé-aléatoire-longue"` | Clé secrète Django (min. 50 caractères) |
| `DJANGO_ADMIN_URL` | ✅ | `"secret/"` | Chemin URL de l'interface d'administration |
| `DJANGO_SETTINGS_MODULE` | ✅ | `config.settings.local` | Module de settings à utiliser |
| `DOMAIN` | ✅ | `localhost:8080` | Domaine public de l'application |
| `COOKIE_SECURE` | ✅ prod | `True` | Active les cookies sécurisés (HTTPS uniquement) |
| `SIGNING_KEY` | ✅ | `"clé-signing"` | Clé de signature JWT |
| `ADMIN_PASSWORD` | ❌ | `admin123` | Mot de passe du superuser créé automatiquement |

---

## Base de données PostgreSQL

| Variable | Obligatoire | Exemple | Description |
|---|:---:|---|---|
| `POSTGRES_HOST` | ✅ | `postgres` | Hôte PostgreSQL (nom du service Docker) |
| `POSTGRES_PORT` | ✅ | `5432` | Port PostgreSQL |
| `POSTGRES_DB` | ✅ | `koda` | Nom de la base de données |
| `POSTGRES_USER` | ✅ | `admin` | Utilisateur PostgreSQL |
| `POSTGRES_PASSWORD` | ✅ | `mot-de-passe` | Mot de passe PostgreSQL |

---

## Email

| Variable | Obligatoire | Exemple | Description |
|---|:---:|---|---|
| `EMAIL_HOST` | ✅ | `mailpit` (dev) / `smtp.gmail.com` (prod) | Serveur SMTP |
| `EMAIL_PORT` | ✅ | `1025` (dev) / `587` (prod) | Port SMTP |
| `DEFAULT_FROM_EMAIL` | ✅ | `support-koda@insuco.com` | Adresse expéditeur par défaut |

---

## Redis et Celery

| Variable | Obligatoire | Exemple | Description |
|---|:---:|---|---|
| `CELERY_BROKER_URL` | ✅ | `redis://redis:6379/0` | URL du broker Redis pour Celery |
| `CELERY_RESULT_BACKEND` | ✅ | `redis://redis:6379/0` | Backend de stockage des résultats Celery |
| `CELERY_FLOWER_USER` | ✅ | `admin` | Identifiant de connexion à Flower |
| `CELERY_FLOWER_PASSWORD` | ✅ | `pass123456` | Mot de passe Flower |

---

## ODK Central

| Variable | Obligatoire | Exemple | Description |
|---|:---:|---|---|
| `ODK_CENTRAL_URL` | ✅ | `https://test-odk.insuco.net/v1` | URL de base de l'API ODK Central |
| `ODK_ADMIN_EMAIL` | ✅ | `admin@insuco.com` | Email du compte admin ODK (pool 1) |
| `ODK_ADMIN_PASSWORD` | ✅ | `mot-de-passe` | Mot de passe admin ODK (pool 1) |
| `ODK_ADMIN_EMAIL2` | ❌ | `admin2@insuco.com` | Email du compte admin ODK (pool 2) |
| `ODK_ADMIN_PASSWORD2` | ❌ | `mot-de-passe` | Mot de passe admin ODK (pool 2) |
| `ODK_VERIFY_SSL` | ✅ | `False` (dev) / `True` (prod) | Vérification du certificat SSL ODK |

!!! info "Pool d'utilisateurs ODK"
    Koda utilise un ou deux comptes administrateurs ODK Central pour toutes les opérations API. Ces comptes doivent avoir les droits d'administration sur ODK Central.

---

## Enketo

| Variable | Obligatoire | Exemple | Description |
|---|:---:|---|---|
| `ENKETO_API_URL` | ✅ | `http://enketo:8005/-/api/v2` | URL interne de l'API Enketo |
| `ENKETO_API_KEY` | ✅ | `clé-longue` | Clé d'authentification API Enketo |
| `ENKETO_PUBLIC_BASE_URL` | ✅ | `http://localhost:8080` | URL publique pour les liens de formulaires |

---

## Google OAuth (SSO)

| Variable | Obligatoire | Exemple | Description |
|---|:---:|---|---|
| `GOOGLE_CLIENT_ID` | ❌ | `711469...apps.googleusercontent.com` | Client ID Google OAuth |
| `GOOGLE_CLIENT_SECRET` | ❌ | `GOCSPX-...` | Secret Google OAuth |
| `REDIRECT_URIS` | ❌ | `http://localhost:8080/api/v1/auth/google` | URI de redirection OAuth |

---

## Google Drive (exports)

| Variable | Obligatoire | Exemple | Description |
|---|:---:|---|---|
| `GOOGLE_DRIVE_FOLDER_ID` | ❌ | `0AESY4Uy...` | ID du dossier Google Drive pour les exports |

---

## Fichier `.env` racine

Le fichier `.env` à la racine du projet contient uniquement deux variables utilisées par Docker Compose :

```env
COMPOSE_BAKE=true
DOMAIN=koda.insuco.net
```

| Variable | Description |
|---|---|
| `COMPOSE_BAKE` | Active le mode bake de Docker Compose (builds optimisés) |
| `DOMAIN` | Domaine utilisé dans la configuration Nginx |
