# Trame vidéo — Alternance Tracker Auto

## Introduction

« Je vous présente Alternance Tracker Auto, un workflow n8n qui recherche des offres d’alternance, les compare au profil du candidat et prépare des brouillons de candidature. »

## Déroulé à l’écran

1. **Déclenchement et réglages** — « Le workflow se lance chaque jour à 8 h. Le nœud Settings centralise les critères de recherche : mots-clés, localisation, rayon, niveau de diplôme et période. »
2. **Lecture du profil** — « Il récupère le CV depuis Google Drive, en extrait les informations utiles avec Gemini, puis enregistre le profil dans Google Sheets. »
3. **Recherche en parallèle** — « Fantastic Jobs et La Bonne Alternance sont interrogés simultanément. Leurs résultats sont réunis au même endroit ; on peut ajouter d’autres sources en leur donnant une branche vers ce point de fusion. »
4. **Résilience et alertes** — « Une erreur ou un quota dépassé sur une source ne bloque pas les résultats de l’autre. Si aucune source ne fournit d’offre, un email récapitule l’état de chaque service et les vérifications à faire. Une autre alerte signale quand il n’y a aucune nouvelle offre exploitable, par exemple après dédoublonnage. »
5. **Sélection et suivi** — « Les offres déjà enregistrées sont écartées. Les nouvelles sont limitées selon les réglages, puis ajoutées au tableur avec leur statut et leurs informations de suivi. »
6. **Préparation des candidatures** — « Gemini évalue la correspondance entre le CV et chaque offre, puis rédige un sujet et un message à partir des seules informations vérifiables du profil. Les candidatures retenues sont enregistrées dans le suivi et préparées dans Gmail. »

## Conclusion

« Le workflow automatise la veille et la préparation, tout en laissant la décision finale au candidat : les messages sont des brouillons à relire et à envoyer manuellement. Le système envoie des alertes de fonctionnement, mais n’envoie jamais automatiquement les emails de candidature. »

## Plans de capture suggérés

- Vue d’ensemble du workflow, puis zoom sur les deux branches de recherche et leur nœud de fusion.
- Nœud Settings et les critères de recherche.
- Branche de création du profil à partir du CV.
- Branche de sélection, comparaison avec Gemini et création du brouillon Gmail.
- Tableur de suivi et exemple de brouillon, en masquant les données personnelles.
