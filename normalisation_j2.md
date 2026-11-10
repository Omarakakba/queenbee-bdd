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

## Étape 6.4 · Revue BCNF du schéma

| Table | Dépendances | Partie gauche = super-clé ? | BCNF ? |
|---|---|---|---|
| site | id -> nom, pays | oui | oui |
| cooperative | id -> tout ; code -> tout (UNIQUE) | oui | oui |
| apicultrice | id -> tout ; telephone -> tout (UNIQUE) | oui | oui |
| ruche | id -> tout ; code -> tout (UNIQUE) | oui | oui |
| adhesion | (apicultrice_id, cooperative_id) -> date_adhesion | oui | oui |
| utilisateur | id -> tout ; apicultrice_id -> tout (UNIQUE) | oui | oui |
| mesure | id -> tout ; (ruche_id, horodatage) -> tout (UNIQUE) | oui | oui |
| inspection | id -> tout | oui | oui |
| recolte | id -> tout | oui | oui |
| alerte | id -> tout | oui | oui |
| formateur | id -> tout ; nom -> theme (UNIQUE) | oui | oui |
| suivi_formation | (apicultrice_id, formateur_id) : clé seule | oui | oui |

apicultrice.site_id et ruche.site_id : la requête montre que chaque apicultrice n'a de ruches que sur son site.
```sql
SELECT a.nom, a.site_id, array_agg(DISTINCT r.site_id)
FROM apicultrice a JOIN ruche r ON r.apicultrice_id = a.id GROUP BY a.id, a.nom, a.site_id;
```
C'est une règle métier (notre hypothèse du lab 1 : une apicultrice n'a qu'un site et ses ruches sont dessus), pas une coïncidence. Mais rien dans le schéma ne la garantit : ruche.site_id est une copie qui peut diverger. Aujourd'hui, seul le test 7 du lab 2 la contrôle ; il faudrait un trigger ou supprimer ruche.site_id.
