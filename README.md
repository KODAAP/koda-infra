# Koda Infrastructure (koda-infra)

Dépôt d'infrastructure et d'orchestration Docker pour la plateforme Koda (backend Django, client Next.js, bases de données et services asynchrones).

---

## 🏗️ Architecture & Composants

Ce projet regroupe les sous-modules applicatifs et orchestre les services :

- **Backend API (`api`)** : Django (Python) / Gunicorn (prod)
- **Frontend Client (`client`)** : Next.js (Node.js 20, pnpm)
- **Base de données (`postgres`)** : PostgreSQL 16
- **Cache & Broker (`redis`)** : Redis 7
- **Tâches asynchrones** :
  - `celeryworker` : Worker Celery pour le traitement asynchrone
  - `celerybeat` : Scheduler périodique Celery Beat
  - `flower` : Dashboard de monitoring Celery (en local)
- **Reverse Proxy / Serveur Web** :
  - Local : Nginx (`docker/local/nginx`)
  - Production : Réseau partagé `reverseProxy_nw` (Traefik / Nginx externe)
- **Serveur de messagerie (Local)** : Mailpit (Webmail & SMTP de test)

---

## 📁 Structure du Répertoire

```text
├── backend/                  # Sous-module Git : API Django (back-office)
├── client/                   # Sous-module Git : Application Next.js (koda-client)
├── docker/
│   ├── local/                # Dockerfiles et scripts d'environnement de développement
│   │   ├── client/
│   │   ├── django/
│   │   ├── nginx/
│   │   └── postgres/
│   └── prod/                 # Dockerfiles multi-stage et scripts de production
│       ├── client/
│       └── django/
├── docs/                     # Documentation technique (MkDocs Material)
├── .github/workflows/        # Pipelines CI/CD GitHub Actions
│   ├── deploy.yml            # Build, scan Dockle, push GHCR et déploiement SSH VM
│   ├── hadolint.yml          # Linting des Dockerfiles
│   └── docs.yml              # Déploiement GitHub Pages de la documentation
├── local.yml                 # Orchestration Docker Compose pour le développement
├── prod.yml                  # Orchestration Docker Compose pour la production
└── Makefile                  # Commandes raccourcies pour l'administration locale
```

---

## 🚀 Démarrage Rapide (Développement)

### Prérequis

- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/)
- [Make](https://www.gnu.org/software/make/) (optionnel, recommandé)
- [Git](https://git-scm.com/)

### 1. Cloner le projet avec les sous-modules

```bash
git clone --recurse-submodules git@github.com:KODAAP/koda-infra.git
cd koda-infra
```

Si le dépôt est déjà cloné :
```bash
git submodule update --init --recursive
```

### 2. Variables d'environnement

Assurez-vous de disposer des fichiers d'environnement nécessaires pour le développement :
- `.env` à la racine
- `backend/.envs/.env.local`

### 3. Lancer les services

Utilisez le `Makefile` ou les commandes docker compose directes :

```bash
# Préparer les dossiers nécessaires
make prepare

# Construire et démarrer les conteneurs
make build
# ou
make dev
```

### Services accessibles en local :

- **Frontend** : [http://localhost:3000](http://localhost:3000)
- **Backend API** : [http://localhost:8001](http://localhost:8001)
- **Mailpit (Web UI)** : [http://localhost:8025](http://localhost:8025)
- **Flower (Monitoring Celery)** : [http://localhost:5555](http://localhost:5555)
- **PostgreSQL** : `localhost:5432`

---

## 🛠️ Commandes Utiles (Makefile)

| Commande | Action |
| --- | --- |
| `make up` | Démarrer les services en arrière-plan |
| `make down` | Arrêter les conteneurs |
| `make down-v` | Arrêter et supprimer les volumes |
| `make show-logs` | Afficher les logs de tous les conteneurs |
| `make show-logs-api` | Suivre les logs du service API |
| `make makemigrations` | Créer les nouvelles migrations Django |
| `make migrate` | Appliquer les migrations |
| `make superuser` | Créer un super-utilisateur Django |
| `make koda-db` | Ouvrir un shell PostgreSQL (`psql`) |

---

## 🚢 CI/CD & Déploiement

Le workflow GitHub Actions ([.github/workflows/deploy.yml](file:///.github/workflows/deploy.yml)) prend en charge :

1. **Build & Cache** des images Docker via Docker Buildx.
2. **Push sur GitHub Container Registry (GHCR)** :
   - `ghcr.io/kodaap/koda-api`
   - `ghcr.io/kodaap/koda-client`
3. **Audit de sécurité** : Scan des vulnérabilités et bonnes pratiques avec `Dockle` (export SARIF).
4. **Déploiement Continu (CD)** via SSH sur la machine cible :
   - Mise à jour du fichier `prod.yml` sur le serveur
   - Pull des images GHCR avec tag SHA
   - Redémarrage sans interruption des conteneurs
   - Exécution des migrations Django et de `collectstatic`
   - Nettoyage automatique des anciennes images Docker