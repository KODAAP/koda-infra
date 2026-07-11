# Architecture de Sycosur

## Vue d'ensemble

Sycosur est une application web full-stack organisée en microservices Docker. Elle s'appuie sur ODK Central comme serveur de collecte de données et expose une interface de supervision et d'export enrichie.

---

## Schéma d'architecture

```mermaid
graph TB
    subgraph Internet
        U[Utilisateur navigateur]
        E[Enquêteur terrain]
    end

    subgraph Docker ["Docker Compose (sycosur_network)"]
        N[Nginx :8080]
        C[Next.js :3000]
        A[Django API :8001]
        W[Celery Worker]
        EK[Enketo :8005]
        PG[(PostgreSQL :5432)]
        R[(Redis :6379)]
        FL[Flower :5555]
    end

    subgraph Externe
        ODK[ODK Central]
        GD[Google Drive]
        GM[Gmail / SMTP]
    end

    U --> N
    E --> EK
    N --> C
    N --> A
    N --> EK
    A --> PG
    A --> R
    A --> ODK
    W --> R
    W --> ODK
    W --> GD
    A --> GM
    FL --> R
```

---

## Services Docker

| Service | Image | Rôle | Port exposé |
|---|---|---|---|
| `nginx` | Custom (local/prod) | Reverse proxy, fichiers statiques | `8080` |
| `api` | `sycosur_api` | Backend Django REST | `8001` (interne) |
| `client` | `sycosur_client` | Frontend Next.js | `3000` (interne) |
| `postgres` | Custom PostgreSQL | Base de données relationnelle | `5432` |
| `redis` | `redis:7.0-alpine` | Broker Celery + cache | interne |
| `celeryworker` | `sycosur_celeryworker` | Traitement async des exports | — |
| `enketo` | `ghcr.io/enketo/enketo:7.6.1` | Formulaires web ODK | `8005` (interne) |
| `flower` | `sycosur_flower` | Monitoring Celery | `5555` |
| `mailpit` | `axllent/mailpit:v1.15` | Serveur mail (dev uniquement) | `8025`, `1025` |

---

## Structure du dépôt

```
sycosur/
├── backend/                    # Application Django
│   ├── config/                 # Configuration Django (settings, urls, celery)
│   │   ├── settings/
│   │   │   ├── base.py
│   │   │   ├── local.py
│   │   │   └── production.py
│   │   ├── celery_app.py
│   │   └── urls.py
│   ├── core_apps/              # Applications Django métier
│   │   ├── common/             # Modèles et utilitaires partagés
│   │   ├── invitations/        # Gestion des invitations email
│   │   ├── odk/                # Intégration ODK Central (cœur du système)
│   │   │   └── services/       # Services métier (submissions, exports, SIG)
│   │   ├── profiles/           # Profils utilisateurs
│   │   ├── projects/           # Gestion des projets
│   │   └── users/              # Authentification et gestion des comptes
│   ├── docs/                   # Documentation technique backend
│   └── .envs/                  # Variables d'environnement (non versionnées)
│
├── client/                     # Application Next.js
│   ├── app/                    # Pages (App Router Next.js 15)
│   ├── components/             # Composants React
│   │   ├── maps/               # Carte interactive (soumissions géolocalisées)
│   │   ├── lists/              # Tableaux de données (soumissions, formulaires)
│   │   └── ...
│   ├── lib/
│   │   └── redux/              # State management (Redux Toolkit)
│   │       └── features/
│   │           ├── surveys/    # API slice enquêtes
│   │           └── api/        # Base API slice
│   └── messages/               # Traductions i18n (fr, es)
│
├── docs/                       # Documentation (ce dossier)
├── docker/                     # Configurations Docker spécifiques
├── scripts/                    # Scripts utilitaires
├── local.yml                   # Docker Compose développement
├── prod.yml                    # Docker Compose production
└── Makefile                    # Commandes raccourcies
```

---

## Flux de données principal

### Collecte d'une soumission

```mermaid
sequenceDiagram
    participant E as Enquêteur
    participant EK as Enketo
    participant ODK as ODK Central
    participant A as Django API
    participant PG as PostgreSQL

    E->>EK: Remplit le formulaire web
    EK->>ODK: Soumet les données (OpenRosa)
    ODK->>ODK: Stocke la soumission
    A->>ODK: Synchronise via API OData
    A->>PG: Met à jour les métadonnées locales
```

### Export asynchrone

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant A as Django API
    participant R as Redis
    participant W as Celery Worker
    participant ODK as ODK Central

    U->>A: POST /api/exports/
    A->>R: Enqueue tâche
    A->>U: 202 Accepted (task_id)
    W->>R: Dépile la tâche
    W->>ODK: GET /submissions (OData)
    W->>W: Traitement (pandas/fiona)
    W->>A: Fichier sauvegardé (media/)
    U->>A: GET /api/exports/{task_id}/
    A->>U: URL de téléchargement
```

---

## Stack technique détaillée

### Backend

| Composant | Technologie | Version |
|---|---|---|
| Framework web | Django | 5.x |
| API REST | Django REST Framework | 3.x |
| Tâches async | Celery | 5.x |
| ORM | Django ORM + PostgreSQL | — |
| Auth | JWT (SimpleJWT) + Google OAuth | — |
| Export tabulaire | pandas, openpyxl | — |
| Export SIG | Fiona, GeoPandas, Shapely | — |
| Client ODK | Requêtes HTTP (httpx/requests) | — |

### Frontend

| Composant | Technologie | Version |
|---|---|---|
| Framework | Next.js (App Router) | 15.x |
| Langage | TypeScript | 5.x |
| State management | Redux Toolkit + RTK Query | — |
| UI | Tailwind CSS + shadcn/ui | — |
| Carte | Leaflet / MapLibre | — |
| i18n | next-intl | — |
| Internationalisation | Français, Espagnol | — |

---

## Sécurité

- **Authentification** : JWT avec refresh token + SSO Google OAuth2
- **HTTPS** : Obligatoire en production (`COOKIE_SECURE=True`)
- **Admin Django** : URL secrète configurable (`DJANGO_ADMIN_URL`)
- **Secrets** : Variables d'environnement, jamais dans le code
- **ODK SSL** : `ODK_VERIFY_SSL=True` en production
