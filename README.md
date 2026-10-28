# Alternance Tracker

Système d'accompagnement à la recherche d'alternance, construit sur n8n, autour de trois principes :

1. **Contrôle humain absolu** - aucun email n'est jamais envoyé par le workflow
2. **Véracité stricte** - aucune compétence, expérience, date ou niveau inventé
3. **Traçabilité** - chaque candidature porte une référence unique `APP-xxxxxxxx`

## MVP (version 1.0)

**Un seul workflow n8n** : `Alternance Tracker`, 27 nœuds, 6 branches derrière un formulaire unique.
Identifiant n8n : `HlVcM1JUEF5DJf90`.
Source : `n8n/workflows/Alternance Tracker.workflow.ts`.

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
Source : `n8n/workflows/Alternance Tracker Auto.workflow.ts`.

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
| `cvFolderId` | Dossier Google Drive qui contient le CV |
| `spreadsheetId`, `userId` | Tableur cible et identifiant de profil |

**Coût** : 1 appel Gemini pour le CV + 1 appel par nouvelle offre, jamais plus de `maxOffers` par jour.

**Sans adresse destinataire**, le brouillon est tout de même créé : `draft_to` vaut `A COMPLETER`, l'avertissement est consigné et la référence `APP-xxxxxxxx` reste dans l'objet. Le workflow n'envoie rien.

### Prérequis propres à ce workflow

1. **Google Drive** : le credential `Google Drive account` existe déjà dans l'instance mais n'est pas encore connecté. L'ouvrir dans n8n, renseigner le client OAuth2 et autoriser le compte.
2. **Adzuna** : créer un credential *Query Auth* nommé `Adzuna API` avec les champs `app_id` et `app_key` (inscription gratuite sur `developer.adzuna.com`), puis le sélectionner sur le nœud `Fetch Offers`.
3. **`cvFolderId`** : remplacer `PASTE_YOUR_DRIVE_FOLDER_ID` par l'identifiant du dossier Drive.

Tant que ces trois points ne sont pas faits, laisser le workflow **inactif** : le déclencheur planifié échouerait chaque matin.

## Architecture

- **n8n** : `2.44.5`, épinglé dans `compose.yaml`, port limité à `127.0.0.1:5678`
- **Stockage** : Google Sheets (6 onglets), voir `docs/GOOGLE_SHEETS_SETUP.md`
- **Modèle** : `models/gemini-flash-lite-latest`
- **Offres (Auto)** : API publique Adzuna, remplaçable dans le nœud `Fetch Offers`
- **Journal d'audit** : historique d'exécution n8n

Le schéma SQL de `schemas/v1_initial.sql` reste la référence pour une migration future vers une base relationnelle.

## Installation

### Prérequis
- Docker et Docker Compose
- n8ncli `1.2.45+`

### Démarrage

```powershell
docker compose up -d
n8ncli env test local
n8ncli validate "n8n/workflows/Alternance Tracker.workflow.ts" --lint
```

Puis suivre `QUICKSTART.md` (tableur, parcours de test).

### Déploiement des workflows

```powershell
n8ncli push "n8n/workflows/Alternance Tracker.workflow.ts" --force
n8ncli push "n8n/workflows/Alternance Tracker Auto.workflow.ts" --force
```

`--force` n'est nécessaire que si le workflow a été modifié dans l'interface n8n depuis le dernier push : les groupes de nœuds, par exemple, sont appliqués directement dans n8n.

Les exports prêts à importer (n8n → *Import from file*) sont versionnés dans `Workflow/` :

- `Workflow/Alternance Tracker.workflow.json`
- `Workflow/Alternance Tracker Auto.workflow.json`

Ils contiennent les identifiants de credentials de cette instance, jamais de secret : après import sur une autre instance, il suffit de resélectionner les credentials.

## Documentation

- `QUICKSTART.md` - mise en route en 15 minutes
- `docs/STATUS.md` - état d'avancement, décisions, limites
- `docs/GOOGLE_SHEETS_SETUP.md` - onglets et en-têtes exacts
- `docs/ARCHITECTURE.md` - modèle de données et cycle de vie
- `docs/DECISION-STORAGE.md` - pourquoi Google Sheets
- `TODO.md` - reste à faire

## Règles importantes

- Ne jamais écrire `sent` sans preuve dans la boîte mail ; le workflow ne le fait jamais lui-même.
- Tout document généré est `pending_review` : il doit être lu avant usage.
- Ne jamais ajouter au CV une compétence absente de `Profiles`.
- Le formulaire est le seul point d'entrée : une action par soumission.

## Tests

```powershell
n8ncli validate "n8n/workflows/Alternance Tracker.workflow.ts" --lint
n8ncli validate "n8n/workflows/Alternance Tracker Auto.workflow.ts" --lint
```

Les fixtures de `fixtures/` servent aux tests manuels décrits dans `TODO.md`.

Le parcours complet du MVP a été exécuté sur l'instance locale (voir `docs/STATUS.md`).
Pour le workflow Auto, la logique des nœuds Code (sélection du CV, normalisation des offres, déduplication, construction et validation du brouillon) est couverte par un harnais local ; le parcours réseau reste à valider après connexion des credentials Drive et Adzuna.
