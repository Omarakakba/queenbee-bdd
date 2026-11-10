# Dépendances fonctionnelles – Groupe Omar Akakba

## Les DF de extrait_plat
| DF                                            | En français |
|-----------------------------------------------|-------------|
| site_id -> site_nom, pays                     | un site a un seul nom et un seul pays |
| telephone -> apicultrice, cooperative         | un téléphone désigne une apicultrice et sa coopérative |
| ruche_code -> site_id, telephone              | une ruche est sur un site et appartient à une apicultrice |
| ruche_code, horodatage -> poids_kg, temp_int_c | une seule mesure par ruche et par instant |

## {site_id}⁺
| Tour | DF utilisée | {site_id}⁺ |
|---|---|---|
| 0 | aucune | {site_id} |
| 1 | site_id -> site_nom, pays | + site_nom, pays |
| 2 | plus rien ne s'ajoute | 3 colonnes sur 10 : pas une clé |

## {ruche_code}⁺
| Tour | DF utilisée | {ruche_code}⁺ |
|---|---|---|
| 0 | aucune | {ruche_code} |
| 1 | ruche_code -> site_id, telephone | + site_id, telephone |
| 2 | site_id -> … ; telephone -> … | + site_nom, pays, apicultrice, cooperative |
| 3 | plus rien ne s'ajoute | 7 colonnes sur 10 : pas une clé |

## {ruche_code, horodatage}⁺
| Tour | DF utilisée | {ruche_code, horodatage}⁺ |
|---|---|---|
| 0 | aucune | {ruche_code, horodatage} |
| 1 | ruche_code, horodatage -> … ; ruche_code -> … | + poids_kg, temp_int_c, site_id, telephone |
| 2 | site_id -> … ; telephone -> … | + site_nom, pays, apicultrice, cooperative |
| 3 | plus rien ne s'ajoute | 10 colonnes sur 10 : clé |

Clé candidate : {ruche_code, horodatage}. On ne peut rien retirer : {ruche_code}⁺ ne donne que 7 colonnes (une ruche a 48 mesures) et {horodatage}⁺ ne donne que lui-même (11 ruches mesurent au même instant).

## Identifier les apicultrices par leur nom ?
La requête sur apicultrice -> telephone renvoie Aminata Diop avec 2 téléphones : ce sont deux personnes. Avec le nom comme identifiant, l'application les confondrait : l'une verrait les ruches et les récoltes de l'autre, une récolte pourrait être attribuée à la mauvaise personne. C'est aussi ce qui a donné trois logins a.diop.
