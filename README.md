# Alternance Tracker

Système d'accompagnement à la recherche d'alternance, construit sur n8n, autour de trois principes :

1. **Contrôle humain absolu** - aucun email n'est jamais envoyé par le workflow
2. **Véracité stricte** - aucune compétence, expérience, date ou niveau inventé
3. **Traçabilité** - chaque candidature porte une référence unique `APP-xxxxxxxx`

## MVP (version 1.0)

**Un seul workflow n8n** : `Alternance Tracker`, 27 nœuds, 6 branches derrière un formulaire unique.
Identifiant n8n : `HlVcM1JUEF5DJf90`.
Export importable : `Workflow/Alternance Tracker.workflow.json`.

| Action | Rôle |
|---|---|
| `diagnostic` | Vérifie le stockage, le profil et l'état des intégrations |
| `import_cv` | Extrait un profil factuel du texte du CV (1 appel LLM) |
| `add_offer` | Enregistre une offre, sans doublon |
| `prepare` | Score l'offre et génère CV, lettre et email (1 appel LLM), écrit les trois tables |
| `draft` | Prépare le brouillon avec `APP-xxxxxxxx` dans l'objet, sans API de messagerie |
| `dashboard` | Synthèse des candidatures, brouillons en attente, envois confirmés |

**Deux appels LLM au total** sur le parcours complet : Gemini Flash-Lite latest, sortie JSON, budget de réflexion nul.
Chaque prompt suit le format XML imposé : `<role>`, `<instructions>` (`<goal>`, `<context>`, `<examples>`, `<output_format>`), puis `<inputs>`.

**Hors périmètre** : envoi automatique, création du brouillon dans Gmail, relances, détection des réponses, multi-utilisateurs.

## Workflow automatique (version 1.1)

**`Alternance Tracker Auto`** : 17 nœuds, 4 groupes, aucun formulaire à remplir à chaque exécution.
Identifiant n8n : `famUstqu1tAcM0Lf`.
Export importable : `Workflow/Alternance Tracker Auto.workflow.json`.

Il réutilise le même tableur et les mêmes onglets que le MVP : les deux workflows alimentent un seul suivi.

| Étape | Rôle |
|---|---|
| `Daily Trigger` | Schedule Trigger, une fois par jour à 08:00 |
| `Settings` | Critères de recherche et identifiants, à régler une seule fois |
| `CV profile` | Cherche le CV dans le dossier Drive, prend le PDF en priorité, l'envoie à Gemini et enregistre le profil (1 appel LLM) |
| `Offer harvesting` | Interroge l'API Adzuna, écarte les offres déjà connues, plafonne à `maxOffers` |
| `Draft preparation` | Note chaque offre et écrit un brouillon d'e-mail par offre (1 appel LLM par offre) |

| Paramètre (`Settings`) | Rôle |
|---|---|
| `keywords`, `location`, `countryCode` | Requête et pays envoyés à l'API |
| `maxOffers` | Nombre maximum d'offres traitées par jour, donc plafond de coût |
| `maxDaysOld` | Ancienneté maximale des offres |
| `cvFolderId` | Dossier Google Drive du CV ; facultatif, sinon recherche par nom |
| `spreadsheetId`, `userId` | Tableur cible et identifiant de profil |

**Coût** : 1 appel Gemini pour le CV + 1 appel par nouvelle offre, jamais plus de `maxOffers` par jour.

**Sans adresse destinataire**, le brouillon est tout de même créé : `draft_to` vaut `A COMPLETER`, l'avertissement est consigné et la référence `APP-xxxxxxxx` reste dans l'objet. Le workflow n'envoie rien.

### Prérequis propres à ce workflow

1. **Google Drive** : credential OAuth2 `CV_folder`, autorisé sur le compte qui contient le CV.
2. **`cvFolderId`** : facultatif. Laisser `PASTE_YOUR_DRIVE_FOLDER_ID` pour chercher tout le Drive avec `name contains 'CV'` ; sinon, mettre l'identifiant du dossier et la recherche s'y limite.
3. **Adzuna** : l'API exige **deux** paramètres de requête (`app_id` et `app_key`), or le credential *Query Auth* n'en porte qu'un. Créer à la place un credential **Simplified Custom Auth** nommé `Adzuna API` (inscription gratuite sur `developer.adzuna.com`) :

   - **Template** :

     ```json
     { "qs": { "app_id": "{{app_id}}", "app_key": "{{app_key}}" } }
     ```

   - **Placeholders** :

     ```json
     [
       { "name": "app_id", "title": "Adzuna app_id", "type": "plain" },
       { "name": "app_key", "title": "Adzuna app_key", "type": "password" }
     ]
     ```

   - **Placeholder Values** : `{ "app_id": "<votre app_id>", "app_key": "<votre app_key>" }`

   Puis, sur `Fetch Offers` : *Authentication* = `Generic Credential Type`, *Generic Auth Type* = `Simplified Custom Auth`, credential `Adzuna API`.

Tant que le point 3 n'est pas fait, laisser le workflow **inactif** : le déclencheur planifié échouerait chaque matin.

## Architecture

- **n8n** : `2.44.5`, instance locale sur `127.0.0.1:5678`
- **Stockage** : Google Sheets, 6 onglets : `Configuration`, `Profiles`, `Offers`, `Offer_Analyses`, `Applications`, `Documents`
- **Modèle** : `models/gemini-flash-lite-latest`
- **Offres (Auto)** : API publique Adzuna, remplaçable dans le nœud `Fetch Offers`
- **Journal d'audit** : historique d'exécution n8n

Une migration future vers une base relationnelle reste possible ; pour le MVP, les six onglets sont la référence.

## Installation

### Prérequis
- Une instance n8n `2.44.5` ou plus récente
- Un tableur Google Sheets avec les six onglets (`Configuration`, `Profiles`, `Offers`, `Offer_Analyses`, `Applications`, `Documents`)
- Les credentials Gemini, Google Sheets et Google Drive

### Import

1. n8n → *Workflows* → *Import from file*, puis choisir `Workflow/Alternance Tracker.workflow.json` (MVP) et/ou `Workflow/Alternance Tracker Auto.workflow.json`.
2. Ouvrir le nœud `Settings` et renseigner `spreadsheetId` ; pour le MVP, vérifier aussi `userId`.
3. Resélectionner les credentials Gemini, Google Sheets et Google Drive : les exports portent les identifiants de l'instance d'origine, jamais de secret.
4. Pour le workflow automatique, appliquer les prérequis Adzuna décrits plus haut, puis activer le déclencheur quotidien.

## Contenu du dépôt

Le dépôt public ne publie que les livrables :

| Élément | Contenu |
|---|---|
| `README.md` | Ce document |
| `Workflow/` | Les exports JSON importables des deux workflows |
| `Skills/` | Les trois skills utilisés pour concevoir et relire le projet (`interview`, `hostile-review`, `doubt-driven-dev`) |
| `Vidéo/` | Emplacement de la vidéo de présentation |

Les documents de travail (guide de démarrage, état d'avancement, schéma du tableur, fixtures, scripts, sources `n8n/`) restent sur le poste et ne sont pas versionnés.

## Règles importantes

- Ne jamais écrire `sent` sans preuve dans la boîte mail ; le workflow ne le fait jamais lui-même.
- Tout document généré est `pending_review` : il doit être lu avant usage.
- Ne jamais ajouter au CV une compétence absente de `Profiles`.
- Le formulaire reste le point d'entrée du MVP : une action par soumission. Le workflow automatique ne fait que collecter des offres et préparer des brouillons.

## Tests

Le parcours complet du MVP (sept actions) a été exécuté sur l'instance locale, sur un CV réel.

Pour le workflow automatique, les exécutions suivantes ont validé la chaîne de bout en bout, avec des offres Adzuna simulées tant que le credential de l'API n'est pas créé :

| Contrôle | Résultat |
|---|---|
| CV lu depuis Drive et profil extrait par Gemini | OK |
| Profil enregistré dans `Profiles` | OK |
| Deux offres neuves traitées dans la même exécution | 2 lignes `Offers`, 2 brouillons |
| Offres rejouées le lendemain | 0 nouvelle offre, déduplication par `external_id` |
| Destinataire absent | `draft_to = A COMPLETER`, aucun envoi |
| Avertissements de véracité | `SQL absent du profil`, `TypeScript absent du profil` |

La validation statique des deux workflows (schéma n8n et lint) est passée sans erreur.
