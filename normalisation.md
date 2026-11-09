# Normalisation – Groupe Omar Akakba

## Les anomalies et la dépendance qui les cause
| Anomalie | Ce qu'on a vu | Dépendance responsable |
|---|---|---|
| Mise à jour | « Senegal » modifié sur une seule ligne : SN-KOLD a deux pays, l'enquête passe de 3 à 4 pays | site_id -> site_nom, pays (le pays est recopié sur les 528 lignes) |
| Mise à jour | le téléphone de Fatou Sow modifié sur une ligne : la ruche SN-KOLD-012 a deux téléphones | ruche_code -> site_id, telephone et telephone -> apicultrice, cooperative |
| Suppression | en effaçant les mesures de SN-CASA-099, le téléphone d'Awa Diop disparaît de la base | telephone -> apicultrice, cooperative (l'apicultrice n'existe qu'à travers ses mesures) |
| Insertion | impossible d'ajouter le site CI-KORH tant qu'il n'a ni ruche ni mesure (ruche_code ne peut pas être vide) | site_id -> site_nom, pays (le site est coincé dans une table dont la clé est la mesure) |

## Classement des dépendances
Clé de extrait_plat : (ruche_code, horodatage).

| Forme normale | Règle | Nos dépendances qui la violent |
|---|---|---|
| 1NF | chaque case contient une seule valeur | aucune : chaque case contient une seule valeur |
| 2NF | aucune colonne ne dépend d'une partie de la clé | ruche_code -> site_id, telephone (ruche_code n'est qu'une partie de la clé) |
| 3NF | aucune colonne ne dépend d'une colonne qui n'est pas la clé | site_id -> site_nom, pays ; telephone -> apicultrice, cooperative |
| BCNF | la partie gauche de toute dépendance est une clé | site_id -> … ; telephone -> … ; ruche_code -> … (seule ruche_code, horodatage -> … respecte la règle) |

extrait_plat est donc en 1NF seulement.

## Le découpage
Le remède : une table par déterminant, chaque fait n'est écrit qu'une fois.

| Table norm | Clé | Colonnes | Dépendance |
|---|---|---|---|
| norm.site | site_id | site_nom, pays | site_id -> site_nom, pays |
| norm.apicultrice | telephone | apicultrice, cooperative | telephone -> apicultrice, cooperative |
| norm.ruche | ruche_code | site_id, telephone | ruche_code -> site_id, telephone |
| norm.mesure | (ruche_code, horodatage) | poids_kg, temp_int_c | ruche_code, horodatage -> poids_kg, temp_int_c |

Lancée sur les données corrompues, la migration a été refusée (`duplicate key value violates unique constraint "site_pkey"` : SN-KOLD avait deux pays). Après correction des deux incohérences, elle passe : 4 sites, 8 apicultrices, 11 ruches, 528 mesures.

## Vérification BCNF, table par table
- **norm.site** : une seule dépendance, site_id -> site_nom, pays ; site_id est la clé. **BCNF.**
- **norm.apicultrice** : une seule dépendance, telephone -> apicultrice, cooperative ; telephone est la clé. (apicultrice -> telephone est fausse : deux Aminata Diop.) **BCNF.**
- **norm.ruche** : une seule dépendance, ruche_code -> site_id, telephone ; ruche_code est la clé. **BCNF.**
- **norm.mesure** : une seule dépendance, (ruche_code, horodatage) -> poids_kg, temp_int_c ; c'est la clé. **BCNF.**

Dans chaque table, la partie gauche de toute dépendance est la clé : les quatre tables sont en BCNF.

## La preuve
- La vue norm.reconstruit, comparée à extrait_plat dans les deux sens (EXCEPT), donne **0 ligne** : la décomposition est **sans perte**.
- Un second pays pour SN-KOLD est **refusé** par la clé primaire de norm.site.
- Un site sans ruche (CI-KORH) est **accepté** : l'anomalie d'insertion a disparu.
- L'enquête par pays sur les tables norm redonne **3 pays**.

**Conclusion : une seule ligne modifiée a fait passer l'enquête de 3 à 4 pays. Une base non normalisée ne peut pas servir de preuve.**

## Testez-vous · Lab 5
1. **Mise à jour** : changer « Sénégal » en « Senegal » sur une seule ligne crée un site avec deux pays. **Suppression** : effacer les mesures de la seule ruche d'Awa Diop fait disparaître Awa Diop et son téléphone. **Insertion** : on ne peut pas ajouter un nouveau site sans inventer une ruche et une mesure.
2. Parce que la clé est (ruche_code, horodatage) et que site_id ne dépend que d'une **partie** de cette clé (ruche_code). Le site est alors recopié sur les 48 mesures de chaque ruche.
3. On recompose la table de départ en joignant les morceaux (la vue norm.reconstruit), puis on compare dans les deux sens avec EXCEPT : `(départ EXCEPT recomposé) UNION ALL (recomposé EXCEPT départ)`. **0 ligne** = rien de perdu, rien d'inventé.
