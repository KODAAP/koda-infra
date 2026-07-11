# Gérer les utilisateurs

Ce guide explique comment inviter, gérer et révoquer les accès des utilisateurs sur la plateforme Sycosur.

## Rôles disponibles

| Rôle | Périmètre | Capacités |
|---|---|---|
| **Administrateur** | Plateforme entière | Tout gérer : utilisateurs, projets, formulaires, suppressions |
| **Project Manager (PM)** | Projet(s) assigné(s) | Gérer les enquêtes, inviter des utilisateurs au projet |
| **User** | Projet(s) assigné(s) | Consulter les données, exporter |

!!! warning "Rôle PM obligatoire"
    Un projet sans Project Manager actif est signalé visuellement par une alerte dans l'interface. Assurez-vous qu'au moins un PM est assigné à chaque projet actif.

---

## Inviter un utilisateur

### Invitation individuelle

1. Allez dans **Utilisateurs** → **Liste des utilisateurs**
2. Cliquez sur **Inviter un utilisateur**
3. Renseignez l'adresse email et le rôle souhaité
4. Cliquez sur **Envoyer l'invitation**

L'utilisateur reçoit un email avec un lien pour définir son mot de passe et activer son compte.

### Invitation en masse

1. Allez dans **Utilisateurs** → **Liste des utilisateurs**
2. Cliquez sur **Invitations en masse**
3. Importez un fichier CSV avec les colonnes `email,role,project_id`
4. Validez et envoyez

---

## Inviter un utilisateur web (sans projet)

Pour les utilisateurs qui ont besoin d'accéder à la plateforme sans être rattachés à un projet spécifique :

1. Allez dans **Utilisateurs** → **Utilisateurs web**
2. Cliquez sur **Inviter un utilisateur web**
3. Renseignez l'email
4. L'utilisateur peut se connecter mais n'a accès à aucun projet tant qu'il n'est pas assigné

---

## Suivre les invitations

1. Allez dans **Utilisateurs** → **Invitations**
2. Filtrez par statut :
   - **En attente** : invitation envoyée, non acceptée
   - **Acceptée** : compte activé
   - **Expirée** : lien expiré, renvoyer si nécessaire
3. Pour renvoyer une invitation expirée, cliquez sur **Renvoyer**

---

## Changer le rôle d'un utilisateur dans un projet

1. Allez dans **Projets** → sélectionnez le projet
2. Accédez à **Form Access** (anciennement "Form Access Matrix")
3. Cliquez sur le menu contextuel de l'utilisateur
4. Sélectionnez **Changer le rôle** → `User` ou `Project Manager`

---

## Révoquer un accès

### Révoquer l'accès à un projet

1. Dans **Form Access** du projet concerné
2. Cliquez sur le menu contextuel de l'utilisateur
3. Sélectionnez **Révoquer l'accès au projet**

### Révoquer l'accès à la plateforme

1. Allez dans **Utilisateurs** → **Liste des utilisateurs**
2. Cliquez sur le menu contextuel de l'utilisateur
3. Sélectionnez **Révoquer l'accès plateforme**

!!! danger "Révocation des emails Insuco"
    Si un email `@insuco.com` est révoqué, les administrateurs reçoivent une notification automatique. Cette action est irréversible sans réinvitation.

---

## Mot de passe oublié

Les utilisateurs peuvent réinitialiser leur mot de passe depuis la page de connexion :

1. Cliquez sur **Mot de passe oublié** sur la page de login
2. Entrez l'adresse email du compte
3. Un email avec un lien de réinitialisation est envoyé
4. Le lien est valable 24 heures

---

## Connexion Google (SSO)

Les utilisateurs peuvent se connecter avec leur compte Google si le SSO est configuré :

- Variables requises : `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `REDIRECT_URIS`
- Le compte Google doit correspondre à l'email d'invitation

---

## Tableau de bord des statistiques utilisateurs

Les administrateurs ont accès au **Dashboard** avec les statistiques en temps réel :

- Nombre total d'utilisateurs (tous / actifs / administrateurs)
- Invitations en cours (en attente / expirées)

Accessible via **Tableau de bord** dans la barre latérale.
