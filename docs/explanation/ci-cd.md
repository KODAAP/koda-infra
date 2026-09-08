# Pipeline CI/CD (Intégration et Livraison Continues)

Le projet KODAAP utilise une architecture multi-dépôts (un dépôt racine avec des submodules Git). L'architecture CI/CD a été conçue pour s'adapter à cette structure de manière modulaire, en utilisant GitHub Actions.

## Vue d'ensemble

La stratégie mise en place est la **Livraison Continue** (Option distribuée) :

- **L'Intégration Continue (CI)** (Linting et Tests) est déléguée aux **sous-dépôts** (`back-office` et `koda-client`).
- **La Livraison Continue (CD)** (Build Docker et Push vers le registre) est centralisée dans le **dépôt racine d'infrastructure** (`koda-infra`).

Cela permet aux développeurs d'obtenir un feedback rapide sur leur code sans impacter le déploiement global, tout en conservant un contrôle centralisé sur ce qui est publié.

## Stratégie de Branches

Chaque dépôt suit un cycle de développement basé sur la branche `develop` (ou `main` pour l'infrastructure) :

| Dépôt | Branche de Dev | Branche de Release | Triggers (push / PR) |
|---|---|---|---|
| `koda-infra` | — | `main` | Build Docker + Push GHCR |
| `back-office` | `develop` | `main` | Lint (Ruff) + Tests Django |
| `koda-client` | `develop` | `main` | Lint (Biome) + Build (Next.js) |

### Le flux de travail (Workflow)

1. Un développeur pousse du code ou ouvre une Pull Request vers `develop` sur un sous-dépôt.
2. Le pipeline **CI** du sous-dépôt se déclenche automatiquement pour valider le code.
3. Une fois validée, la branche `develop` est mergée sur `main`.
4. Le submodule est ensuite mis à jour manuellement dans `koda-infra`.
5. Lors du push de cette mise à jour sur la branche `main` de `koda-infra`, le pipeline **CD** se déclenche.
6. Le pipeline CD construit les images Docker de production et les publie sur GitHub Container Registry (GHCR).

## Les Workflows GitHub Actions

### 1. CI Backend (`back-office`)

Fichier : `.github/workflows/ci.yml`

Ce workflow s'assure de la qualité du code Python (Django).
*   **Linting** : Exécuté de manière extrêmement rapide via `ruff`.
*   **Tests** : Lance la suite de tests Django. Le workflow provisionne automatiquement un service de base de données **PostgreSQL** (`postgres:16-alpine`) pour permettre l'exécution des tests dans un environnement réaliste.

### 2. CI Frontend (`koda-client`)

Fichier : `.github/workflows/ci.yml`

Ce workflow s'assure de la qualité du code TypeScript/React (Next.js).
*   **Linting et Formatage** : Géré par `biome` pour une validation stricte.
*   **Build** : Un test de compilation (`pnpm run build`) est effectué pour vérifier qu'aucune erreur TypeScript ou de rendu ne bloquera la production.

### 3. CD Infrastructure (`koda-infra`)

Fichier : `.github/workflows/deploy.yml`

C'est le chef d'orchestre de la livraison.
*   **Checkout Récursif** : Récupère le code du dépôt racine et clone automatiquement les sous-dépôts (nécessite un Personal Access Token configuré en secret).
*   **Build Docker** : Construit les images `koda-api` et `koda-client` en utilisant le cache BuildKit de GitHub pour accélérer considérablement les temps de build.
*   **Push GHCR** : Pousse les images fraîchement construites sur GHCR. Les images sont taguées avec `latest` et avec l'empreinte SHA-1 exacte du commit pour garantir une traçabilité totale et faciliter les rollbacks.

## Sécurité

Pour garantir la reproductibilité et éviter toute faille due à l'injection de code via des dépendances externes corrompues, toutes les actions tierces utilisées dans les pipelines (ex: `actions/checkout`, `docker/login-action`) sont épinglées sur leur **commit SHA** exact au lieu d'utiliser des numéros de version flottants (comme `@v4`).
