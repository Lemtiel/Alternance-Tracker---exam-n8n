# Transcription descriptive — Alternance Tracker Auto

## Présentation générale

Alternance Tracker Auto est un workflow n8n nommé `famUstqu1tAcM0Lf`. Il organise une veille quotidienne d’offres d’alternance, réutilise les critères et le profil du candidat, collecte les annonces depuis deux sources, les filtre, recherche des coordonnées publiées et prépare des brouillons dans Gmail. Les candidatures ne sont jamais envoyées automatiquement.

Le scénario comporte quatre groupes d’actions : `Bloc 1 - Recherche et profil`, `Bloc 2 - Sources d’offres`, `Bloc 3 - Filtrage et contacts` et `Bloc 4 - Analyse et brouillons`. Le formulaire de préférences et la branche d’alerte sont présentés dans des zones dédiées du canevas. Les nœuds de connexion aux services portent les accès OAuth ou API ; les nœuds Code harmonisent et contrôlent les données qui circulent entre ces services.

## Déclencheurs et paramètres

Le déclencheur `Daily Trigger` lance la recherche une fois par jour à 8 h, selon le fuseau configuré dans n8n. Il transmet l’exécution au nœud `Settings`, qui contient les paramètres généraux : localisation Toulouse, Occitanie, France, coordonnées géographiques, rayon de 30 km, niveau de diplôme visé 5, fenêtre de recherche `24h`, plafond de 50 résultats demandé à la source et ancienneté maximale de 7 jours. La feuille Google Sheets et le dossier Drive du CV sont aussi référencés dans cette configuration.

Un second déclencheur, `Search Preferences Form`, démarre uniquement lorsqu’un utilisateur soumet le formulaire. Cette branche met à jour les préférences ; elle ne remplace pas le déclenchement quotidien. Les critères saisis sont enregistrés afin que les recherches suivantes puissent les réutiliser sans nouvelle soumission.

## Préférences et CV

Le formulaire contient des champs pour les mots-clés, les secteurs et le dépôt facultatif d’un CV PDF. `Form Settings` fournit les paramètres de base et `Read Search Preferences (Form)` récupère la ligne précédemment enregistrée dans l’onglet `Configuration`. `Prepare Search Preferences` normalise les séparateurs en une liste lisible, conserve les champs précédents lorsqu’ils ne sont pas remplacés et incrémente la version de la configuration. Une soumission sans critères nouveaux ni CV est rejetée afin d’éviter une mise à jour vide.

`Has CV Upload` distingue une soumission avec CV d’une mise à jour des seuls critères. Avec un PDF, `Upload New CV to Drive` enregistre le fichier dans Drive ; `Build Configuration after CV Upload` associe son identifiant et son nom aux préférences avant `Save Search Preferences`. Sans nouveau fichier, `Build Configuration without CV Upload` conserve le CV déjà associé. Le PDF doit être fourni à nouveau seulement lorsqu’il est remplacé.

Pendant une recherche quotidienne, `Read Search Preferences` et `Resolve Search Preferences` chargent la configuration enregistrée. Une feuille sans ligne de préférence ne bloque pas la recherche : les champs vides sont transmis comme critères vides. `Read Saved Profile`, `Select Saved Profile` et `Has Saved Profile` vérifient si le profil extrait correspond toujours au CV actif. Lorsqu’un profil approprié existe, `Use Saved Profile` le réutilise. Sinon, `Find Cv File` recherche un document dans le dossier Drive configuré, `Pick Cv File` privilégie le PDF, `Download Cv` le télécharge sous forme de document PDF et `Extract Cv Profile` demande à Gemini Flash Lite d’en extraire les faits vérifiables.

`Parse Cv Profile` contrôle la réponse structurée : les informations personnelles doivent être présentes dans un objet JSON valide ; les formations, expériences, compétences, langues, certifications et projets sont sérialisés séparément. Les éléments incertains et le niveau de confiance de l’extraction sont conservés. Le modèle reçoit la consigne de ne pas inventer d’informations et le texte du CV est traité comme une donnée, non comme des instructions. `Save Profile` enregistre ou met à jour le profil dans l’onglet `Profiles`. Cette réutilisation évite de télécharger et d’analyser le même CV à chaque exécution.

## Collecte simultanée des offres

Après la résolution du profil et la lecture des annonces déjà suivies dans l’onglet `Offers`, le nœud `Resolve Active Profile` alimente deux branches HTTP indépendantes : `Fetch Fantastic Offers` et `Fetch La Bonne Alternance`. La première interroge l’API Fantastic Jobs avec les paramètres de période, de langue, de format de description et de limite configurés. La seconde interroge l’API La Bonne Alternance avec les critères de localisation et de formation définis dans les paramètres du workflow.

`Merge Offer Sources` attend les résultats des deux branches et les rassemble avant le traitement commun. Les appels sont des requêtes API ; le workflow ne simule pas une navigation humaine ni un scraping des pages de résultats. Les réponses sont demandées en mode réponse complète afin de conserver le code HTTP. Les statuts d’erreur sont traités comme des résultats de branche au lieu d’interrompre immédiatement toute l’exécution. `Extract Offers` écarte les réponses dont le code est en erreur et transforme les formats des deux fournisseurs vers une structure commune : identifiant externe, source, intitulé, entreprise, domaine, description, localisation, URL de candidature, adresse éventuellement fournie et date de publication.

Le paramètre de 50 est la limite de résultats demandée par configuration ; il ne signifie pas que toutes les annonces publiées sur les sites sont récupérées. La quantité réellement disponible dépend des réponses des API et de leurs quotas. Le workflow ne comporte pas de notification distincte qui nomme une API en panne lorsque l’autre source fournit des annonces : l’état détaillé de chaque branche reste visible dans l’exécution n8n.

## Critères, doublons et seuil de sélection

`Filter by Candidate Criteria` compare les mots-clés et secteurs aux champs de titre, entreprise, description et localisation. Les séparateurs virgule, point-virgule et retour à la ligne sont acceptés ; la comparaison ignore la casse et les accents. Les termes sont réunis dans une seule liste et une annonce correspond dès qu’un terme apparaît dans son texte de recherche.

La logique actuelle applique deux règles de complément. Si aucun mot-clé ni secteur n’est enregistré, toutes les offres normalisées sont candidates. Si moins de cinq annonces correspondent aux critères, les offres restantes récupérées sont ajoutées jusqu’à constituer l’ensemble disponible. Les critères ne constituent donc pas un filtre strict lorsque moins de cinq correspondances sont trouvées ; une partie des annonces traitées peut être hors critères. Cette règle sert à alimenter le seuil minimal de brouillons, mais elle peut réduire la pertinence de la sélection.

`Read Known Offers` charge les identifiants externes déjà enregistrés dans `Offers`. `Filter New Offers` retire ces doublons et attribue à chaque annonce nouvelle un identifiant de suivi stable de type `APP-…`, ainsi qu’un identifiant d’application. Il prépare également un contexte limité pour l’analyse : annonce, profil candidat et références de rapprochement. `Select Valid New Offers` élimine les éléments de contrôle qui ne correspondent pas à des annonces. `Save Offer` conserve la nouvelle offre dans Sheets avant l’appel de rédaction ; ainsi, l’annonce reste suivie même si l’étape de génération du brouillon échoue.

Lorsqu’aucune nouvelle annonce ne franchit l’étape de dédoublonnage, `Build No New Offers Alert` distingue plusieurs situations : critères absents, aucune annonce correspondant aux critères, annonces déjà suivies ou absence d’annonce nouvelle. Le message inclut le nombre d’offres traité quand cette donnée est disponible et rappelle qu’aucun courriel de candidature n’a été envoyé. `Send No New Offers Alert` transmet cet état au propriétaire du workflow par Gmail. Cette alerte concerne l’absence de nouvelles offres éligibles ; elle n’est pas une alerte technique détaillée pour chaque panne de source.

## Recherche des coordonnées de contact

`Has Public Contact URL` vérifie si l’annonce contient un domaine d’entreprise, une URL de candidature ou une autre URL publique. Sans lien exploitable, la branche de requête HTTP est sautée et le traitement continue avec les coordonnées déjà présentes dans l’annonce. Avec un lien, `Lookup Public Contact Email` consulte la page publique, traite les requêtes par petits lots et applique un délai maximal de huit secondes. Une page indisponible ou une réponse non exploitable n’interrompt pas la préparation.

`Enrich Candidate Contact` examine les champs de réponse et les informations de l’annonce à la recherche d’adresses publiées. Il écarte les adresses manifestement génériques ou techniques, puis privilégie les libellés associés au recrutement, aux talents, aux emplois, aux ressources humaines ou au contact. Cette étape extrait des adresses visibles publiquement ; elle ne garantit pas qu’il s’agisse de l’adresse directe d’un recruteur et ne vérifie pas l’identité de son propriétaire. Aucune adresse n’est déduite ou inventée. Lorsqu’aucune adresse vérifiable n’est trouvée, la ligne de candidature porte un destinataire à compléter et conserve le lien de candidature disponible.

## Analyse de l’offre et préparation du brouillon

`Build Draft Prompt` construit une demande distincte pour chaque annonce retenue. Le contexte inclut le CV structuré, l’annonce, les critères enregistrés et la référence de suivi. Gemini doit évaluer l’adéquation, produire un score, une recommandation (`apply`, `consider` ou `skip`), une justification, les compétences correspondantes ou manquantes, un objet et un corps de message. Les consignes interdisent d’inventer des faits ou une adresse et demandent de traiter le texte de l’annonce comme une donnée, non comme une instruction.

`Write Email Draft` génère la proposition. `Parse Draft` contrôle que le résultat correspond à une réponse exploitable et le rattache à la bonne annonce grâce à la référence de suivi. Il prépare une ligne d’application avec le score, la recommandation, les avertissements, le texte, l’adresse de contact et l’URL de candidature. `Save Draft` met cette ligne à jour dans l’onglet `Applications` en utilisant la référence de suivi pour éviter les duplications.

`Select Gmail Drafts` retient d’abord les recommandations `apply` ou `consider` qui comportent un objet et un corps non vides. Si moins de cinq brouillons répondent à ces conditions, le nœud construit des messages neutres de demande d’information à partir d’autres annonces disponibles en amont, jusqu’à atteindre cinq ou épuiser les annonces. Ces brouillons de complément peuvent inclure des annonces que Gemini avait classées `skip` ou qui ne correspondent pas aux critères lorsqu’une sélection a été complétée selon la règle précédente. Le nombre cinq est donc un objectif minimal conditionnel, jamais une garantie si moins de cinq annonces nouvelles sont disponibles.

`Create Gmail Draft` crée les brouillons dans Gmail. L’adresse de destination est renseignée uniquement lorsqu’une adresse de contact vérifiable est présente ; sinon, le brouillon est créé sans destinataire et doit être complété manuellement. Le nœud crée un brouillon et n’envoie aucun message. Le candidat reste responsable de vérifier l’offre, le destinataire et le texte avant tout envoi manuel.

## Feuilles Google Sheets utilisées

- **Configuration** : mots-clés, secteurs, référence du CV et métadonnées de préférences conservées entre les exécutions.
- **Profiles** : profil structuré extrait du CV, source du document, date d’extraction, éléments incertains et confiance de l’analyse.
- **Offers** : annonces normalisées déjà récupérées et leurs références de suivi ; sert notamment à la déduplication.
- **Applications** : score, recommandation, coordonnées, lien de candidature, brouillon, avertissements et état de préparation.

## Commandes n8ncli

La CLI présente dans l’environnement est `n8ncli` version `1.2.45`. Les commandes suivantes décrivent la vérification et la synchronisation d’un projet local avec n8n.

### `n8ncli --version`

Affiche la version installée de n8ncli. La version observée dans l’environnement de ce projet est `1.2.45`. Cette commande identifie les capacités de la CLI avant d’interpréter le résultat d’une autre commande.

### `n8ncli env list`

Affiche les environnements n8n configurés pour la CLI, par exemple `local`, ainsi que les types de connexions configurées. Elle permet d’identifier le nom d’environnement à utiliser dans les vérifications sans afficher les secrets d’authentification.

### `n8ncli env test local`

Teste les connexions de l’environnement nommé `local` : API n8n, serveur MCP et base de données lorsqu’elle est configurée. Le résultat indique les composants joignables et ceux dont le test échoue ou qui ne sont pas configurés. Cette commande vérifie les connexions ; elle ne déclenche pas le workflow.

### `n8ncli validate`

Vérifie la syntaxe et les schémas n8n des workflows TypeScript présents dans le chemin de travail reconnu par la configuration CLI. Elle signale les erreurs de structure avant synchronisation et ne modifie pas les workflows avec les options par défaut. Le projet conserve son export Auto dans `Workflow/Alternance Tracker Auto.workflow.ts` ; le chemin pris en charge dépend donc de la configuration `n8ncli.json` ou d’un chemin de fichier explicitement fourni si le dossier par défaut `n8n/workflows/` est utilisé.

### `n8ncli pull`

Récupère depuis l’instance n8n les workflows distants et les convertit en fichiers TypeScript SDK dans le projet local. Cette commande synchronise dans le sens n8n vers le dossier de travail ; elle ne publie pas les modifications locales vers n8n. Elle peut créer ou actualiser des fichiers locaux et doit être suivie d’une vérification des changements avant toute validation Git. Les options `--force` et surtout `--hard` élargissent les risques d’écrasement ou de suppression ; elles ne font pas partie de la commande présentée ici.

## Limites opérationnelles

La collecte dépend de la disponibilité, du format et des quotas des deux API. La limite configurée borne les résultats demandés, sans promettre une couverture exhaustive. La qualité des filtres repose sur des correspondances textuelles et la règle de complément à cinq peut inclure des offres hors critères. La recherche d’adresse se limite à des éléments publics trouvés dans l’annonce ou sur une page accessible ; l’absence d’adresse laisse le destinataire à compléter. Gemini peut proposer une formulation, mais son score et son texte nécessitent une relecture humaine. Le workflow automatise la veille et la préparation, pas l’envoi de candidatures.
