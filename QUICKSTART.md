# 🚀 Guide de démarrage rapide - Alternance Tracker

**Temps estimé** : 30-45 minutes pour setup complet

---

## 📦 Ce qui est déjà prêt

✅ Infrastructure Docker configurée et sécurisée  
✅ Architecture complète documentée  
✅ Structure projet créée  
✅ Fixtures de test disponibles  
✅ Documentation complète  

---

## 🎯 Configuration en 5 étapes

### Étape 1 : Vérifier que n8n fonctionne (2 min)

```powershell
# Le conteneur devrait déjà tourner
docker ps | Select-String "alternance-tracker"

# Si pas démarré :
docker compose up -d

# Attendre 10 secondes puis ouvrir :
# http://localhost:5678
```

✅ Vous devriez voir la page de connexion n8n

---

### Étape 2 : Créer votre compte n8n (3 min)

1. Ouvrez http://localhost:5678
2. Remplissez le formulaire :
   - Email : votre-email@example.com
   - Mot de passe : (minimum 8 caractères)
   - Prénom et Nom
3. Cliquez "Get started"
4. Répondez aux questions de setup (skip les optionnelles)

✅ Vous êtes maintenant dans n8n !

---

### Étape 3 : Générer un API token (2 min)

1. Cliquez sur votre avatar (coin supérieur droit)
2. **Settings** > **API**
3. **Create API Key**
4. Nom : `n8ncli-local`
5. **Copiez le token** (affiché une seule fois !)

```powershell
# Configurez n8ncli avec ce token :
n8ncli env edit local --url http://localhost:5678 --access-token "VOTRE-TOKEN-ICI"

# Testez la connexion :
n8ncli env test local
```

✅ Vous devriez voir "REST API connection successful"

---

### Étape 4 : Créer votre Google Sheet (10-15 min)

#### 4.1 Créer le Sheet

1. Allez sur https://sheets.google.com
2. Créez un nouveau tableur
3. Nommez-le : **Alternance Tracker - [Votre Nom]**

#### 4.2 Créer les 10 tabs (sheets)

Créez ces tabs dans cet ordre (clic droit sur tab > Renommer) :
1. Users
2. Configuration
3. Profiles
4. Offers
5. Offer_Analyses
6. Applications
7. Documents
8. Messages
9. Events
10. Workflow_Locks

#### 4.3 Ajouter les en-têtes

**Users** (row 1) :
```
id | email | display_name | created_at | updated_at | deleted_at
```

**Configuration** (row 1) :
```
id | user_id | version | gmail_enabled | gmail_email | drive_enabled | drive_folder_id | llm_provider | llm_model | search_keywords_json | excluded_keywords_json | locations_json | contract_types_json | scoring_weights_json | min_score_threshold | notifications_enabled | notification_types_json | created_at | updated_at
```

**Profiles** (row 1) :
```
id | user_id | version | source_filename | source_filepath | extracted_at | personal_info_json | education_json | experience_json | skills_json | languages_json | certifications_json | projects_json | raw_text | extraction_confidence | uncertain_elements_json | human_verified | verified_at | verification_notes | created_at | updated_at
```

**Offers** (row 1) :
```
id | user_id | external_id | external_source | external_url | title | company_name | company_domain | description | location | contract_type | salary_range | start_date | contact_email | contact_name | application_url | posted_at | expires_at | last_checked_at | availability_status | status | created_at | updated_at | deleted_at
```

**Offer_Analyses** (row 1) :
```
id | offer_id | profile_id | score | scoring_details_json | matching_skills_json | missing_skills_json | strengths_json | concerns_json | recommendation | rationale | analyzed_by | model_version | created_at
```

**Applications** (row 1) :
```
id | user_id | offer_id | profile_id | tracking_ref | status | draft_created_at | sent_at | last_response_at | closed_at | response_count | notes | created_at | updated_at
```

**Documents** (row 1) :
```
id | application_id | profile_id | document_type | format | storage_type | storage_id | filename | generated_by | template_id | generation_params_json | content | verification_status | verification_notes | human_verified | verified_at | created_at | updated_at
```

**Messages** (row 1) :
```
id | user_id | provider | message_id | thread_id | message_type | direction | subject | from_email | from_name | to_emails_json | cc_emails_json | body_plain | body_html | sent_at | received_at | labels_json | has_attachments | attachment_names_json | synced_at | extracted_tracking_ref | created_at | updated_at
```

**Events** (row 1) :
```
id | user_id | entity_type | entity_id | event_type | event_data_json | triggered_by | occurred_at | created_at
```

**Workflow_Locks** (row 1) :
```
workflow_name | locked_at | locked_by | expires_at
```

#### 4.4 Formater les en-têtes

Pour chaque sheet :
1. Sélectionnez la ligne 1
2. Format > Gras
3. View > Freeze > 1 row

#### 4.5 Noter le Sheet ID

Dans l'URL, copiez l'ID :
```
https://docs.google.com/spreadsheets/d/[COPIEZ_CETTE_PARTIE]/edit
```

Exemple : `1abc...xyz` (long identifiant)

**Sauvegardez-le**, vous en aurez besoin !

---

### Étape 5 : Configurer credentials Google Sheets (5 min)

#### Dans n8n :

1. Menu latéral : **Credentials**
2. **Add credential** > Recherchez "Google Sheets"
3. Choisissez **Google Sheets OAuth2**
4. Sélectionnez **"Use n8n's OAuth app"** (plus simple pour test)
5. **Connect my account**
6. Autorisez l'accès Google Sheets
7. Testez la connexion (bouton "Test connection")
8. Nom du credential : `Google Sheets - Alternance Tracker`
9. **Save**

✅ Credential prêt !

---

## 🧪 Test rapide : Premier workflow

### Créer WF0 - Configuration (test de connexion)

1. Dans n8n, cliquez **Add workflow**
2. Nom : `WF0 - Init Config`
3. Ajoutez un node **Manual Trigger**
4. Ajoutez un node **Google Sheets**
   - Operation : **Read**
   - Credential : Sélectionnez votre credential
   - Document : Collez votre Sheet ID
   - Sheet : `Users`
5. Connectez Manual Trigger → Google Sheets
6. **Save** le workflow
7. Cliquez **Test workflow**

**Résultat attendu** :
- Le node Google Sheets devrait s'exécuter
- Retourner les colonnes (pas encore de données)
- Status : ✅ Success

✅ **Si ça marche, votre configuration est complète !**

---

## 📝 Données de test (optionnel)

Pour tester avec des données, ajoutez dans le sheet **Users** (row 2) :
```
test-user-001 | candidat@example.com | Jean Dupont | 2026-10-22T15:00:00.000Z | 2026-10-22T15:00:00.000Z |
```

Relancez le workflow, vous devriez voir cette ligne.

---

## ✅ Checklist finale

Avant de commencer à développer les workflows :

- [ ] ✅ n8n accessible et compte créé
- [ ] ✅ API token généré et n8ncli configuré
- [ ] ✅ Google Sheet créé avec 10 tabs + headers
- [ ] ✅ Sheet ID sauvegardé
- [ ] ✅ Credential Google Sheets créé et testé
- [ ] ✅ WF0 test workflow fonctionne

---

## 🚀 Prochaines étapes

Vous êtes prêt pour :
1. **Développer WF1-6** : Import CV, analyse, génération documents
2. **Tester avec fixtures** : Profils et offres de test fournis
3. **Créer WF10** : Dashboard et suivi

Référez-vous à :
- `docs/STATUS.md` : État d'avancement détaillé
- `docs/ARCHITECTURE.md` : Spécifications techniques
- `fixtures/*.json` : Données de test

---

## 🆘 Problèmes courants

### "Cannot connect to n8n"
```powershell
docker compose restart
Start-Sleep -Seconds 10
# Puis réessayez http://localhost:5678
```

### "Invalid API token"
- Régénérez un nouveau token dans Settings > API
- Reconfigurez n8ncli avec le nouveau token

### "Google Sheets connection failed"
- Vérifiez que vous avez autorisé l'app OAuth
- Essayez de réautoriser le credential
- Vérifiez que le Sheet ID est correct

---

## 🎉 Félicitations !

Votre environnement Alternance Tracker est opérationnel.

**Temps total** : ~30-45 minutes  
**Prochaine étape** : Développer les workflows (WF1-6, WF10)  
**Durée estimée** : 10-15h pour MVP complet

📚 **Documentation complète** : `docs/` folder

Bon développement ! 🚀
