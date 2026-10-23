# Alternance Tracker

Système d'accompagnement à la recherche d'alternance avec n8n, respectant trois principes fondamentaux :

1. **Contrôle humain absolu** : Aucun envoi automatique d'email
2. **Véracité stricte** : Aucune invention de compétence ou expérience
3. **Détection robuste** : Rapprochement par clé unique + validation humaine des cas ambigus

## 🎯 MVP (Version 1.0)

**Workflows implémentés** :
- WF0 : Configuration et diagnostic système
- WF1 : Import et extraction CV
- WF2 : Collecte d'offres
- WF3 : Analyse et scoring
- WF4 : Adaptation CV
- WF5 : Génération documents (lettre, email)
- WF6 : Création brouillon avec clé unique (APP-xxxx)
- WF10 : Tableau de bord et actions manuelles

**Hors scope MVP** :
- WF7-8 : Détection automatique envois/réponses (manuel dans MVP)
- WF9 : Relances automatiques (manuel dans MVP)

## 🏗️ Architecture

### Stack technique
- **n8n** : 2.44.5 (Docker)
- **Stockage** : SQLite externe (`/data/alternance-tracker.db`)
- **Intégrations** : Google Drive, Gmail (brouillons), OpenAI/LLM

### Base de données
- 12 tables principales
- Contraintes d'intégrité strictes
- Queue de workflows pour éviter race conditions
- Audit trail complet

## 📋 Installation

### Prérequis
- Docker et Docker Compose
- n8ncli 1.2.40+

### Démarrage rapide

1. **Cloner le projet** (ou extraire l'archive)

2. **Démarrer n8n**
   ```bash
   docker compose up -d
   ```

3. **Initialiser la base de données**
   ```bash
   ./scripts/init_db.sh
   ```

4. **Charger les fixtures de test**
   ```bash
   ./scripts/load_fixtures.sh
   ```

5. **Configurer n8ncli**
   ```bash
   n8ncli env edit local
   # URL: http://localhost:5678
   # Credentials: vos credentials n8n
   ```

6. **Importer les workflows**
   ```bash
   cd workflows
   n8ncli push --all
   ```

7. **Accéder à n8n**
   - URL : http://localhost:5678
   - Créer un compte lors du premier accès

## 📖 Documentation

- [Architecture complète](docs/ARCHITECTURE.md)
- [Guide utilisateur](docs/USER_GUIDE.md)
- [Configuration](docs/CONFIGURATION.md)
- [Stockage et schéma](docs/STORAGE.md)
- [Dépannage](docs/TROUBLESHOOTING.md)
- [Limites connues](docs/LIMITATIONS.md)

## 🔒 Sécurité

- Port n8n restreint à `127.0.0.1:5678` (local uniquement)
- Version n8n fixée à `2.44.5`
- Secrets dans credentials n8n (chiffrés)
- `.gitignore` configuré pour ne jamais versionner secrets ou données réelles

## 🧪 Tests

```bash
# Valider les workflows
n8ncli validate --lint

# Tester un workflow spécifique
n8ncli test workflows/WF0_Init_Config.workflow.ts

# Voir les résultats de tests
cat tests/test_results.md
```

## 📝 Utilisation

### Workflow de base

1. **Configuration initiale** : Exécuter WF0 pour valider la configuration
2. **Import CV** : WF1 avec votre CV (PDF/DOCX)
3. **Collecte offres** : WF2 avec URL ou fichier
4. **Analyse** : WF3 pour scorer l'offre vs votre profil
5. **Génération documents** : WF4-5 pour créer CV adapté et lettre
6. **Brouillon** : WF6 crée le brouillon avec clé unique `APP-xxxxx`
7. **Envoi manuel** : Vous modifiez et envoyez le brouillon
8. **Suivi** : WF10 pour voir le tableau de bord

### Règles importantes

- **Ne jamais supprimer la clé `APP-xxxxx`** de l'objet email (nécessaire au rapprochement)
- **Valider tous les documents générés** avant utilisation
- **Vérifier l'exactitude** du CV adapté (pas d'invention)

## 🔧 Maintenance

### Sauvegarde
```bash
./scripts/backup_db.sh
# Crée : backups/alternance-tracker-YYYY-MM-DD-HHmmss.db
```

### Restauration
```bash
./scripts/restore_db.sh backups/alternance-tracker-2026-10-22-140000.db
```

### Reset complet (⚠️ supprime toutes les données)
```bash
./scripts/reset_db.sh
```

## 🚀 Évolution future

- **Phase 2** : Détection automatique envois/réponses (WF7-8)
- **Phase 3** : Relances automatiques avec contrôles (WF9)
- **Phase 4** : Migration PostgreSQL pour multi-utilisateur
- **Phase 5** : Interface web dédiée

## 📊 Statut du projet

- ✅ **Phase 1** : Audit et architecture (complète)
- 🚧 **Phase 2** : Implémentation MVP en cours
- ⏳ **Phase 3+** : Planifiées

## 🐛 Problèmes connus

Voir [LIMITATIONS.md](docs/LIMITATIONS.md) et [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 📄 Licence

Projet éducatif - Cours M1 - Non destiné à usage commercial

## 👤 Auteur

Projet réalisé dans le cadre du cours d'automatisation M1

---

**Version** : 1.0.0-MVP  
**Dernière mise à jour** : 2026-10-23
