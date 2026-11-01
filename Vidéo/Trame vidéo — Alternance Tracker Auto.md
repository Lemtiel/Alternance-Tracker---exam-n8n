# Trame vidéo — Alternance Tracker Auto

## Introduction

« Je vous présente Alternance Tracker Auto, un workflow n8n qui recherche des offres d’alternance, les compare au profil du candidat et prépare des brouillons de candidature. »

## Déroulé à l’écran

1. **Déclenchement et préférences** — « Une recherche démarre chaque jour à 8 h. Un formulaire indépendant permet de saisir les mots-clés et secteurs recherchés, et de remplacer le CV avec un PDF. Les critères et le CV sont conservés : le formulaire n’est pas à remplir à chaque exécution. »
2. **Lecture du profil** — « Le workflow utilise le dernier CV enregistré dans Drive, ou celui du dossier configuré. Gemini en extrait les informations utiles, puis le profil est enregistré dans Google Sheets. »
3. **Sources en parallèle** — « Fantastic Jobs et La Bonne Alternance sont interrogés simultanément. La fenêtre Fantastic Jobs est réglée sur 24 heures pour correspondre à la recherche quotidienne, avec un maximum de 50 résultats demandés. Les branches rejoignent le même point de fusion, où l’on pourra raccorder d’autres sources. »
4. **Résilience et alertes** — « Une erreur ou un quota dépassé chez Fantastic Jobs ne bloque pas les résultats de La Bonne Alternance. Une alerte détaille les réponses de chaque source si l’une échoue ou si aucune offre n’est reçue. D’autres alertes expliquent l’absence de critères, l’absence de correspondance ou l’absence de nouvelle offre. »
5. **Filtrage et contacts** — « Après normalisation, le workflow garde uniquement les offres qui correspondent à au moins un mot-clé ou secteur, puis écarte celles déjà enregistrées. Il recherche une adresse de contact publiée par l’entreprise ; s’il n’en trouve pas, il ne l’invente pas. »
6. **Analyse et brouillons** — « Gemini évalue chaque nouvelle offre correspondante par rapport au CV. Il peut recommander de passer une offre ; celles retenues produisent un brouillon Gmail et une ligne de suivi. Le nombre d’offres n’est plus plafonné artificiellement ; le volume d’appels Gemini dépend donc des offres filtrées. »

## Conclusion

« Le workflow automatise la veille et la préparation, tout en laissant la décision finale au candidat : les messages sont des brouillons à relire et à envoyer manuellement. Le système envoie des alertes de fonctionnement, mais n’envoie jamais automatiquement les emails de candidature. »

## Plans de capture suggérés

- Vue d’ensemble du workflow, puis zoom sur les deux branches de recherche et leur nœud de fusion.
- Formulaire de préférences et réglages persistés.
- Branche de création du profil à partir du CV.
- Branche de filtrage, recherche de contact, comparaison avec Gemini et création du brouillon Gmail.
- Alertes de source défaillante, de quota atteint et d’absence de nouvelles offres.
- Tableur de suivi et exemple de brouillon, en masquant les données personnelles.
