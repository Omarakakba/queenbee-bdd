# Normalisation Jour 2 – Groupe Omar Akakba

## Étape 6.1 · Analyser la table reçue

Les téléphones du sujet n'existent pas dans notre jeu d'essai du jour 1. On les a remplacés par ceux de nos apicultrices (Fatou Ba du sujet = notre Fatou Sow, +221 77 123 45 04).

Les trois tests (0 ligne chacun) :
```sql
SELECT telephone, theme FROM formation_plat GROUP BY telephone, theme HAVING count(DISTINCT formateur) > 1;
SELECT formateur FROM formation_plat GROUP BY formateur HAVING count(DISTINCT theme) > 1;
SELECT telephone, formateur FROM formation_plat GROUP BY telephone, formateur HAVING count(*) > 1;
```

- Dépendances : (telephone, theme) -> formateur et formateur -> theme.
- Clés candidates : (telephone, theme) et (telephone, formateur), car le formateur donne le thème.
- 3NF ? Oui : les trois colonnes font partie d'une clé, aucune colonne non clé ne dépend d'autre chose.
- BCNF ? Non : formateur -> theme part de formateur, qui n'est pas une clé à lui seul.

Anomalie (entre BEGIN et ROLLBACK) : Moussa Sarr passé en capteurs sur la ligne de Fatou Sow, la table accepte.
`Moussa Sarr | {capteurs,varroa}` : un formateur a deux thèmes, la règle est cassée sans message.

## Étape 6.2 · Découper sans perte

Mauvais découpage (telephone, theme) + (theme, formateur) : 16 lignes au lieu de 8, dont 8 inventées. Par exemple Fatou Sow serait suivie en varroa par Moussa Sarr, Ibrahima Fall et Kouassi Yao. La colonne commune theme n'est la clé d'aucun morceau (un thème a plusieurs formateurs), donc la jointure fabrique des lignes.

Bon découpage : formateur (nom unique, theme) et suivi_formation (apicultrice_id, formateur_id). INSERT 0 5 puis INSERT 0 8. La double comparaison EXCEPT donne 0 ligne : rien de perdu, rien d'inventé.

- formateur -> theme est garanti par le UNIQUE sur formateur.nom : un nom n'a qu'une ligne, donc qu'un thème.
- suivi_formation pointe vers apicultrice(id) au lieu de recopier le téléphone : le téléphone peut changer, et une copie pourrait diverger. Avec la clé étrangère, le suivi désigne toujours une apicultrice qui existe.

## Étape 6.3 · La règle perdue et le trigger

Sans trigger, Fatou Sow inscrite chez Ibrahima Fall est acceptée (INSERT 0 1) : elle a deux formateurs varroa (Moussa Sarr et Ibrahima Fall). Plus aucune table ne contient à la fois l'apicultrice et le thème, donc (apicultrice, theme) -> formateur n'est plus vérifiée. Ligne supprimée ensuite.

Avec le trigger suivi_formation_df :
- Fatou Sow chez Ibrahima Fall (varroa) :
  `ERROR:  DF violée : cette apicultrice a déjà un formateur pour ce thème`
- Fatou Sow chez Khady Ndiaye (récolte, nouveau thème pour elle) : `INSERT 0 1`

Correction après retour : en UPDATE, la ligne modifiée se comparait à elle-même. Changer le formateur varroa d'Aminata Diop (Moussa Sarr -> Ibrahima Fall) était refusé à tort. La fonction exclut maintenant la ligne OLD :
- Aminata Diop, Moussa Sarr -> Ibrahima Fall (même thème) : `UPDATE 1`
- Aminata Diop, Khady Ndiaye -> Ibrahima Fall (elle a déjà Moussa Sarr en varroa) : `ERROR:  DF violée : cette apicultrice a déjà un formateur pour ce thème`

Contournement par la table formateur : passer Khady Ndiaye en varroa donnait deux formateurs varroa à Aminata Diop sans erreur, car le trigger ne surveille que suivi_formation. Ajout du trigger formateur_theme_df (BEFORE UPDATE OF theme ON formateur) :
- Khady Ndiaye en varroa : `ERROR:  DF violée : une apicultrice aurait deux formateurs pour ce thème`
- Kouassi Yao en capteurs (Mariam Kone n'a que lui) : `UPDATE 1`

## Étape 6.4 · Revue BCNF du schéma

Règle métier retenue (hypothèse du lab 1) : apicultrice_id -> site_id, une apicultrice n'a qu'un site et ses ruches et son compte sont dessus.

| Table | Dépendances | Partie gauche = super-clé ? | BCNF ? |
|---|---|---|---|
| site | id -> tout | oui | oui |
| cooperative | id -> tout ; code -> tout (UNIQUE) | oui | oui |
| apicultrice | id -> tout ; telephone -> tout (UNIQUE) | oui | oui |
| ruche | id -> tout ; code -> tout (UNIQUE) ; apicultrice_id -> site_id | non pour apicultrice_id | non |
| adhesion | (apicultrice_id, cooperative_id) -> date_adhesion | oui | oui |
| utilisateur | id -> tout ; login -> tout (UNIQUE depuis le lab 4) ; apicultrice_id -> site_id | non pour apicultrice_id (UNIQUE mais peut être NULL, donc pas une clé) | non |
| mesure | id -> tout ; (ruche_id, horodatage) -> tout (UNIQUE) | oui | oui |
| inspection | id -> tout | oui | oui |
| recolte | id -> tout | oui | oui |
| alerte | id -> tout | oui | oui |
| formateur | id -> tout ; nom -> tout (UNIQUE) | oui | oui |
| suivi_formation | (apicultrice_id, formateur_id), clé seule | oui | oui |

apicultrice.site_id et ruche.site_id : la requête montre que chaque apicultrice n'a de ruches que sur son site.
```sql
SELECT a.nom, a.site_id, array_agg(DISTINCT r.site_id)
FROM apicultrice a JOIN ruche r ON r.apicultrice_id = a.id GROUP BY a.id, a.nom, a.site_id;
```
C'est une règle métier, pas une coïncidence. Mais alors ruche.site_id et utilisateur.site_id (pour un compte d'apicultrice) recopient apicultrice.site_id : ruche et utilisateur ne sont pas en BCNF. Rien dans le schéma ne garantit la cohérence, seul le test 7 du lab 2 la contrôle. Pour corriger : retirer site_id de ruche (on le retrouve par l'apicultrice), ou ajouter un trigger qui vérifie que le site de la ruche est celui de son apicultrice.

## Étape 7.1 · Mesurer avant de copier

volume.sql : INSERT 0 47520 (11 ruches x 90 jours x 48).
Notre site SN-CASA n'a que 3 ruches (4 dans le sujet) : 144 mesures par jour au lieu de 192.

Tableau de bord SN-CASA (3 derniers jours) : 144 | 144 | 144 mesures.
EXPLAIN ANALYZE : Seq Scan sur les 48 048 mesures, Execution Time = 19,5 ms.

## Étape 7.2 · La synthèse

Même requête sur synthese_site_jour : mêmes chiffres, Index Scan sur synthese_site_jour_pk, Execution Time = 0,006 ms (au lieu de 19,5 ms).

Vol sur SN-CASA-014 (SN-CASA-011 n'existe pas chez nous), 15 mars 6 h, 8,40 kg :
- avant le REFRESH, la vue s'arrête au 14 mars, rien d'anormal ;
- après REFRESH MATERIALIZED VIEW CONCURRENTLY : `SN-CASA | 2027-03-15 | 1 | 8.40 | 8.40 | 90`.

Si la vue n'est rafraîchie que la nuit, un vol à 6 h reste invisible jusqu'au rafraîchissement suivant, soit environ 18 h (jusqu'à 24 h dans le pire cas). Un vol se détecte donc sur les mesures brutes, au moment où elles arrivent (requête ou trigger sur mesure), pas dans la synthèse qui sert seulement au tableau de bord.

## Étape 7.3 · L'export pour le bailleur

Haché simple du téléphone de Fatou Sow (notre Fatou Ba) : `1e37b0c6...0e7b`. En essayant le million de numéros qui commencent par +221 77 1, on retrouve `+221 77 123 45 04` en 882 ms. Un sha256 sans clé ne protège donc rien.

v_export_bailleur : 8 lignes pour 11 ruches, sans nom ni téléphone, positions comme 12.6 | -16.3. Vérification de la clé dans la définition de la vue : `f`.

Colonnes retirées :
- nom et telephone : ils identifient directement la personne ;
- id de l'apicultrice : remplacé par un HMAC avec clé secrète, impossible à recalculer sans la clé ;
- code de la ruche : avec le site, il permet de retrouver la ruche et sa propriétaire ;
- latitude et longitude exactes : arrondies à 0,1 degré (environ 11 km) pour qu'on ne puisse pas aller voler la ruche ;
- détail des récoltes (dates, quantités, validee_par) : seul le total validé est utile au bailleur, et validee_par désigne un coordinateur.

## Étape 7.4 · Le journal d'audit

1. ligne_id n'est pas une clé étrangère : si la récolte était supprimée, la clé étrangère refuserait la suppression ou effacerait les lignes du journal avec elle (CASCADE). Or le journal doit justement garder la trace d'une ligne supprimée. Et il surveille plusieurs tables, une seule clé étrangère ne suffirait pas.
2. Oui. C'est une copie voulue : le journal garde l'état de la ligne au moment de l'action, c'est la preuve. Il n'est jamais modifié, donc la copie ne peut pas diverger. Il contient des données personnelles, d'où le REVOKE ALL.
3. now() donne l'heure du début de la transaction : toutes les actions d'une même transaction auraient la même heure, on ne pourrait plus les ordonner. clock_timestamp() donne l'heure réelle de chaque action.
