# Revue de sécurité de notre base – Groupe Omar Akakba

Adaptations : f.ba -> a.diop (Aminata Diop, SN-CASA) pour les sessions ; « le téléphone de Fatou Ba » -> celui de Fatou Sow. SN-CASA a 3 ruches chez nous (4 dans le sujet).

## Synthèse
Contrôles passés : 6 / 12 avant corrections, 12 / 12 après.
Constats : 2 critiques, 0 haute, 2 moyennes, 2 basses. Tous corrigés et retestés.

## Notre propre code : failles démontrées (étapes 10.1 et 10.2)

| ID | Faille | Preuve | Correction | Retest |
|----|--------|--------|------------|--------|
| P1 | injection par le tri dans recherche_vuln.py | site `SN-CASA`, tri `cast((SELECT telephone FROM apicultrice WHERE nom = 'Fatou Sow') AS int)` -> `Erreur : invalid input syntax for type integer: "+221 77 123 45 04"`. À l'aveugle : `CASE WHEN (SELECT substr(telephone, 6, 2) FROM apicultrice WHERE nom = 'Fatou Sow') = '77' THEN code ELSE longitude::text END` -> ordre 014, 015, 099 ; avec `'78'` -> ordre 099, 015, 014 : l'ordre répond oui ou non. Empilée : `code; DROP TABLE journal_audit` -> `cannot insert multiple commands into a prepared statement` | recherche.py : liste blanche de deux colonnes, sql.Identifier, l'erreur de la base n'est plus affichée | même saisie par erreur -> `Tri refusé : choisissez code ou date_installation` |
| P2 | vue v_carte_ruches trop large | en a.diop : `SELECT nom, telephone FROM apicultrice` -> `permission denied for table apicultrice` ; `SELECT code, nom, telephone FROM v_carte_ruches` -> 11 lignes, tous les téléphones. La vue s'exécute avec les droits de postgres : élévation de privilège | corrections.sql : vue réécrite, ses ruches seulement, sans nom ni téléphone, avec security_barrier | `SELECT * FROM v_carte_ruches` -> 2 lignes (SN-CASA-014, SN-CASA-015), sans téléphone |
| P3 | fuite par fonction espion | en a.diop : fonction `pg_temp.espion(code, latitude, longitude)` qui fait RAISE NOTICE, puis `SELECT code FROM v_mes_ruches WHERE pg_temp.espion(code, latitude, longitude)` -> résultat de 2 lignes, mais 11 NOTICE avec la position GPS de toutes les ruches | corrections.sql : security_barrier sur les 6 vues filtrantes, REVOKE TEMPORARY sur la base | même session : 2 NOTICE seulement (ses ruches) ; nouvelle session : `permission denied to create temporary tables in database "queenbee"` |

## Grille de contrôle

| N° | Contrôle | Résultat avant | Après |
|---|---|---|---|
| C1 | aucune fonction exécutable par PUBLIC | mon_apicultrice (R1) | 0 ligne |
| C2 | search_path fixé dans les SECURITY DEFINER | audit_ligne, mon_apicultrice, valider_recolte : `search_path=public, pg_temp` | passé |
| C3 | vues filtrantes = barrières | aucune (R2) | les 6 vues filtrantes + v_carte_ruches. v_export_bailleur et v_ruche_coordinateur (vue Q5 du jour 1) n'en ont pas : elles ne filtrent pas par utilisateur, la première n'est donnée qu'au gestionnaire et la seconde à personne, ce n'est pas une faute |
| C4 | aucune vue hors périmètre | v_carte_ruches montre tout (R3) | chaque vue lue en a.diop ne montre que ses lignes |
| C5 | journal en ajout seul | UPDATE, DELETE, TRUNCATE refusés | passé |
| C6 | le journal nomme le vrai acteur | a.diop / recolte / INSERT, coord.casa / recolte / UPDATE | passé |
| C7 | pas d'écriture chez une autre | test 4 du lab 8 : `new row violates check option` | passé |
| C8 | un jeton ne sert qu'une fois | course_jeton.py sur un jeton neuf : 1 session (UNIQUE) | passé |
| C9 | pas de requête construite par + ou f" | query_vuln.py et recherche_vuln.py (R4) | conservés comme démonstrations, marqués en tête de fichier |
| C10 | les preuves ne partent pas en cascade | mesure, inspection, recolte, alerte : RESTRICT | passé |
| C11 | pas de mot de passe dans le dépôt | `git grep -i password` -> roles.sql (R5) | 0 résultat |
| C12 | la base se reconstruit avec nos fichiers | roles.sql : `role "qb_apicultrice" already exists` (R6) | reconstruction complète sans ERROR, mêmes résultats aux 12 tests de contournement |

## Constats de la grille

| ID | Contrôle | Gravité | Constat | Preuve (commande et résultat) | Correction | Retest |
|----|----------|---------|---------|-------------------------------|------------|--------|
| R1 | C1 | moyenne | mon_apicultrice() (créée dans roles.sql après le REVOKE général) est exécutable par PUBLIC | `SELECT proname FROM pg_proc WHERE pronamespace = 'public'::regnamespace AND has_function_privilege('public', oid, 'EXECUTE');` -> mon_apicultrice | REVOKE ALL ON FUNCTION mon_apicultrice() FROM PUBLIC ; ALTER DEFAULT PRIVILEGES … REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC pour les fonctions futures | même requête -> 0 ligne |
| R2 | C3 | critique | aucune vue filtrante n'est une barrière : une fonction de l'utilisateur voit toutes les lignes (P3) | requête C3 : reloptions vides ; démonstration P3 : 11 positions GPS | security_barrier = true sur v_moi, v_mes_ruches, v_mes_mesures, v_mes_recoltes, v_ruches_site, v_recoltes_site ; REVOKE TEMPORARY | requête C3 : security_barrier=true ; espion : 2 lignes vues |
| R3 | C4 | critique | v_carte_ruches donne nom et téléphone de toutes les apicultrices à toute apicultrice (P2) | en a.diop : `SELECT code, nom, telephone FROM v_carte_ruches` -> 11 lignes | vue réécrite (ses ruches, sans nom ni téléphone) | 2 lignes, colonnes code, latitude, longitude |
| R4 | C9 | basse | deux scripts construisent la requête par concaténation | `grep -n '" +' *.py` -> query_vuln.py, recherche_vuln.py | ce sont les démonstrations demandées par le TP : gardées, marquées « ne jamais utiliser », versions sûres à côté (query.py, recherche.py) | les autres scripts utilisent %s ou sql.Identifier |
| R5 | C11 | moyenne | des mots de passe de comptes de la base étaient dans roles.sql, dépôt public | `git grep -i password` -> 5 lignes CREATE ROLE … PASSWORD | roles.sql sans mot de passe (définis à part, dans psql) ; comme ils restent dans l'historique Git, il faut les changer (ALTER ROLE … PASSWORD) | `git grep -i password` -> rien |
| R6 | C12 | basse | roles.sql ne se rejoue pas : les rôles sont communs au serveur, et le nom de la base était écrit en dur | reconstruction dans une base vide avec -v ON_ERROR_STOP=1 -> `ERROR: role "qb_apicultrice" already exists` | rôles créés seulement s'ils n'existent pas (bloc DO), GRANT de groupe séparé, current_database() au lieu de queenbee | reconstruction complète sans ERROR, tests de contournement identiques |
