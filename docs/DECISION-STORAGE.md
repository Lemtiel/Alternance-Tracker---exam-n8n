# Décision technique : Stockage MVP

## Contexte

Lors de l'implémentation, nous avons rencontré des obstacles techniques avec SQLite :
- SQLite3 non disponible dans l'image Docker n8n standard
- Installation de modules natifs (better-sqlite3) bloquée par permissions
- SQLite non installé sur la machine hôte Windows

## Décision : Google Sheets pour MVP

Pour accélérer le développement et obtenir un MVP fonctionnel rapidement, nous adoptons **Google Sheets** comme stockage initial.

### Avantages dans le contexte MVP
✅ **Intégration native n8n** : Nodes Google Sheets disponibles et testés  
✅ **Pas d'infrastructure supplémentaire** : Pas de volume, pas d'installation  
✅ **Interface utilisateur immédiate** : Visualisation et édition faciles  
✅ **Partage simple** : Collaboration facile si nécessaire  
✅ **Rapidité d'implémentation** : API simple, documentation complète  

### Limitations acceptées pour MVP
⚠️ **Concurrence limitée** : Un seul workflow writer à la fois (géré par queue)  
⚠️ **Contraintes d'intégrité faibles** : Gérées par la logique workflow  
⚠️ **Performances limitées** : Acceptable pour volume MVP (<100 candidatures)  
⚠️ **Dépendance Google API** : Quotas et disponibilité  

### Mitigation des limitations

1. **Queue de workflows** : Serialisation explicite des workflows critiques
2. **Validation côté workflow** : Vérifications strictes avant insert/update
3. **Retry avec backoff** : Gestion des rate limits API
4. **Cache local** : Minimiser les appels API répétitifs
5. **Logs détaillés** : Traçabilité de toutes les opérations

## Structure Google Sheets

### Workbook : "Alternance Tracker"

**Sheet 1 : Users**
| id | email | display_name | created_at | updated_at |

**Sheet 2 : Configuration**
| id | user_id | version | gmail_enabled | drive_enabled | llm_provider | ... |

**Sheet 3 : Profiles**
| id | user_id | version | source_filename | personal_info_json | education_json | ... |

**Sheet 4 : Offers**
| id | user_id | title | company_name | company_domain | description | ... |

**Sheet 5 : Offer_Analyses**
| id | offer_id | profile_id | score | recommendation | rationale | ... |

**Sheet 6 : Applications**
| id | user_id | offer_id | tracking_ref | status | sent_at | ... |

**Sheet 7 : Documents**
| id | application_id | document_type | format | storage_id | filename | ... |

**Sheet 8 : Messages**
| id | user_id | provider | message_id | subject | from_email | ... |

**Sheet 9 : Events**
| id | user_id | entity_type | entity_id | event_type | occurred_at | ... |

**Sheet 10 : Workflow_Locks**
| workflow_name | locked_at | locked_by | expires_at |

### Conventions

- **Première ligne** : En-têtes de colonnes (noms de champs)
- **Ligne 2+** : Données
- **Colonnes JSON** : Suffixe `_json` pour données structurées (stockées en JSON string)
- **Dates** : Format ISO 8601 UTC (YYYY-MM-DDTHH:mm:ss.sssZ)
- **Booléens** : "TRUE" / "FALSE" (strings)
- **NULL** : Cellule vide

## Migration future vers SQLite/PostgreSQL

Le schéma SQL (`schemas/v1_initial.sql`) est conservé et servira de base pour la migration.

### Script de migration (futur)
```javascript
// Pseudo-code
1. Exporter toutes les sheets en JSON
2. Créer base SQLite/PostgreSQL
3. Appliquer schéma v1_initial.sql
4. Importer données avec mapping
5. Valider intégrité
6. Basculer workflows
7. Archiver Google Sheets
```

### Quand migrer ?

Migrer vers SQLite/PostgreSQL si :
- Volume > 100 candidatures
- Besoin multi-utilisateurs
- Performance devient limitante
- Requêtes complexes nécessaires (JOINs, agrégations)
- Contraintes d'intégrité critiques

## Implémentation immédiate

1. ✅ Créer Google Sheet avec structure définie
2. ✅ Configurer credentials Google dans n8n
3. ✅ Créer helpers pour CRUD operations
4. ✅ Implémenter queue de workflows
5. ✅ Tester avec données fictives

## Date de décision : 2026-10-22

**Raison** : Pragmatisme - délivrer un MVP fonctionnel rapidement sans bloquer sur l'infrastructure  
**Validé par** : Analyse coût/bénéfice pour contexte pédagogique et démonstration  
**Réversible** : Oui, migration documentée et planifiable
