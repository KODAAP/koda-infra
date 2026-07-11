# Gérer les permissions et accès aux formulaires

Ce guide explique comment contrôler l'accès aux formulaires et aux données par utilisateur et par projet.

## Modèle de permissions

Sycosur utilise un modèle hiérarchique à trois niveaux :

```
Plateforme
└── Projet
    └── Formulaire (Survey)
        └── Soumissions
```

Les permissions sont héritées du niveau supérieur mais peuvent être restreintes au niveau inférieur.

---

## Matrice des permissions par rôle

| Action | Administrateur | Project Manager | User |
|---|:---:|:---:|:---:|
| Créer un projet | ✅ | ❌ | ❌ |
| Supprimer un projet | ✅ | ❌ | ❌ |
| Inviter des utilisateurs (plateforme) | ✅ | ❌ | ❌ |
| Inviter des utilisateurs (projet) | ✅ | ✅ | ❌ |
| Changer les rôles projet | ✅ | ✅ | ❌ |
| Importer un formulaire | ✅ | ✅ | ❌ |
| Supprimer un formulaire | ✅ | ✅ | ❌ |
| Consulter les soumissions | ✅ | ✅ | ✅ |
| Exporter les données | ✅ | ✅ | ✅ |
| Accéder à la vue carte | ✅ | ✅ | ✅ |
| Révoquer des accès | ✅ | ✅ (projet) | ❌ |

---

## Configurer l'accès aux formulaires (Form Access)

La page **Form Access** (anciennement "Form Access Matrix") permet de gérer finement qui a accès à quels formulaires dans un projet.

### Accéder à Form Access

1. Allez dans **Projets** → sélectionnez votre projet
2. Cliquez sur **Form Access** dans le menu du projet

### Assigner un utilisateur à un formulaire

1. Dans la matrice, localisez l'utilisateur (ligne) et le formulaire (colonne)
2. Cochez la case pour donner accès
3. L'accès est effectif immédiatement

### Retirer l'accès à un formulaire

1. Décochez la case correspondante dans la matrice
2. L'utilisateur ne voit plus ce formulaire dans son interface

---

## Gérer les rôles au niveau projet

### Promouvoir un User en Project Manager

1. Dans **Form Access**, cliquez sur le menu contextuel de l'utilisateur
2. Sélectionnez **Changer le rôle** → **Project Manager**
3. L'utilisateur peut désormais gérer les enquêtes et inviter d'autres utilisateurs

### Rétrograder un PM en User

Même procédure, sélectionnez **User** dans le menu de changement de rôle.

---

## Alertes et notifications automatiques

Sycosur génère des alertes visuelles et des notifications dans les cas suivants :

| Situation | Alerte | Destinataire |
|---|---|---|
| Projet sans Project Manager actif | Bandeau orange sur le projet | Administrateurs |
| Projet archivé | Indicateur visuel sur la carte projet | Tous les utilisateurs |
| Email `@insuco.com` révoqué | Notification email | Administrateurs |
| Utilisateur externe supprimé | Notification email | Administrateurs |

---

## Permissions ODK Central

Sycosur synchronise les permissions avec ODK Central via son API. Chaque utilisateur Sycosur ayant accès à un formulaire est automatiquement configuré comme **App User** dans ODK Central pour ce formulaire.

!!! info "Pool d'utilisateurs ODK"
    Sycosur utilise un pool de comptes administrateurs ODK Central (`ODK_ADMIN_EMAIL`, `ODK_ADMIN_EMAIL2`) pour effectuer les opérations d'administration. Ces comptes ne correspondent pas aux utilisateurs finaux.

---

## Référence complémentaire

- [`backend/docs/permission-guide.md`](../../backend/docs/permission-guide.md) — Guide technique des permissions Django
- [`backend/docs/sys-rights-guide.md`](../../backend/docs/sys-rights-guide.md) — Guide des droits système
- [Explication : Gestion des rôles](../explanation/roles-permissions.md) — Comprendre le modèle de permissions
