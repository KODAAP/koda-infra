# Flux d'Information Enketo ↔ ODK Central : Analyse OODA

Ce document présente une analyse comparative des flux d'authentification Enketo via la méthodologie **OODA** (Observe, Orient, Decide, Act).

---

## 1. Type : `cookie` (Authentification Externe)

### **Contexte**
Utilisé par défaut dans les configurations ODK Central. Repose sur le partage d'un cookie de session.

### **Flux OODA**
1. **Observe (Enketo)** : Reçoit une requête de formulaire. Tente un fetch vers Central. Reçoit un **401 Unauthorized**.
2. **Orient (Enketo)** : Identifie que l'utilisateur n'est pas authentifié. Sait qu'il doit rediriger vers l'URL de login de Central.
3. **Decide (Enketo)** : Génère une redirection 302 vers `https://central.domain/login?return={URL_ENKETO}`.
4. **Act (Système)** : 
   - L'utilisateur se connecte sur Central.
   - Central définit un cookie `__Host-session`.
   - Central redirige vers Enketo.

### **⚠️ Problème avec ngrok (Cross-Domain)**
- **Observe** : Le navigateur refuse de transmettre le cookie de Central à Enketo car les domaines sont différents (`ngrok.io` vs `insuco.net`).
- **Résultat** : Enketo reste en **401** → Boucle infinie de redirections.

---

## 2. Type : `basic` (Authentification Native)

### **Contexte**
Méthode standard OpenRosa. L'utilisateur saisit ses identifiants directement dans le navigateur.

### **Flux OODA**
1. **Observe (Enketo)** : Tente de fetch le formulaire sur Central. Reçoit un **401**.
2. **Orient (Enketo)** : Détecte qu'il doit demander des credentials Basic.
3. **Decide (Enketo)** : Envoie un challenge `WWW-Authenticate: Basic` au navigateur (ou affiche son propre formulaire).
4. **Act (Utilisateur/Navigateur)** : 
   - L'utilisateur saisit `email` et `password`.
   - Le navigateur envoie le header `Authorization: Basic base64(...)`.
   - Enketo relaie ce header à Central.

### **✅ Avantage**
- Fonctionne en **cross-domain** (ngrok OK).
- Le navigateur mémorise les identifiants pour la session.

---

## 3. Type : `token` (External Token)

### **Contexte**
Prévu pour les intégrations où un token est passé directement dans l'URL.

### **Flux OODA**
1. **Observe (Enketo)** : Reçoit une requête. Cherche le paramètre de token (ex: `?st=...`) dans l'URL.
2. **Orient (Enketo)** : Si absent, redirige vers le login central pour obtenir ce token.
3. **Decide (Enketo)** : Attend un retour avec le token injecté.
4. **Act (Système)** : Central doit être capable de rediriger vers Enketo en ajoutant le token dans l'URL.

### **❌ Limitation**
- ODK Central standard **ne supporte pas** nativement l'injection de token dans le redirect URL après login (il utilise uniquement les cookies).

---

## 4. Type : `Proxy Django` (Solution Recommandée)

### **Contexte**
Django agit comme un pont (Gateway) entre Enketo et ODK Central.

### **Flux OODA**
1. **Observe (Enketo)** : Parle au `server_url` pointant vers Django (`/api/v1/odk/odk-proxy`).
2. **Orient (Django Proxy)** : Intercepte la requête d'Enketo. Récupère le token de session de l'utilisateur (déjà connecté à Django).
3. **Decide (Django Proxy)** : Injecte le header `Authorization: Bearer [TOKEN]` et relaie la requête à ODK Central.
4. **Act (Système)** : Central valide le token, renvoie le XML à Django, qui le renvoie à Enketo.

### **🚀 Avantages**
- **Zéro Prompt** : L'utilisateur n'a jamais à se reconnecter à ODK.
- **Sécurité** : Les tokens ne sont pas exposés côté client.
- **Transparence** : Résout tous les problèmes de cross-domain.

---

## Synthèse Comparative

| Critère | Cookie | Basic | Proxy Django |
| :--- | :--- | :--- | :--- |
| **UX** | Redirection Central | Popup Navigateur | **Transparent (Zéro clic)** |
| **Compatibilité ngrok** | ❌ Non | ✅ Oui | ✅ Oui |
| **Double Connexion** | Oui | Oui | **Non** |
| **Sécurité** | Haute | Moyenne | Haute |
