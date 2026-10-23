# ✅ TODO - Alternance Tracker

**Dernière mise à jour** : 2026-10-22 15:10

---

## 🎯 Actions immédiates (Utilisateur - 30-45 min)

### 1. Configuration n8n
- [ ] Ouvrir http://localhost:5678
- [ ] Créer compte n8n (email + mot de passe)
- [ ] Noter les credentials quelque part de sûr
- [ ] Répondre aux questions setup n8n
- [ ] Aller dans Settings > API
- [ ] Créer API Key nommée "n8ncli-local"
- [ ] Copier le token (affiché une seule fois !)
- [ ] Configurer n8ncli :
  ```powershell
  n8ncli env edit local --url http://localhost:5678 --access-token "VOTRE-TOKEN"
  ```
- [ ] Tester : `n8ncli env test local`

### 2. Créer Google Sheet
- [ ] Aller sur https://sheets.google.com
- [ ] Créer nouveau tableur : "Alternance Tracker - [Votre Nom]"
- [ ] Créer 10 tabs (voir `docs/GOOGLE_SHEETS_SETUP.md`) :
  - [ ] Users
  - [ ] Configuration
  - [ ] Profiles
  - [ ] Offers
  - [ ] Offer_Analyses
  - [ ] Applications
  - [ ] Documents
  - [ ] Messages
  - [ ] Events
  - [ ] Workflow_Locks
- [ ] Copier-coller les headers de chaque sheet (voir guide)
- [ ] Formater ligne 1 : Gras + Freeze row
- [ ] Noter le Sheet ID (dans l'URL)
- [ ] Sauvegarder le Sheet ID : `___________________________`

### 3. Configurer credential Google Sheets
- [ ] Dans n8n : Credentials > Add credential
- [ ] Chercher "Google Sheets"
- [ ] Choisir "Google Sheets OAuth2"
- [ ] Sélectionner "Use n8n's OAuth app"
- [ ] Connect my account
- [ ] Autoriser l'accès
- [ ] Tester la connexion
- [ ] Nom : "Google Sheets - Alternance Tracker"
- [ ] Save

### 4. Test de connexion
- [ ] Créer nouveau workflow dans n8n
- [ ] Nom : "WF0 - Init Config"
- [ ] Ajouter Manual Trigger
- [ ] Ajouter Google Sheets node (Read, Users sheet)
- [ ] Coller votre Sheet ID
- [ ] Tester le workflow
- [ ] ✅ Devrait retourner les colonnes (vides pour l'instant)

---

## 📋 Développement workflows (10-15h)

### Phase 2.1 : WF0 - Configuration (2h)
- [ ] Créer workflow WF0
- [ ] Vérifier connexion Google Sheets
- [ ] Lire sheet Configuration
- [ ] Vérifier credentials disponibles (Gmail, Drive, LLM)
- [ ] Compiler rapport diagnostic JSON
- [ ] Tester avec toutes combinaisons de config
- [ ] Logger événement dans sheet Events

**Statuts possibles** :
- `ready` : Tout configuré
- `incomplete` : Certains manquants
- `error` : Blocage

### Phase 2.2 : WF1 - Import CV (2-3h)
- [ ] Créer workflow WF1
- [ ] Input : File ID Google Drive ou upload local
- [ ] Extraire texte du PDF/DOCX
- [ ] Appel LLM pour structuration (prompt anti-invention)
- [ ] Valider schéma JSON sortie
- [ ] Insérer dans sheet Profiles
- [ ] Générer profile_id (UUID)
- [ ] Logger événement
- [ ] Tester avec `fixtures/profile_junior_dev.json`

**À créer** :
- [ ] `prompts/extract_cv.txt`

### Phase 2.3 : WF2 - Collecte offres (1-2h)
- [ ] Créer workflow WF2
- [ ] Input : URL ou JSON manuel
- [ ] Parser offre
- [ ] Normaliser structure
- [ ] Vérifier doublon (external_source + external_id)
- [ ] Insérer ou update sheet Offers
- [ ] Logger événement
- [ ] Tester avec fixtures offres

### Phase 2.4 : WF3 - Analyse (2-3h)
- [ ] Créer workflow WF3
- [ ] Input : offer_id + profile_id
- [ ] Charger offre et profil
- [ ] Appel LLM pour analyse (prompt scoring)
- [ ] Calculer score (poids configurables)
- [ ] Identifier compétences manquantes (sans inventer)
- [ ] Insérer dans sheet Offer_Analyses
- [ ] Logger événement
- [ ] Tester avec combinaisons profil/offre

**À créer** :
- [ ] `prompts/analyze_offer.txt`

### Phase 2.5 : WF4 - Adaptation CV (2-3h)
- [ ] Créer workflow WF4
- [ ] Input : offer_id + profile_id
- [ ] Charger profil et analyse
- [ ] Appel LLM adaptation (prompt strict : réorganiser, pas inventer)
- [ ] Générer Markdown
- [ ] Conversion Markdown → PDF (méthode à définir)
- [ ] Upload vers Drive (optionnel)
- [ ] Insérer dans sheet Documents
- [ ] Logger événement
- [ ] **Validation manuelle obligatoire** (pas automatique)

**À créer** :
- [ ] `prompts/adapt_cv.txt`

**À décider** :
- [ ] Méthode génération PDF (API externe ? Pandoc ? Google Docs API ?)

### Phase 2.6 : WF5 - Génération documents (2h)
- [ ] Créer workflow WF5
- [ ] Input : application_id
- [ ] Charger application, offre, profil
- [ ] Générer lettre de motivation (LLM)
- [ ] Générer corps email (LLM)
- [ ] Insérer documents dans sheet Documents
- [ ] Logger événements

**À créer** :
- [ ] `prompts/generate_cover_letter.txt`
- [ ] `prompts/generate_email.txt`

### Phase 2.7 : WF6 - Brouillon avec APP-ref (2h)
- [ ] Créer workflow WF6
- [ ] Input : application_id
- [ ] Générer tracking_ref unique : `APP-{8 char hex}`
- [ ] Charger documents (CV, lettre, email)
- [ ] Vérifier contact_email disponible
- [ ] Construire objet avec APP-ref : "Candidature [poste] - APP-xxxxx"
- [ ] Créer brouillon Gmail avec pièces jointes
- [ ] Stocker draft_message_id
- [ ] Update Applications : status = 'ready', tracking_ref, draft_created_at
- [ ] Logger événement
- [ ] **VÉRIFIER : c'est un brouillon, pas un envoi**

**Credentials requis** :
- [ ] Gmail OAuth2 (gmail.compose)

### Phase 2.8 : WF10 - Dashboard (2-3h)
- [ ] Créer workflow WF10
- [ ] Lire sheet Applications
- [ ] Joindre données Offers, Profiles, Offer_Analyses
- [ ] Afficher candidatures actives
- [ ] Filtres : statut, score, date
- [ ] Actions :
  - [ ] Mettre à jour statut manuellement
  - [ ] Marquer envoi confirmé (sent_at)
  - [ ] Ajouter notes
  - [ ] Fermer candidature
- [ ] Afficher événements récents (sheet Events)

---

## 🧪 Tests (3-4h)

### Tests unitaires (par workflow)
- [ ] WF0 : Config complète, incomplète, erreur
- [ ] WF1 : CV valide, PDF corrompu, extraction partielle
- [ ] WF2 : Offre nouvelle, doublon, format invalide
- [ ] WF3 : Scoring cohérent, compétences manquantes
- [ ] WF4 : CV adapté sans invention
- [ ] WF5 : Documents cohérents avec offre
- [ ] WF6 : Brouillon créé, APP-ref présent, pas d'envoi
- [ ] WF10 : Affichage données, actions manuelles

### Tests d'intégration
- [ ] WF1 → WF3 : Profil importé puis analysé
- [ ] WF3 → WF4 → WF5 : Pipeline génération documents
- [ ] WF6 → Action manuelle → WF10 : Brouillon puis suivi

### Test bout-en-bout
- [ ] Charger fixture profile_junior_dev.json via WF1
- [ ] Charger fixture offer_airbus via WF2
- [ ] Analyser via WF3
- [ ] Générer documents via WF4, WF5
- [ ] Créer brouillon via WF6
- [ ] Vérifier dans WF10
- [ ] **Vérifier** : aucune invention détectée
- [ ] **Vérifier** : APP-ref présent dans objet
- [ ] **Vérifier** : brouillon Gmail créé (pas envoyé)

**Documenter résultats** :
- [ ] `tests/test_results.md`

---

## 📝 Documentation supplémentaire (2-3h)

### Guides utilisateur
- [ ] `docs/USER_GUIDE.md` : Utilisation quotidienne
- [ ] `docs/TROUBLESHOOTING.md` : Problèmes courants
- [ ] `docs/LIMITATIONS.md` : Limites connues MVP

### Documentation technique
- [ ] `docs/WORKFLOWS.md` : Description détaillée chaque workflow
- [ ] `docs/PROMPTS.md` : Stratégie et bonnes pratiques prompts
- [ ] `docs/DATA_MODEL.md` : Schéma Google Sheets détaillé

### Procédures
- [ ] Sauvegarde Google Sheet (File > Make a copy)
- [ ] Export workflows n8n (pour versioning)
- [ ] Restauration après erreur

---

## 🚀 Livraison MVP (1h)

### Validation finale
- [ ] Tous les workflows fonctionnent
- [ ] Test bout-en-bout réussi
- [ ] Documentation complète et à jour
- [ ] Aucune invention détectée
- [ ] Aucun envoi automatique
- [ ] APP-ref présent et fonctionnel

### Démonstration
- [ ] Préparer scénario de démo
- [ ] Capturer screenshots/vidéo
- [ ] Documenter dans `DEMO.md`

### Archivage
- [ ] Export workflows n8n (JSON + TypeScript si n8ncli)
- [ ] Backup Google Sheet
- [ ] Archive projet complet

---

## 🔮 Évolutions futures (Phase 3+)

### À court terme
- [ ] WF7 : Détection envois (multi-indices + clé APP-ref)
- [ ] WF8 : Classification réponses (LLM)
- [ ] Amélioration WF10 : Statistiques, graphiques

### À moyen terme
- [ ] WF9 : Relances avec boucle contrôle complète
- [ ] Migration SQLite (selon volume)
- [ ] RAG pour matching offres/profil

### À long terme
- [ ] Migration PostgreSQL (multi-utilisateur)
- [ ] Interface web dédiée
- [ ] Intégration calendrier (entretiens)
- [ ] Export statistiques avancées

---

## 📊 Suivi avancement

| Phase | Statut | Durée estimée | Durée réelle |
|-------|--------|---------------|--------------|
| Phase 1 : Audit et architecture | ✅ | 6h | 6h |
| Phase 2.1 : WF0 | ⏳ | 2h | - |
| Phase 2.2 : WF1 | ⏳ | 2-3h | - |
| Phase 2.3 : WF2 | ⏳ | 1-2h | - |
| Phase 2.4 : WF3 | ⏳ | 2-3h | - |
| Phase 2.5 : WF4 | ⏳ | 2-3h | - |
| Phase 2.6 : WF5 | ⏳ | 2h | - |
| Phase 2.7 : WF6 | ⏳ | 2h | - |
| Phase 2.8 : WF10 | ⏳ | 2-3h | - |
| Phase 3 : Tests | ⏳ | 3-4h | - |
| Phase 4 : Documentation | ⏳ | 2-3h | - |
| Phase 5 : Livraison | ⏳ | 1h | - |
| **TOTAL MVP** | 🔄 | **27-35h** | **6h** |

**Progression** : 18% (6h / 33h)

---

## 🎯 Prochaine session

**Focus** : Configuration manuelle + WF0 + WF1

**Checklist avant de commencer** :
- [ ] J'ai lu QUICKSTART.md
- [ ] n8n est configuré
- [ ] Google Sheet est créé
- [ ] Credentials sont prêts
- [ ] J'ai 2-3h devant moi

**Commande pour démarrer** :
```
# Ouvrir n8n
http://localhost:5678

# Créer nouveau workflow
Name: WF0 - Init Config
Description: System configuration and diagnostic
```

---

**Mis à jour** : 2026-10-22 15:10  
**Par** : Session d'implémentation initiale  
**Prochaine mise à jour** : Après configuration manuelle
