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
Export importable : `Workflow/Alternance Tracker Auto.workflow.ts` (format workflow-as-code n8n).

Il réutilise le même tableur et les mêmes onglets que le MVP : les deux workflows alimentent un seul suivi.

| Étape | Rôle |
|---|---|
| `Daily Trigger` | Schedule Trigger, une fois par jour à 08:00 |
| `Settings` | Critères de recherche et identifiants, à régler une seule fois |
| `CV profile` | Cherche le CV dans le dossier Drive, prend le PDF en priorité, l'envoie à Gemini et enregistre le profil (1 appel LLM) |
| `Offer harvesting` | Interroge l'API La bonne alternance (`/api/job/v1/search`), écarte les offres déjà connues, plafonne à `maxOffers` |
| `Draft preparation` | Note chaque offre et écrit un brouillon d'e-mail par offre (1 appel LLM par offre) |

| Paramètre (`Settings`) | Rôle |
|---|---|
| `keywords` | Texte recherché dans le titre et la description des offres |
| `location` | Zone de recherche, en nom complet (`Toulouse, Occitanie, France`) |
| `timeFrame` | Fenêtre de l'API : `24h` pour un passage quotidien, `7d` pour un rattrapage |
| `maxFetch` | Nombre d'offres demandées à l'API par exécution, donc plafond de crédits consommés |
| `maxOffers` | Nombre maximum d'offres traitées par jour, donc plafond du coût LLM |
| `maxDaysOld` | Ancienneté maximale des offres |
| `cvFolderId` | Dossier Google Drive du CV ; facultatif, sinon recherche par nom |
| `spreadsheetId`, `userId` | Tableur cible et identifiant de profil |

**Coût** : 1 appel Gemini pour le CV + 1 appel par nouvelle offre, jamais plus de `maxOffers` par jour.

**Sans adresse destinataire**, le brouillon est tout de même créé : `draft_to` vaut `A COMPLETER`, l'avertissement est consigné et la référence `APP-xxxxxxxx` reste dans l'objet. Le workflow n'envoie rien.

### Prérequis propres à ce workflow

1. **Google Drive** : credential OAuth2 `CV_folder`, autorisé sur le compte qui contient le CV. S'il échoue en `invalid_client`, le client OAuth ou son jeton n'est plus accepté par Google : rouvrir le credential et le reconnecter.
2. **`cvFolderId`** : facultatif. Laisser `PASTE_YOUR_DRIVE_FOLDER_ID` pour chercher tout le Drive avec `name contains 'CV'` ; sinon, mettre l'identifiant du dossier et la recherche s'y limite.
3. **La bonne alternance** : l'API de recherche s'authentifie par un en-tête `Authorization: Bearer <clé>`. Créer un credential **Bearer Auth** nommé `La bonne alternance`, y coller la clé seule (sans le préfixe `Bearer `), puis le sélectionner sur `Fetch Offers`.

   Puis, sur `Fetch Offers` : *Authentication* = `Generic Credential Type`, *Generic Auth Type* = `Bearer Auth`, credential `La bonne alternance`, URL = `https://api.apprentissage.beta.gouv.fr/api/job/v1/search`.

   Les paramètres de requête du nœud (`time_frame`, `description`, `location`, `ai_language`, `description_format`, `date_posted_gte`, `limit`) sont encore ceux de l'ancien fournisseur. Ils restent à aligner sur le contrat de `La bonne alternance` (`caller`, `romes`, `latitude`/`longitude` ou `insee`, `radius`) avant la mise en service : tant que ce point n'est pas fait, l'appel répond une erreur et aucune offre n'est collectée.

Tant que les points 1 et 3 ne sont pas faits, laisser le workflow **inactif** : le déclencheur planifié échouerait chaque matin.

## Architecture

- **n8n** : `2.44.5`, instance locale sur `127.0.0.1:5678`
- **Stockage** : Google Sheets, 6 onglets : `Configuration`, `Profiles`, `Offers`, `Offer_Analyses`, `Applications`, `Documents`
- **Modèle** : `models/gemini-flash-lite-latest`
- **Offres (Auto)** : API La bonne alternance `/api/job/v1/search` (offres d'alternance collectées par La bonne alternance et ses partenaires), remplaçable dans le nœud `Fetch Offers`
- **Journal d'audit** : historique d'exécution n8n

Une migration future vers une base relationnelle reste possible ; pour le MVP, les six onglets sont la référence.

## Installation

### Prérequis
- Une instance n8n `2.44.5` ou plus récente
- Un tableur Google Sheets avec les six onglets (`Configuration`, `Profiles`, `Offers`, `Offer_Analyses`, `Applications`, `Documents`)
- Les credentials Gemini, Google Sheets et Google Drive

### Import

1. MVP : n8n → *Workflows* → *Import from file*, puis choisir `Workflow/Alternance Tracker.workflow.json`.
   Workflow automatique : `Workflow/Alternance Tracker Auto.workflow.ts` est un fichier workflow-as-code, déployé avec `n8ncli push` (ou importé depuis le canevas après conversion).
2. Ouvrir le nœud `Settings` et renseigner `spreadsheetId` ; pour le MVP, vérifier aussi `userId`.
3. Resélectionner les credentials Gemini, Google Sheets et Google Drive : les exports portent les identifiants de l'instance d'origine, jamais de secret.
4. Pour le workflow automatique, appliquer les prérequis La bonne alternance décrits plus haut, puis activer le déclencheur quotidien.

## Contenu du dépôt

Le dépôt public ne publie que les livrables :

| Élément | Contenu |
|---|---|
| `README.md` | Ce document |
| `Workflow/` | Le workflow MVP (`Alternance Tracker.workflow.json`) et le workflow automatique (`Alternance Tracker Auto.workflow.ts`, workflow-as-code) |
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

Les exécutions 35 et 36 ont validé la lecture réelle du CV dans Drive, l'extraction Gemini, l'écriture dans Sheets et la déduplication. Les exécutions 40 à 42 ont rejoué la chaîne des offres avec des données fantastic.jobs épinglées et un profil de test, le credential Drive étant à reconnecter :

| Contrôle | Résultat |
|---|---|
| Réponse ATS normalisée : HTML nettoyé, `locations_derived`, `domain_derived` | OK |
| Offre plus ancienne que `maxDaysOld` | écartée avant tout appel LLM |
| Deux offres neuves dans la même exécution | 2 lignes `Offers`, 2 brouillons |
| Mêmes offres rejouées | 0 nouvelle offre, déduplication sur `external_id` |
| Contact exposé par l'offre | repris dans `Offers.contact_email` et `Applications.draft_to` |
| Profil volontairement vide | score 0, `skip`, avertissement, aucune compétence inventée |
| Destinataire absent | `draft_to = A COMPLETER`, aucun envoi |

La validation statique des deux workflows (schéma n8n et lint) est passée sans erreur.
