# Gestion des Secrets, Variables et Workflows GitHub Actions

Ce document explique comment gérer efficacement les secrets et les variables d'environnement pour vos workflows GitHub Actions, en particulier dans un contexte de meta-repo et d'organisation.

---

## 1. Gestion en Masse des Secrets et Variables (Bulk Insert)

L'utilisation de la CLI GitHub (`gh`) permet de configurer rapidement de nombreux secrets ou variables à partir d'un fichier local (souvent de type `.env`).

### Utilisation de la CLI GitHub (`gh`)

Assurez-vous d'être connecté au bon compte GitHub avant de commencer :
```bash
gh auth status
# Si besoin de se connecter :
gh auth login
```

### Importation des Secrets
Pour importer tous les secrets à partir d'un fichier `.env.prod` vers le dépôt GitHub courant :
```bash
gh secret set --env-file .env.prod
```

### Importation des Variables
Pour importer toutes les variables non sensibles (Repository Variables) :
```bash
gh variable set --env-file .env.prod_vars
```

### Options Utiles
*   **`--repo owner/repo`** : Spécifie le dépôt si vous n'êtes pas dans le répertoire local du projet.
*   **`--env production`** : Cible un environnement GitHub spécifique (ex: production, staging).
*   **`--org my-org`** : Définit les secrets au niveau de l'organisation (nécessite des droits d'administrateur d'organisation).

---

## 2. Contexte d'Organisation et Permissions

Dans le cas d'un dépôt appartenant à une **organisation**, les principes suivants s'appliquent :

*   **Dépôt Meta-repo** : Pour votre architecture, les secrets et variables doivent être créés dans le **dépôt parent (meta-repo)**. C'est lui qui orchestre le déploiement de tous les sous-modules (backend, client).
*   **Permissions** : Vous devez disposer au minimum du rôle **Maintainer** ou **Admin** sur le dépôt spécifique pour pouvoir gérer ses secrets et variables via la CLI ou l'interface web.
*   **Visibilité** : Les secrets de dépôt ne sont accessibles qu'aux workflows s'exécutant sur ce dépôt précis.

---

## 3. Comprendre la Branche de Déploiement

GitHub Actions fournit des variables de contexte pour identifier précisément quelle version du code a déclenché le workflow.

### Variables de Contexte Clés
*   **`github.ref`** : La référence Git complète (ex: `refs/heads/main`).
*   **`github.ref_name`** : Le nom court de la branche ou du tag (ex: `main` ou `v1.2.3`).
*   **`github.sha`** : L'ID unique (hash) du commit exact qui a déclenché le workflow.

### Déploiement Automatique vs Manuel
*   **Automatique (`on: push`)** : Le workflow se lance sur le commit qui a été "pushé". `github.ref_name` correspondra à la branche cible (ex: `main`).
*   **Manuel (`on: workflow_dispatch`)** : L'utilisateur choisit la branche ou le tag au moment du lancement. Cette valeur devient `github.ref_name`.

### Option : Choix de l'Environnement (Workflow Dispatch)
Pour permettre à l'utilisateur de choisir explicitement l'environnement cible (ex: `production`, `staging`) lors d'un lancement manuel, vous pouvez configurer des `inputs` :

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environnement cible'
        required: true
        default: 'production'
        type: choice
        options:
          - production
          - staging

jobs:
  deploy:
    # Utilisation de l'input choisi pour définir l'environnement GitHub (GitHub Environments)
    environment: ${{ github.event.inputs.environment }}
    runs-on: ubuntu-latest
    steps:
      - name: Log Target Environment
        run: echo "Déploiement en cours vers l'environnement : ${{ github.event.inputs.environment }}"
```

### Vérification dans les Logs
Vous pouvez ajouter cette étape à vos workflows pour confirmer la version déployée :
```yaml
- name: Log Deployment Context
  run: |
    echo "Déploiement de la branche : ${{ github.ref_name }}"
    echo "Hash du commit : ${{ github.sha }}"
```

L'action `actions/checkout@v4` (avec `submodules: 'recursive'`) se chargera automatiquement de récupérer la version du code correspondant à ce contexte.
