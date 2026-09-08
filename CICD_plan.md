# Plan d'Architecture CI/CD — Option B : CI distribué + CD centralisé

Ce plan décrit la mise en œuvre d'un pipeline CI/CD pour l'architecture **multi-dépôts avec submodules Git** du projet KODAAP.

## Contexte de l'architecture

```
KODAAP/koda-infra    ← Dépôt principal (orchestrateur)
├── backend/         → Submodule : KODAAP/back-office    (Django DRF)
├── client/          → Submodule : KODAAP/koda-client    (Next.js)
├── docker/
├── prod.yml
└── local.yml
```

**Principe (Option B — Livraison Continue uniquement)** :
- La **CI** (Lint + Tests) est définie dans **chaque sous-dépôt** → feedback immédiat pour les développeurs sur leurs PRs.
- La **CD** (Livraison Continue : Build Docker + Push sur GHCR) est centralisée dans **`koda-infra`** → les images sont générées et prêtes à être déployées, mais le déploiement sur le VPS n'est pas géré automatiquement.

---

## Stratégie Git & Triggers

### Structure des branches (par dépôt)

| Dépôt | Branche de développement | Branche de production | Branches de travail |
|---|---|---|---|
| `koda-infra` | — | `main` | `feature/*` |
| `back-office` | **`develop`** | `main` | `feature/*`, `bugfix/*` |
| `koda-client` | **`develop`** | `main` | `feature/*`, `bugfix/*` |

> La branche `develop` des sous-dépôts est la branche de travail principale. Après validation, un merge vers `main` est effectué manuellement avant la mise à jour du submodule dans `koda-infra`.

### Flux de déclenchement

```mermaid
graph TD
    Dev[Développeur travaille sur la branche develop]
    Dev -->|push sur develop ou PR vers develop| CI_Dev[✅ CI: Lint + Tests sur develop]
    CI_Dev -->|Validation OK| MergeDev[Merge develop → main du sous-dépôt]
    MergeDev -->|push sur main| CI_Main[✅ CI: Lint + Tests sur main]
    CI_Main -->|Mise à jour manuelle du submodule| InfraUpdate[Commit dans koda-infra]
    InfraUpdate -->|Push sur main de koda-infra| CD[🚀 Pipeline CD: Build Docker + Push GHCR]
```

### Récapitulatif des triggers CI par branche

| Branche | `back-office` CI | `koda-client` CI | `koda-infra` CD |
|---|:---:|:---:|:---:|
| `develop` (push / PR) | ✅ Lint + Tests | ✅ Lint + Build | ❌ |
| `main` (push / PR) | ✅ Lint + Tests | ✅ Lint + Build | ❌ |
| `main` de `koda-infra` | — | — | ✅ Build + Push GHCR |

> **Point clé** : La livraison (build d'images Docker) est déclenchée depuis `koda-infra/main`. La branche `develop` des sous-dépôts n'interagit jamais avec ce processus. Le déploiement effectif sur le serveur n'est pas automatisé ici.

---

## Fichiers à créer

### Dépôt `KODAAP/back-office`

#### [NEW] `.github/workflows/ci.yml`

```yaml
name: CI — Backend (Django)

on:
  push:
    branches: [ main, develop ]   # CI sur les deux branches
  pull_request:
    branches: [ main, develop ]   # CI sur les PRs vers develop ET main

jobs:
  lint:
    name: Lint (Ruff)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

      - uses: actions/setup-python@0b93645e5fea732b7c7b5b5463f20b32f143d46a # v5.3.0
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Install Ruff
        run: pip install ruff

      - name: Lint & Format check
        run: |
          ruff check .
          ruff format --check .

  test:
    name: Tests Django
    runs-on: ubuntu-latest
    services:
      db:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: test_kodaap
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_pass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

      - uses: actions/setup-python@0b93645e5fea732b7c7b5b5463f20b32f143d46a # v5.3.0
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Install dependencies
        run: |
          pip install --upgrade pip
          # Utilise requirements/local.txt s'il existe, sinon requirements.txt
          if [ -f requirements/local.txt ]; then
            pip install -r requirements/local.txt
          else
            pip install -r requirements.txt
          fi

      - name: Run tests
        env:
          DJANGO_SETTINGS_MODULE: config.settings.test
          DATABASE_URL: postgres://test_user:test_pass@localhost:5432/test_kodaap
        run: python manage.py test --verbosity=2
```

---

### Dépôt `KODAAP/koda-client`

#### [NEW] `.github/workflows/ci.yml`

```yaml
name: CI — Frontend (Next.js)

on:
  push:
    branches: [ main, develop ]   # CI sur les deux branches
  pull_request:
    branches: [ main, develop ]   # CI sur les PRs vers develop ET main

jobs:
  lint:
    name: Lint (Biome)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

      - uses: pnpm/action-setup@fe02b34f77f8bc703788d5817da081398fad5dd2 # v4.0.0
        with:
          version: 10.28.0

      - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af # v4.1.0
        with:
          node-version: '20'
          cache: 'pnpm'
          cache-dependency-path: 'pnpm-lock.yaml'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Lint & Format check
        run: |
          pnpm run lint
          pnpm run format

  build-check:
    name: Build Validation
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

      - uses: pnpm/action-setup@fe02b34f77f8bc703788d5817da081398fad5dd2 # v4.0.0
        with:
          version: 10.28.0

      - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af # v4.1.0
        with:
          node-version: '20'
          cache: 'pnpm'
          cache-dependency-path: 'pnpm-lock.yaml'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build Next.js
        env:
          NEXT_TELEMETRY_DISABLED: 1
        run: pnpm run build
```

---

### Dépôt `KODAAP/koda-infra`

#### [NEW/MODIFY] `.github/workflows/deploy.yml`

```yaml
name: CD — Livraison Continue

on:
  push:
    branches: [ main ]
  # Permettre de relancer un build manuellement
  workflow_dispatch:

permissions:
  contents: read
  packages: write

jobs:
  build-push-docker:
    name: Build & Push Docker Images
    runs-on: ubuntu-latest
    steps:
      - name: Checkout koda-infra avec submodules
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
        with:
          submodules: recursive
          # Un PAT avec accès en lecture aux 3 dépôts est nécessaire
          token: ${{ secrets.GH_PAT }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@6524bf65af31da8d45b59e8c27de4bd072b392f5 # v3.8.0

      - name: Log in to GHCR
        uses: docker/login-action@9780b0c442fbb1117ed29e0efdff1e18412f7567 # v3.3.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Métadonnées image Backend
        id: meta-backend
        uses: docker/metadata-action@8e5d50cd915cb4b08eb5047b3be5d8628b030b20 # v5.6.1
        with:
          images: ghcr.io/${{ github.repository_owner }}/koda-api
          tags: |
            type=sha,prefix=sha-,format=short
            type=raw,value=latest

      - name: Métadonnées image Frontend
        id: meta-frontend
        uses: docker/metadata-action@8e5d50cd915cb4b08eb5047b3be5d8628b030b20 # v5.6.1
        with:
          images: ghcr.io/${{ github.repository_owner }}/koda-client
          tags: |
            type=sha,prefix=sha-,format=short
            type=raw,value=latest

      - name: Build & Push image Backend
        uses: docker/build-push-action@3b5e8027fcad23fda98b2e3ac259d8d67585f671 # v5.0.0
        with:
          context: .
          file: ./docker/prod/django/Dockerfile
          push: true
          tags: ${{ steps.meta-backend.outputs.tags }}
          labels: ${{ steps.meta-backend.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Build & Push image Frontend
        uses: docker/build-push-action@3b5e8027fcad23fda98b2e3ac259d8d67585f671 # v5.0.0
        with:
          context: .
          file: ./docker/prod/client/Dockerfile
          push: true
          tags: ${{ steps.meta-frontend.outputs.tags }}
          labels: ${{ steps.meta-frontend.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## Gestion des Secrets

### Secrets à configurer par dépôt

| Secret | `back-office` | `koda-client` | `koda-infra` | Description |
|---|:---:|:---:|:---:|---|
| *(aucun)* | — | — | — | Les CI sous-dépôts n'ont pas besoin de secrets |
| `GH_PAT` | — | — | ✅ | Personal Access Token — lecture des 3 dépôts pour checkout avec submodules |

> [!IMPORTANT]
> **Créer un `GH_PAT` avec les scopes** : `repo` (lecture seule sur les 3 dépôts) + `read:packages`. Ce token est nécessaire pour que `actions/checkout` puisse cloner les submodules privés `back-office` et `koda-client` lors du build dans `koda-infra`.

---

## Flux de travail complet (Dev → Prod)

```mermaid
sequenceDiagram
    participant Dev as Développeur
    participant SubRepo as back-office / koda-client
    participant Infra as koda-infra
    participant GHCR as GitHub Container Registry

    Dev->>SubRepo: git push feature/ma-feature
    Dev->>SubRepo: Ouvre une Pull Request
    SubRepo->>SubRepo: 🔄 CI : Lint + Tests (automatique)
    SubRepo->>Dev: ✅ ou ❌ Résultat CI
    Dev->>SubRepo: Merge PR sur develop
    Dev->>SubRepo: Merge develop sur main (après review)
    Note over Dev,Infra: Mise à jour manuelle du submodule
    Dev->>Infra: cd backend && git pull origin main
    Dev->>Infra: cd .. && git add backend && git commit -m "chore: update backend submodule"
    Dev->>Infra: git push origin main
    Infra->>Infra: 🔄 CD : Build Docker + Push GHCR
    Infra->>GHCR: 🚀 Publication des images
    GHCR->>Dev: ✅ Images prêtes pour le déploiement
```

---

## Open Questions

> [!NOTE]
> 1. **Settings Django pour les tests** : Le job `test` utilise `config.settings.test`. Existe-t-il un tel fichier de settings dans `back-office` ? Sinon, il faut utiliser `config.settings.local` avec les variables d'environnement de la base de test injectées dans le workflow.
> 2. **Mise à jour des submodules** : La mise à jour du submodule dans `koda-infra` est-elle faite manuellement par un dev ou souhaitez-vous l'automatiser via un `repository_dispatch` depuis `back-office`/`koda-client` ?

---

## Proposed Changes

### Dépôt `KODAAP/back-office`

#### [NEW] `.github/workflows/ci.yml`
Pipeline CI avec Lint (Ruff) + Tests Django + service PostgreSQL intégré.

---

### Dépôt `KODAAP/koda-client`

#### [NEW] `.github/workflows/ci.yml`
Pipeline CI avec Lint (Biome) + Build validation Next.js.

---

### Dépôt `KODAAP/koda-infra`

#### [NEW] `.github/workflows/deploy.yml`
Pipeline de Livraison Continue avec :
- Checkout récursif des submodules via PAT
- Build + Push des 2 images Docker vers GHCR (avec cache BuildKit)

---

## Verification Plan

### Étapes de validation recommandées

1. **Test CI sous-dépôts** :
   - Ouvrir une PR de test sur `back-office` ciblant `develop` → vérifier que le job Lint + Tests se déclenche.
   - Ouvrir une PR de test sur `koda-client` ciblant `develop` → vérifier que le job Lint + Build se déclenche.

2. **Test Livraison Continue `koda-infra`** :
   - Configurer le secret `GH_PAT` dans `koda-infra` (`Settings → Secrets → Actions`).
   - Faire un commit sur `main` de `koda-infra` et vérifier que les images Docker sont bien construites et poussées sur le registre GHCR.
