# Configurer Enketo

Ce guide explique comment configurer et intégrer le serveur Enketo Express avec Koda pour la collecte via formulaires web.

## Qu'est-ce qu'Enketo ?

[Enketo](https://enketo.org/) est un moteur de rendu de formulaires ODK XForms dans le navigateur. Il permet aux enquêteurs de remplir des formulaires directement depuis un navigateur web, sans application mobile.

Koda utilise **Enketo Express 7.6.1** déployé comme service Docker.

---

## Configuration locale (développement)

Le fichier de configuration Enketo se trouve dans :

```
docker/local/enketo/config.json
```

### Variables d'environnement requises

Dans `backend/.envs/.env.local` :

```env
ENKETO_API_URL=http://enketo:8005/-/api/v2
ENKETO_API_KEY=votre-clé-api-enketo
ENKETO_PUBLIC_BASE_URL=http://localhost:8080
```

| Variable | Description |
|---|---|
| `ENKETO_API_URL` | URL interne de l'API Enketo (réseau Docker) |
| `ENKETO_API_KEY` | Clé d'authentification pour l'API Enketo |
| `ENKETO_PUBLIC_BASE_URL` | URL publique utilisée dans les liens de formulaires |

---

## Configuration production

En production, Enketo doit être accessible via le domaine public pour que les enquêteurs puissent accéder aux formulaires.

```env
ENKETO_API_URL=http://enketo:8005/-/api/v2
ENKETO_API_KEY=clé-longue-et-aléatoire
ENKETO_PUBLIC_BASE_URL=https://koda.insuco.net
```

!!! warning "ENKETO_PUBLIC_BASE_URL"
    Cette variable doit correspondre à l'URL publique de votre instance Koda. Les liens de formulaires générés utilisent cette base URL. Une mauvaise configuration rend les formulaires inaccessibles aux enquêteurs.

---

## Générer une clé API Enketo

La clé API Enketo est définie dans `docker/local/enketo/config.json` :

```json
{
  "api key": "votre-clé-api",
  "linked form and data server": {
    "name": "ODK Central",
    "api key": "votre-clé-api"
  }
}
```

La clé doit être identique dans `config.json` et dans la variable `ENKETO_API_KEY`.

Pour générer une clé aléatoire sécurisée :

```bash
python -c "import secrets; print(secrets.token_urlsafe(64))"
```

---

## Types de liens Enketo générés

Koda génère automatiquement deux types de liens pour chaque formulaire publié :

| Type | Description | Usage |
|---|---|---|
| **Soumission unique** | L'enquêteur ne peut soumettre qu'une seule fois | Enquêtes individuelles |
| **Soumissions multiples** | L'enquêteur peut soumettre plusieurs fois | Collecte répétée |

Ces liens sont visibles dans le **Survey Dashboard** → section **Web Forms**.

---

## Vérifier que Enketo fonctionne

```bash
# Vérifier que le conteneur est UP
docker compose -f local.yml ps enketo

# Tester l'API Enketo directement
curl -X GET http://localhost:8005/api/v2/survey \
  -u "votre-clé-api:"

# Consulter les logs Enketo
docker compose -f local.yml logs enketo -f
```

---

## Problèmes courants

??? failure "Les formulaires Enketo ne s'affichent pas"
    Vérifiez que `ENKETO_PUBLIC_BASE_URL` correspond exactement à l'URL depuis laquelle les enquêteurs accèdent à Koda (avec ou sans `https://`, sans slash final).

??? failure "Erreur 401 lors de la génération des liens"
    La clé API dans `.env.local` ne correspond pas à celle dans `config.json`. Vérifiez les deux fichiers et redémarrez le conteneur Enketo.

??? failure "Le conteneur Enketo ne démarre pas"
    Vérifiez que Redis est démarré avant Enketo (Enketo dépend de Redis pour le cache des formulaires) :
    ```bash
    docker compose -f local.yml up redis enketo
    ```

---

## Documentation complémentaire

- [ENKETO_AUTH_OODA.md](../ENKETO_AUTH_OODA.md) — Authentification ODK-ODA avec Enketo
- [ENKETO_BASIC_SCHEMA.md](../ENKETO_BASIC_SCHEMA.md) — Schéma de base de la configuration Enketo
- [Documentation officielle Enketo](https://enketo.org/develop/)
