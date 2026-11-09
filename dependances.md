# Dépendances fonctionnelles – Groupe Omar Akakba

## Les DF de extrait_plat
| DF | En français |
|---|---|
| site_id -> site_nom, pays | un site a un seul nom et un seul pays |
| telephone -> apicultrice, cooperative | un téléphone désigne une seule apicultrice et sa coopérative |
| ruche_code -> site_id, telephone | une ruche est sur un seul site et appartient à une seule apicultrice |
| ruche_code, horodatage -> poids_kg, temp_int_c | une seule mesure par ruche et par instant |

## Les fermetures

### {site_id}⁺
| Tour | DF utilisée | {site_id}⁺ |
|---|---|---|
| 0 | aucune | {site_id} |
| 1 | site_id -> site_nom, pays | + site_nom, pays |
| 2 | plus rien ne s'ajoute | 3 colonnes sur 10 : **pas une clé** |

### {ruche_code}⁺
| Tour | DF utilisée | {ruche_code}⁺ |
|---|---|---|
| 0 | aucune | {ruche_code} |
| 1 | ruche_code -> site_id, telephone | + site_id, telephone |
| 2 | site_id -> … ; telephone -> … | + site_nom, pays, apicultrice, cooperative |
| 3 | plus rien ne s'ajoute | 7 colonnes sur 10 : **pas une clé** (il manque horodatage, poids_kg, temp_int_c) |

### {ruche_code, horodatage}⁺
| Tour | DF utilisée | {ruche_code, horodatage}⁺ |
|---|---|---|
| 0 | aucune | {ruche_code, horodatage} |
| 1 | ruche_code, horodatage -> poids_kg, temp_int_c ; ruche_code -> site_id, telephone | + poids_kg, temp_int_c, site_id, telephone |
| 2 | site_id -> … ; telephone -> … | + site_nom, pays, apicultrice, cooperative |
| 3 | plus rien ne s'ajoute | 10 colonnes sur 10 : **c'est une clé** |

### La clé candidate : {ruche_code, horodatage}
On ne peut rien lui retirer :
- sans horodatage, {ruche_code}⁺ ne donne que 7 colonnes : une ruche a 48 mesures, le code seul ne dit pas laquelle ;
- sans ruche_code, {horodatage}⁺ = {horodatage} : à un même instant, les 11 ruches envoient chacune une mesure.

Elle est donc minimale : c'est la clé candidate.

## Si l'application identifiait les apicultrices par leur nom
La requête de contrôle montre « Aminata Diop » avec 2 téléphones : ce sont deux personnes différentes, sur deux sites. Si l'application cherchait les apicultrices par leur nom, elle les confondrait. L'une verrait les ruches, les positions GPS et les récoltes de l'autre, une récolte pourrait être enregistrée ou payée à la mauvaise personne, et un changement de téléphone écraserait celui de l'homonyme. C'est exactement ce qui est arrivé aux logins : la règle « initiale.nom » a fabriqué trois a.diop. Il faut toujours identifier une personne par une valeur unique (son id, ou à défaut son téléphone), jamais par son nom.

## Testez-vous · Lab 4
1. **site_id -> pays** veut dire : si je connais le site, je connais son pays. Un site ne peut pas être dans deux pays à la fois.
2. Parce que sa fermeture ne donne que 7 colonnes sur 10 : une ruche a plusieurs mesures, donc le code seul ne désigne pas une ligne précise de extrait_plat (il y a 48 lignes par ruche).
3. Parce que « 0 ligne » veut seulement dire que **les données actuelles** ne contredisent pas la règle. Avec un petit jeu d'essai, c'est peut-être le hasard : il suffit d'une seule ligne demain pour la casser. Une DF est une règle métier, qu'on lit dans le sujet et qu'on impose avec des contraintes ; les données ne peuvent que la démentir, jamais la prouver.
