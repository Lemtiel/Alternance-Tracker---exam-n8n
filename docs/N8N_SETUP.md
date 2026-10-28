# Configuration n8n - Guide de démarrage

## 🚀 Première connexion à n8n

### 1. Accéder à l'interface

Ouvrez votre navigateur et allez sur :
```
http://localhost:5678
```

### 2. Créer votre compte

Si c'est votre première connexion :
1. Entrez votre **email** : (utilisez votre email réel ou un email de test)
2. Définissez un **mot de passe** : (minimum 8 caractères)
3. Entrez votre **prénom** et **nom**
4. Cliquez sur "Get started"

⚠️ **Important** : Notez bien ces credentials, vous en aurez besoin pour n8ncli !

### 3. Configuration initiale

n8n vous demandera quelques préférences :
- Usage : "Personal" ou "Work" (choisissez selon votre cas)
- Taille de l'équipe : "Just me" pour MVP
- Rôle : "Student" ou autre selon votre profil
- Skip les questions optionnelles

## 🔑 Obtenir un API Access Token

### Option A : Via l'interface n8n

1. Cliquez sur votre avatar (coin supérieur droit)
2. Allez dans **Settings** > **API**
3. Cliquez sur **"Create API Key"**
4. Donnez un nom : "n8ncli-local"
5. Copiez le token généré (il ne sera affiché qu'une fois !)
6. Sauvegardez-le en sécurité

### Option B : Via les Personal Access Tokens (si disponible)

1. Settings > Personal Access Tokens
2. Generate new token
3. Name: "n8ncli"
4. Copy token

## ⚙️ Configurer n8ncli

### Méthode 1 : Variable d'environnement (temporaire)

**PowerShell** :
```powershell
$env:N8N_ACCESS_TOKEN = "votre-token-ici"
```

**Bash** (si vous utilisez WSL ou Git Bash) :
```bash
export N8N_ACCESS_TOKEN="votre-token-ici"
```

### Méthode 2 : Configuration globale (persistante)

```bash
n8ncli env edit local --url http://localhost:5678 --access-token "votre-token-ici"
```

### Méthode 3 : Fichier de configuration projet

Créez `n8n-cli.json` à la racine du projet :
```json
{
  "environments": {
    "local": {
      "url": "http://localhost:5678",
      "accessToken": "votre-token-ici"
    }
  }
}
```

⚠️ **ATTENTION** : Ce fichier est dans `.gitignore` pour ne jamais versionner votre token !

## 🧪 Tester la connexion

```bash
n8ncli env test local
```

Vous devriez voir :
```
✓ REST API connection successful
✓ User authenticated: votre-email@example.com
```

## 🔧 Initialiser le workspace n8ncli

```bash
n8ncli init --no-examples
```

Cela créera :
- `n8n/` : Dossier pour les workflows
- Configuration locale

## 📦 Credentials Google Sheets (pour le stockage)

### 1. Dans n8n interface

1. Menu latéral : **Credentials**
2. Cliquez sur **"Add credential"**
3. Recherchez **"Google Sheets"**
4. Choisissez **"Google Sheets OAuth2"**

### 2. Configuration OAuth

**Option A : Utiliser les credentials n8n (recommandé pour test)**
- Sélectionnez "Use n8n's OAuth app"
- Cliquez sur "Connect my account"
- Autorisez l'accès à Google Sheets
- Testez la connexion

**Option B : Créer votre propre OAuth app**
1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un projet "Alternance Tracker"
3. Activez "Google Sheets API"
4. Créez des credentials OAuth 2.0
5. Ajoutez redirect URI : `http://localhost:5678/rest/oauth2-credential/callback`
6. Copiez Client ID et Client Secret dans n8n
7. Autorisez l'accès

### 3. Sauvegarder

- Donnez un nom : "Google Sheets - Alternance Tracker"
- Cliquez sur "Save"
- Notez l'ID du credential (vous en aurez besoin dans les workflows)

## 🗂️ Créer votre Google Sheet

1. Suivez le guide : `docs/GOOGLE_SHEETS_SETUP.md`
2. Créez toutes les sheets avec headers
3. Notez le **Sheet ID** (dans l'URL)
4. Partagez le sheet avec votre compte Google (celui autorisé dans n8n)

## ✅ Checklist de configuration complète

- [ ] n8n accessible sur http://localhost:5678
- [ ] Compte n8n créé
- [ ] API token généré et sauvegardé
- [ ] n8ncli configuré et testé
- [ ] Credential Google Sheets créé et testé
- [ ] Google Sheet créé avec toutes les tabs
- [ ] Sheet ID sauvegardé

## 🚨 Dépannage

### "Cannot connect to n8n"
- Vérifiez que Docker est lancé : `docker ps`
- Vérifiez le port : `http://localhost:5678` (pas 5679 ou autre)
- Redémarrez le conteneur : `docker compose restart`

### "Invalid API token"
- Vérifiez que le token n'a pas d'espaces avant/après
- Régénérez un nouveau token si nécessaire
- Vérifiez que vous utilisez le bon environnement (local)

### "Google Sheets connection failed"
- Vérifiez que vous avez autorisé l'app OAuth
- Essayez de réautoriser le credential
- Vérifiez que le Sheet est partagé avec votre compte

### Port 5678 déjà utilisé
```bash
# Trouver le processus
netstat -ano | findstr :5678

# Arrêter le conteneur et relancer
docker compose down
docker compose up -d
```

## 📚 Ressources

- Documentation n8n : https://docs.n8n.io/
- n8ncli docs : https://github.com/n8n-io/n8ncli
- Google Sheets API : https://developers.google.com/sheets/api

## ⏭️ Prochaines étapes

Une fois la configuration terminée :
1. Créer le premier workflow (WF0 - Configuration)
2. Tester avec des données fictives
3. Construire les workflows suivants (WF1-WF6, WF10)

---

**Date** : 2026-10-22  
**Version** : 1.0 - Configuration initiale
