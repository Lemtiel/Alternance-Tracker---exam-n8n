# Démarrage rapide - Alternance Tracker

**Temps estimé** : 15-20 minutes.

Le MVP tient dans **un seul workflow n8n** : `Alternance Tracker` (27 nœuds, 6 branches).
Il n'envoie jamais d'email : il produit du contenu de brouillon que tu envoies toi-même.

---

## 1. Vérifier n8n (1 min)

```powershell
docker ps | Select-String "alternance-tracker"
# Si besoin :
docker compose up -d
```

Ouvrir http://localhost:5678

---

## 2. Vérifier le credential Gemini (déjà fait)

Le credential `Google Gemini(PaLM) Api account` existe et est rattaché aux deux nœuds :

- **Extract Cv Profile**
- **Analyze Offer and Write Documents**

> Ces deux nœuds sont les **seuls** appels au modèle. Aucun autre nœud n'en fait.
> Ne pas remettre l'option `thinkingBudget: 0` : le modèle `gemini-flash-lite-latest` la refuse (HTTP 400).

---

## 3. Vérifier le tableur (déjà fait)

Le tableur est créé et son identifiant est déjà renseigné dans le nœud **Settings**.

Pour repartir d'un tableur neuf, suivre `docs/GOOGLE_SHEETS_SETUP.md` :

1. Créer un tableur
2. Créer **6 onglets** : `Configuration`, `Profiles`, `Offers`, `Offer_Analyses`, `Applications`, `Documents`
3. Coller la ligne d'en-têtes de chaque onglet (fournie dans le guide)
4. Copier l'identifiant du tableur et le coller dans **Settings**

Le credential `Google Sheets account` est déjà rattaché aux dix nœuds Google Sheets.

---

## 4. Tester (5 min)

1. Dans le workflow, cliquer **Execute workflow**
2. Ouvrir l'URL du formulaire affichée par le nœud `Application Form`
3. Action `diagnostic` → **Submit**

Réponse attendue :

```json
{ "status": "ready", "blockers": [], ... }
```

Si `blockers` n'est pas vide, le message dit exactement quoi corriger.

---

## 5. Parcours complet

Dans l'ordre, depuis le même formulaire :

| Étape | Action | Champs à remplir |
|---|---|---|
| 1 | `import_cv` | `cv_text` (le texte complet du CV) |
| 2 | `add_offer` | `offer_title`, `company_name`, `contact_email`, `offer_description` |
| 3 | `prepare` | `offer_ref` (id de l'offre ou nom de l'entreprise) |
| 4 | `draft` | `application_ref` (le `APP-xxxxxxxx` renvoyé par `prepare`) |
| 5 | `dashboard` | rien |

`prepare` écrit : une ligne `Applications`, une ligne `Offer_Analyses`, une ligne `Documents` par document généré (CV, lettre, email).

`draft` ajoute `draft_to`, `draft_subject` (avec `APP-xxxxxxxx`) et `draft_body`, et passe le statut à `draft_ready`.

---

## 6. Envoyer toi-même

1. Ouvrir `Applications`, lire `draft_to`, `draft_subject`, `draft_body`
2. Lire et corriger le CV et la lettre dans `Documents` (`verification_status = pending_review`)
3. Envoyer depuis ta boîte mail
4. Passer `status` à `sent` et remplir `sent_at` **seulement** si la boîte confirme l'envoi

---

## 6 bis. Variante automatique (optionnelle)

Le workflow `Alternance Tracker Auto` fait la même chose sans formulaire : il cherche les offres lui-même chaque matin à 08:00, lit le CV dans un dossier Google Drive et prépare les brouillons.

Avant de le publier :

1. Connecter le credential `Google Drive account` (créé mais vide) et autoriser le compte.
2. Créer un credential *Query Auth* nommé `Adzuna API` (`app_id` + `app_key`, inscription gratuite) et le sélectionner sur le nœud `Fetch Offers`.
3. Dans `Settings`, remplacer `PASTE_YOUR_DRIVE_FOLDER_ID` par l'identifiant du dossier Drive qui contient le CV.

Il écrit dans le même tableur, donc le reste du parcours (lecture des brouillons, envoi manuel) ne change pas.

---

## Problèmes courants

### Le formulaire ne répond rien
Le nœud fautif est visible dans l'historique d'exécution n8n. Les erreurs sont explicites (`No profile found: run the import_cv action first.`).

### « spreadsheetId is not set »
Le nœud `Settings` contient encore `PASTE_YOUR_SPREADSHEET_ID`.

### « Gemini did not return JSON »
L'erreur affiche les 200 premiers caractères reçus. Relancer l'action ; si cela persiste, réduire la taille du CV ou de l'offre.

### Une colonne apparaît à la fin de l'onglet
L'en-tête ne correspondait pas exactement à `docs/GOOGLE_SHEETS_SETUP.md`. Le nœud d'écriture ajoute la colonne manquante plutôt que de perdre la donnée. Pour revenir à l'ordre documenté : vider l'onglet, recoller la ligne d'en-têtes, rejouer l'action.

---

## Documentation

- `docs/STATUS.md` : état d'avancement et limites
- `docs/GOOGLE_SHEETS_SETUP.md` : onglets et en-têtes exacts
- `docs/ARCHITECTURE.md` : modèle de données et états
- `TODO.md` : ce qui reste à faire
