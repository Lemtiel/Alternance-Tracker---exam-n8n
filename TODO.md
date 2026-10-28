# TODO - Alternance Tracker

**Dernière mise à jour** : 2026-10-28

---

## ✅ Configuration (terminée)

- [x] Credential `Google Gemini(PaLM) Api account` créé et branché sur les deux nœuds Gemini
- [x] Tableur créé (`11EYug1CDVKHmoY0NKTme5AQdxJdIp7gj23SMCLtxIJQ`)
- [x] 6 onglets créés
- [x] `Settings` renseigné avec l'identifiant du tableur
- [x] `diagnostic` → `blockers: []`

---

## 🧹 À faire par toi (nettoyage, ~5 min)

- [ ] Supprimer dans `Applications` la ligne `APP-5908eec9` (premier essai, colonnes vides)
- [ ] Supprimer dans `Offer_Analyses` et `Documents` les lignes créées par ce premier essai
- [ ] Vérifier l'en-tête de `Offer_Analyses` : la colonne `warnings_json` doit exister (ajoutée par le workflow). Sinon, la coller à la fin de la ligne 1
- [ ] Vérifier l'en-tête de `Applications` : l'onglet doit contenir `draft_to`, `draft_subject`, `draft_body`, `draft_status`, `contact_email`, `email_body`
- [ ] (Optionnel) Réordonner les colonnes de `Applications` selon `docs/GOOGLE_SHEETS_SETUP.md`

> Les onglets créés avec l'ancien schéma v1 restent utilisables : les colonnes manquantes sont ajoutées automatiquement, les colonnes inutilisées restent vides.

---

## 🤖 Workflow automatique `Alternance Tracker Auto` (2026-10-28)

- [x] Source `n8n/workflows/Alternance Tracker Auto.workflow.ts` (17 nœuds, 4 groupes)
- [x] Workflow poussé dans l'instance n8n : `famUstqu1tAcM0Lf`
- [x] `n8ncli validate --lint` → VALID, `n8ncli diff` → identique au distant
- [x] Logique des 6 nœuds Code vérifiée par un harnais local (13 contrôles)
- [x] Ligne de sécurité : brouillon créé même sans destinataire (`draft_to = A COMPLETER`), jamais d'envoi
- [ ] Connecter le credential `Google Drive account` (créé, vide)
- [ ] Créer le credential *Query Auth* `Adzuna API` (`app_id`, `app_key`) et le sélectionner sur `Fetch Offers`
- [ ] Renseigner `cvFolderId` dans `Settings`
- [ ] Exécution réelle de bout en bout, puis publication du déclencheur quotidien

---

## 🧪 Tests restants

### Déjà validés (2026-10-28)
- [x] `diagnostic` → `ready`
- [x] `add_offer` → `offer-137d5261` (Airbus)
- [x] `import_cv` → `profile-local-user`
- [x] `prepare` → `APP-197c8589`, score 85, `apply`, 3 documents
- [x] Contrôle de véracité : NoSQL et méthodes agiles absents du CV généré, signalés en avertissement
- [x] `draft` → objet contenant `APP-197c8589`, `draft_to` rempli
- [x] `dashboard` → compteurs cohérents

### À faire
- [ ] `add_offer` avec `fixtures/offer_thales_data.json`, puis `prepare` sur Thales
- [ ] Cas limites : CV trop court, offre sans email de contact, `prepare` sans profil, `prepare` sans offre, `draft` sur une candidature déjà `sent`, référence d'offre inconnue
- [ ] Vérifier le rendu du CV généré (accents, mise en forme Markdown)

---

## 📄 Documentation

- [ ] `docs/WORKFLOWS.md` : détail des 6 branches et des contrats de données
- [ ] `docs/PROMPTS.md` : les deux prompts XML et leur justification
- [ ] `tests/test_results.md` : résultats des tests ci-dessus
- [x] `docs/STATUS.md` mis à jour
- [x] `docs/GOOGLE_SHEETS_SETUP.md` : note sur les colonnes ajoutées automatiquement

---

## 🚀 Livraison

- [x] Export JSON des deux workflows dans `Workflow/`
- [ ] Capture d'écran du canvas pour la démonstration
- [ ] Scénario de démo écrit

---

## 🔮 Hors périmètre MVP

- [ ] Branche `mark_sent` avec preuve d'envoi
- [ ] Création du brouillon dans Gmail avec pièces jointes
- [ ] Conversion PDF des documents
- [ ] Détection des réponses et relances
- [ ] Multi-utilisateurs
- [ ] Migration vers PostgreSQL

---

## 📊 Avancement

| Élément | Statut |
|---|---|
| Infrastructure n8n | ✅ |
| Credential Google Sheets | ✅ |
| Credential Gemini | ✅ |
| Identifiant du tableur | ✅ |
| Workflow unique (27 nœuds) | ✅ |
| Workflow automatique (17 nœuds) | ✅ |
| Validation SDK + lint | ✅ |
| Parcours complet sur fixtures | ✅ |
| Deuxième offre + cas limites | ⏳ |
| Documentation finale | ⏳ |
| Livraison (export, capture, démo) | ⏳ |

**Progression** : ~85 % (le parcours complet fonctionne ; il reste les cas limites, la documentation de détail et la livraison)
