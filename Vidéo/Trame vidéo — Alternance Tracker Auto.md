# Trame vidéo — Alternance Tracker Auto

## Introduction

« Je vous présente Alternance Tracker Auto, un workflow n8n qui interroge des sources d’offres d’alternance, filtre les résultats, les compare au profil du candidat et prépare des brouillons Gmail. Les candidatures ne sont jamais envoyées automatiquement. »

## Déroulé à l’écran

1. **Déclenchement et préférences** — « La recherche démarre automatiquement selon le planning du workflow. Le formulaire séparé permet d’enregistrer des mots-clés, des secteurs ou un nouveau CV PDF. Les préférences restent enregistrées pour les prochaines recherches : il n’est pas nécessaire de remplir le formulaire à chaque fois. »
2. **Profil candidat** — « Le workflow choisit le CV configuré ou en trouve un dans le dossier Drive. Gemini en extrait les informations utiles ; le profil est ensuite validé et enregistré dans Google Sheets. »
3. **Collecte des offres** — « Les deux branches font des requêtes HTTP vers les API de Fantastic Jobs et de La Bonne Alternance, en parallèle. Ce sont des appels à des API : le workflow ne parcourt pas les pages des sites pour en extraire le contenu comme un scraper HTML. Les réponses sont réunies au même point pour permettre d’ajouter d’autres sources. »
4. **État réel des sources** — « Lors de l’exécution consultée le 1er novembre 2026, Fantastic Jobs a répondu HTTP 403 avec un message de quota “jobs” dépassé. La Bonne Alternance a continué sur sa branche indépendante. Cela confirme que la collecte est bien lancée, mais pas que Fantastic Jobs fournit actuellement des offres. Le traitement de contact a été sécurisé : si une offre ne fournit ni domaine d’entreprise ni URL, cette étape est sautée et le traitement continue. »
5. **Filtrage et dédoublonnage** — « Les offres sont harmonisées, puis comparées aux critères enregistrés et aux offres déjà présentes dans la feuille de suivi. La feuille “Offers” contenait 70 lignes lors de l’exécution observée. L’alerte “aucune nouvelle offre” signifie qu’aucune offre n’a atteint la suite du traitement comme nouvelle offre ; elle ne signifie pas nécessairement que les API n’ont renvoyé aucun résultat. À noter : dans la logique actuelle, si moins de cinq offres correspondent aux critères, les autres offres récupérées peuvent compléter la sélection. »
6. **Recherche d’un contact** — « Le workflow reprend une adresse publiée dans l’annonce et peut lire la page publique de l’entreprise si un domaine ou un lien est fourni. Il ne fait pas de recherche Google ou LinkedIn et n’invente aucune adresse. Si aucun contact vérifiable n’est trouvé, le brouillon reste sans destinataire, conserve le lien de candidature lorsqu’il existe et propose d’utiliser ce lien ou le formulaire de contact. Hunter.io serait une source complémentaire, mais nécessite une clé API que le propriétaire doit ajouter dans les identifiants n8n. »
7. **Analyse et brouillons** — « Gemini reçoit une offre à la fois avec le profil du candidat et une consigne de ne pas inventer de faits. Le résultat est validé avant d’être enregistré. Les brouillons sont créés dans Gmail pour relecture manuelle ; aucune candidature n’est envoyée. Le seuil de cinq ne peut être atteint que s’il existe au moins cinq offres distinctes qui arrivent à cette étape. »

## Pourquoi les nœuds Code sont présents

« Les nœuds Code servent surtout à transformer les données et à appliquer les règles propres au projet. Les nœuds HTTP, Google Sheets, Drive et Gmail se chargent des connexions aux services ; le Code organise les données entre ces étapes. »

- **Préférences du formulaire** — `Prepare Search Preferences`, `Build Configuration after CV Upload` et `Build Configuration without CV Upload` valident les champs, conservent les critères précédents lorsqu’ils ne sont pas remplacés et préparent la ligne à enregistrer.
- **Choix et lecture du CV** — `Resolve Search Preferences` transmet la configuration sauvegardée ; `Pick Cv File` choisit le CV approprié ; `Parse Cv Profile` extrait et valide le JSON renvoyé par Gemini avant l’enregistrement.
- **Traitement des annonces** — `Extract Offers` convertit les réponses différentes des deux API en annonces normalisées et élimine les doublons ; `Filter by Candidate Criteria` applique les mots-clés et secteurs ; `Filter New Offers` retire les annonces déjà suivies et ajoute un identifiant de suivi.
- **Contact et préparation du message** — `Enrich Candidate Contact` repère une adresse publiée dans la réponse du site ; `Build Draft Prompt` assemble l’annonce, le profil et les garde-fous transmis à Gemini ; `Parse Draft` contrôle le JSON et rattache chaque réponse à la bonne offre.
- **Création et alertes** — `Select Gmail Drafts` sélectionne les brouillons valides et complète avec un message neutre lorsque la logique actuelle le permet ; `Build No New Offers Alert` explique pourquoi aucune offre n’est retenue ; `Build Search Alert` résume les résultats et erreurs des sources.

## Conclusion

« Le workflow automatise une veille et prépare des brouillons, mais il dépend de la disponibilité et des quotas des API. Les alertes permettent de distinguer une source indisponible d’une absence de nouvelles offres. Le candidat garde la main pour vérifier le destinataire, relire le message et l’envoyer lui-même. »

## Plans de capture suggérés

- Vue d’ensemble du workflow et des deux branches HTTP parallèles.
- Exécution montrant l’erreur de quota Fantastic Jobs et la poursuite de la branche La Bonne Alternance.
- Formulaire des préférences et stockage dans Google Sheets.
- Nœuds Code de normalisation, filtrage, dédoublonnage et contrôle des réponses Gemini.
- Exemple d’alerte « aucune nouvelle offre » et exemple de brouillon Gmail, données personnelles masquées.
- Montrer que `Has Public Contact URL` ignore la recherche de contact lorsque l’offre ne comporte ni domaine ni URL, puis que le brouillon conserve le lien de candidature lorsqu’il est disponible.
