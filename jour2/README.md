# Queen Bee – Dossier de conception, jour 2 – Groupe Omar Akakba

## Les 5 parties
1. Schéma normalisé : 1_schema_normalise/
2. Rôles et privilèges : 2_roles_privileges/ (4 rôles, 7 vues, 1 fonction de validation)
3. Trigger d'audit : 3_trigger_audit/ (tables auditées : recolte, utilisateur)
4. Test de concurrence : 4_test_concurrence/ (2 sessions avant, 1 après)
5. Revue de sécurité : 5_revue_securite/ (3 failles et 6 constats, tous corrigés)

## Reconstruire (après la base du jour 1, avec -v ON_ERROR_STOP=1)
Base du jour 1, depuis la racine du dépôt : schema.sql, donnees.sql, plat.sql, puis contraintes.sql (sans ON_ERROR_STOP : ses erreurs sont des tests voulus, et il rend les logins uniques).

1. formation.sql   2. volume.sql (une fois)   3. denormalisation.sql
4. references.sql puis check.sql   5. audit.sql   6. roles.sql
7. jeton.sql   8. corrections.sql

## Nos choix principaux
- BCNF + trigger pour les formations, parce que le découpage perd la règle « une apicultrice, un formateur par thème » ; un second trigger bloque le changement de thème d'un formateur qui casserait cette règle.
- La synthèse est rafraîchie toutes les heures pour le tableau de bord ; le vol est détecté sur les mesures brutes, à leur arrivée, pas dans la synthèse.
- Personne n'a de droit direct sur les tables : chaque rôle passe par des vues filtrées par qui(), en security_barrier, et la validation d'une récolte passe par une fonction SECURITY DEFINER.
- Les preuves (mesures, inspections, récoltes, alertes) sont en RESTRICT ; seules les adhésions partent en CASCADE.
- Les noms du sujet ont été adaptés à notre jeu d'essai du jour 1 (f.ba -> a.diop, coord.sn -> coord.casa, Fatou Ba -> Fatou Sow) ; chaque adaptation est notée dans le fichier concerné.

## Limites connues
- un superutilisateur peut désactiver les triggers du journal : le journal doit aussi être copié hors de la base, vers le SIEM.
- les triggers du lab 6 sont des « vérifier, puis agir » : deux insertions simultanées peuvent les contourner ; une contrainte UNIQUE (apicultrice_id, theme) serait plus sûre.
- les anciens mots de passe de test restent dans l'historique Git : ils ont été supprimés de la base (PASSWORD NULL).
- les rôles ne sont pas dans pg_dump : il faut aussi pg_dumpall --roles-only.
