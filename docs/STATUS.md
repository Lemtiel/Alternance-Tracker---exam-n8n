# État d'avancement - Alternance Tracker

**Date** : 2026-10-28
**Phase** : MVP exécuté de bout en bout sur les fixtures
**Statut** : 🟢 Les six actions passent sur l'instance réelle

---

## ✅ Réalisé

### Infrastructure
- n8n `2.44.5` épinglé dans `compose.yaml`, port limité à `127.0.0.1:5678`
- Volume dédié `alternance_tracker_data`
- `n8ncli` initialisé sur l'environnement `local`, projet personnel `bVZliWxwN4Tpwx03`
- Credentials présents :
  - `Google Sheets account` (`googleSheetsOAuth2Api`, id `WPHRV1xwMPz7spQZ`)
  - `Google Gemini(PaLM) Api account` (`googlePalmApi`, id `2hE1732A2Q2fwTJW`), sélectionné sur les deux nœuds Gemini

### Workflow unique : `Alternance Tracker`
- Id n8n : `HlVcM1JUEF5DJf90`
- 27 nœuds, 6 branches, 1 seul déclencheur (formulaire `alternance-tracker`)
- Fichier source : `n8n/workflows/Alternance Tracker.workflow.ts`, resynchronisé depuis n8n
- `n8ncli validate --lint` : VALID, aucun avertissement
- Tableur : `11EYug1CDVKHmoY0NKTme5AQdxJdIp7gj23SMCLtxIJQ`, renseigné dans `Settings`

### Choix structurants
1. **Un seul workflow** : chaque action est une branche du formulaire, pas un workflow séparé.
2. **Deux appels LLM au total** sur le parcours complet :
   - `import_cv` → extraction du profil
   - `prepare` → scoring + CV + lettre + email en un seul appel
3. **Gemini Flash-Lite latest** (`models/gemini-flash-lite-latest`), sortie JSON, température 0.1 / 0.2.
4. **Prompts au format XML imposé** : `<role>`, `<instructions>` (`<goal>`, `<context>`, `<examples>` avec 3 exemples, `<output_format>`), puis `<inputs>` avec `{{ ... }}`.
5. **Aucun envoi d'email** : le workflow n'appelle aucune API de messagerie. Il produit du contenu de brouillon, l'utilisateur envoie lui-même.
6. **Référence de suivi** `APP-xxxxxxxx` placée dans l'objet de l'email, pour un rapprochement certain.
7. **Véracité** : le profil est la seule source de vérité ; les compétences manquantes sont listées et jamais revendiquées. Un contrôle déterministe signale toute compétence manquante qui apparaîtrait malgré tout dans le CV généré.
8. **Traçabilité** : l'historique d'exécution n8n sert de journal d'audit ; aucune sheet `Events` n'est écrite.

### Actions disponibles
| Action | Nœuds | Effet |
|---|---|---|
| `diagnostic` | 3 | Rapport de préparation, bloqueurs, intégrations non vérifiées |
| `import_cv` | 4 | Extraction du profil (1 appel LLM) puis upsert `Profiles` |
| `add_offer` | 2 | Validation et upsert `Offers` (id déterministe) |
| `prepare` | 10 | Scoring + CV + lettre + email (1 appel LLM), écrit `Applications`, `Offer_Analyses`, `Documents` |
| `draft` | 3 | Prépare le brouillon avec `APP-ref` dans l'objet, statut `draft_ready` |
| `dashboard` | 2 | Synthèse : statuts, brouillons en attente, envois confirmés |

---

## 🧪 Validation sur l'instance (2026-10-28)

| Exécution | Action | Résultat |
|---|---|---|
| 4 | `diagnostic` | `status: ready`, `blockers: []`, `configuration_rows: 0` |
| 5 | `add_offer` | offre `offer-137d5261` (Airbus) écrite dans `Offers` |
| 8 | `import_cv` | profil `profile-local-user`, `extraction_confidence: 1`, 7 compétences |
| 13 | `prepare` | candidature `APP-197c8589`, score `85`, recommandation `apply`, 3 documents |
| 14 | `draft` | `draft_ready`, objet `… - APP-197c8589`, `draft_to` = email de contact |
| 15 | `dashboard` | `total: 2`, `awaiting_manual_send: 1`, `sent_confirmed: 0` |

Contrôle de véracité observé sur `APP-197c8589` : l'offre demande NoSQL et les méthodes agiles, absents du profil. Le modèle les a listés dans `missing_skills`, aucun des deux n'apparaît dans le CV généré, et un avertissement a été enregistré.

### Défauts trouvés et corrigés pendant les tests

1. **HTTP 400 `INVALID_ARGUMENT` sur le premier appel Gemini.** L'option `thinkingBudget: 0` est refusée par le modèle servi derrière `gemini-flash-lite-latest`. Option retirée : les valeurs par défaut de l'API s'appliquent.
2. **Parsers qui recevaient `[object Object]`.** Le nœud Gemini renvoie `content.parts[].text` (et non une chaîne). Les deux nœuds de parsing extraient désormais le texte de toutes les formes possibles et échouent explicitement quand `finishReason` n'est pas `STOP` (réponse tronquée).
3. **Colonnes perdues à l'écriture.** Les onglets avaient été créés avec l'ancien schéma v1 ; les nœuds d'écriture étaient en `ignoreIt`, donc tout champ sans colonne était silencieusement jeté (`contact_email`, `email_body`, `warnings_json`…). Passage en `insertInNewColumn` : la colonne manquante est ajoutée en fin d'en-tête au lieu de perdre la donnée.

---

## 🔴 Blocages restants

Aucun.

---

## 🚧 Limites assumées du MVP

- **Brouillon sans Gmail** : le contenu du brouillon est stocké dans `Applications` (`draft_to`, `draft_subject`, `draft_body`), pas dans Gmail. Aucune pièce jointe n'est créée.
- **Statut `sent` manuel** : le workflow ne peut pas prouver un envoi, il ne le déclare donc jamais.
- **Validation humaine obligatoire** : tous les documents naissent `pending_review`.
- **Un seul profil actif** : `Profiles` est upserté sur un id fixe par utilisateur.
- **Pas de conversion PDF** : les documents sont stockés en Markdown ou texte.
- **Mono-utilisateur** : `userId` vaut `local-user`.
- **Onglets à l'ancien schéma** : les colonnes inutilisées restent vides, les colonnes manquantes sont ajoutées par le workflow. Voir `docs/GOOGLE_SHEETS_SETUP.md`.
- **Pas de relances, pas de détection de réponses** (hors MVP).

---

## 🤖 Workflow automatique `Alternance Tracker Auto`

Poussé dans l'instance locale le 2026-10-28, identifiant `famUstqu1tAcM0Lf`.

- 17 nœuds, 4 groupes, une seule branche linéaire : `Daily Trigger` → `Settings` → profil CV → collecte des offres → brouillons.
- Source : `n8n/workflows/Alternance Tracker Auto.workflow.ts` ; export importable : `Workflow/Alternance Tracker Auto.workflow.json`.
- `n8ncli validate --lint` : VALID ; `n8ncli diff` : identique au distant.
- Les six nœuds Code ont été exécutés hors n8n dans un harnais local (13 contrôles : choix du PDF, parsing du profil, normalisation Adzuna, déduplication et plafond, construction du prompt, refus d'une référence modifiée, plafonnement du score, destinataire absent).
- Le workflow est laissé **inactif** : sans credential Drive connecté, sans credential `Adzuna API` et sans `cvFolderId`, une exécution planifiée échouerait chaque matin.

**Ce qui reste à faire côté utilisateur** : connecter `Google Drive account`, créer le credential *Query Auth* `Adzuna API`, renseigner `cvFolderId`, puis publier le workflow.

---

## 🎓 Ce que le projet démontre

- Conception d'un workflow unique à branches plutôt qu'une constellation de workflows
- Optimisation du coût LLM : deux appels, température basse, sortie JSON, aucune option superflue
- Prompts structurés en XML avec exemples et format de sortie contraignant
- Séparation stricte entre données et instructions (l'offre est une donnée, jamais une consigne)
- Refus de l'invention : source de vérité unique, champs inconnus laissés vides, contrôle déterministe
- Discipline sur les effets de bord : aucune action irréversible automatisée

---

## 📌 Prochaines étapes

1. Supprimer les lignes de test incomplètes : `APP-5908eec9` dans `Applications`, et les analyses/documents du premier essai.
2. Rejouer `prepare` sur la seconde offre (`fixtures/offer_thales_data.json`) pour vérifier le tri des candidatures.
3. Tester les cas limites : CV trop court, offre sans email de contact, `prepare` sans profil, `draft` sur une candidature déjà `sent`.
4. Rédiger `docs/WORKFLOWS.md`, `docs/PROMPTS.md` et `tests/test_results.md`.
5. Exporter le workflow en JSON et préparer le scénario de démonstration.
