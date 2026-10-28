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

## Architecture

- **n8n** : `2.44.5`, épinglé dans `compose.yaml`, port limité à `127.0.0.1:5678`
- **Stockage** : Google Sheets (6 onglets), voir `docs/GOOGLE_SHEETS_SETUP.md`
- **Modèle** : `models/gemini-flash-lite-latest`
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

### Déploiement du workflow

```powershell
n8ncli push "n8n/workflows/Alternance Tracker.workflow.ts" --force
```

`--force` n'est nécessaire que si le workflow a été modifié dans l'interface n8n depuis le dernier push : les groupes de nœuds, par exemple, sont appliqués directement dans n8n.

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
```

Les fixtures de `fixtures/` servent aux tests manuels décrits dans `TODO.md`.
