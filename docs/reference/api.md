# Référence API REST

Sycosur expose une API REST Django REST Framework. La documentation interactive complète est disponible via Swagger UI.

## Accès à la documentation interactive

| Environnement | URL |
|---|---|
| Développement | `http://localhost:8080/api/schema/swagger-ui/` |
| Production | `https://sycosur.insuco.net/api/schema/swagger-ui/` |

---

## Authentification

Toutes les routes API (sauf login) nécessitent un token JWT dans le header :

```http
Authorization: Bearer <access_token>
```

### Obtenir un token

```http
POST /api/v1/auth/login/
Content-Type: application/json

{
  "email": "user@insuco.com",
  "password": "mot-de-passe"
}
```

**Réponse :**
```json
{
  "access": "eyJ...",
  "refresh": "eyJ..."
}
```

### Rafraîchir un token

```http
POST /api/v1/auth/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ..."
}
```

### Connexion Google OAuth

```http
GET /api/v1/auth/google
```

Redirige vers le flux OAuth Google. Configuré via `GOOGLE_CLIENT_ID` et `REDIRECT_URIS`.

---

## Endpoints principaux

### Utilisateurs

| Méthode | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/users/` | Liste des utilisateurs (Admin) |
| `GET` | `/api/v1/users/me/` | Profil de l'utilisateur connecté |
| `PATCH` | `/api/v1/users/me/` | Mettre à jour son profil |
| `POST` | `/api/v1/users/invite/` | Inviter un utilisateur |
| `POST` | `/api/v1/users/invite/bulk/` | Invitations en masse |
| `DELETE` | `/api/v1/users/{id}/revoke/` | Révoquer l'accès plateforme |

### Invitations

| Méthode | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/invitations/` | Liste des invitations |
| `POST` | `/api/v1/invitations/resend/{id}/` | Renvoyer une invitation |

### Projets

| Méthode | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/projects/` | Liste des projets accessibles |
| `POST` | `/api/v1/projects/` | Créer un projet (Admin) |
| `GET` | `/api/v1/projects/{id}/` | Détail d'un projet |
| `DELETE` | `/api/v1/projects/{id}/` | Supprimer un projet (Admin) |
| `GET` | `/api/v1/projects/{id}/members/` | Membres du projet |

### Enquêtes (Surveys / Formulaires ODK)

| Méthode | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/projects/{id}/surveys/` | Liste des enquêtes du projet |
| `POST` | `/api/v1/projects/{id}/surveys/` | Importer un formulaire XLSForm |
| `GET` | `/api/v1/projects/{id}/surveys/{survey_id}/` | Détail d'une enquête |
| `DELETE` | `/api/v1/projects/{id}/surveys/{survey_id}/` | Supprimer une enquête |
| `GET` | `/api/v1/projects/{id}/surveys/{survey_id}/versions/` | Versions du formulaire |
| `POST` | `/api/v1/projects/{id}/surveys/{survey_id}/update/` | Mettre à jour le formulaire |

### Soumissions

| Méthode | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/projects/{id}/surveys/{survey_id}/submissions/` | Liste des soumissions (OData) |
| `GET` | `/api/v1/projects/{id}/surveys/{survey_id}/submissions/{uuid}/` | Détail d'une soumission |

### Exports

| Méthode | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/projects/{id}/surveys/{survey_id}/exports/excel/` | Lancer un export Excel |
| `POST` | `/api/v1/projects/{id}/surveys/{survey_id}/exports/csv/` | Lancer un export CSV |
| `POST` | `/api/v1/projects/{id}/surveys/{survey_id}/exports/shapefile/` | Lancer un export Shapefile |
| `POST` | `/api/v1/projects/{id}/surveys/{survey_id}/exports/media/` | Lancer un export ZIP médias |
| `GET` | `/api/v1/exports/{task_id}/` | Statut et URL de téléchargement |

### Liens Enketo

| Méthode | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/projects/{id}/surveys/{survey_id}/enketo/single/` | Lien soumission unique |
| `GET` | `/api/v1/projects/{id}/surveys/{survey_id}/enketo/multiple/` | Lien soumissions multiples |

---

## Codes de réponse

| Code | Signification |
|---|---|
| `200` | Succès |
| `201` | Ressource créée |
| `202` | Tâche acceptée (export async) |
| `400` | Données invalides |
| `401` | Non authentifié |
| `403` | Accès refusé |
| `404` | Ressource introuvable |
| `500` | Erreur serveur |

---

## API ODK Central

Sycosur consomme l'API ODK Central en interne. La spécification complète de l'API ODK Central est disponible dans [`docs/api.yaml`](../api.yaml) (OpenAPI 3.0).

Pour consulter la documentation ODK Central :
- [Documentation officielle ODK Central API](https://docs.getodk.org/central-api/)
- Fichier local : `docs/api.yaml` (importable dans Swagger UI ou Postman)
