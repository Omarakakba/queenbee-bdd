# Normalisation – Groupe Omar Akakba

## Anomalies
| Anomalie | Ce qu'on a vu | DF qui la cause |
|---|---|---|
| mise à jour | Senegal sur une seule ligne : SN-KOLD a deux pays, l'enquête passe à 4 pays | site_id -> site_nom, pays |
| mise à jour | un autre téléphone sur une ligne : SN-KOLD-012 a deux téléphones | ruche_code -> site_id, telephone |
| suppression | en supprimant les mesures de SN-CASA-099, le téléphone d'Awa Diop disparaît | telephone -> apicultrice, cooperative |
| insertion | impossible d'ajouter le site CI-KORH sans ruche ni mesure | site_id -> site_nom, pays |

## Formes normales
Clé de extrait_plat : (ruche_code, horodatage).

| Forme normale | Règle | Vos dépendances qui la violent |
|---|---|---|
| 1NF | chaque case contient une seule valeur | aucune |
| 2NF | aucune colonne ne dépend d'une partie de la clé | ruche_code -> site_id, telephone |
| 3NF | aucune colonne ne dépend d'une colonne qui n'est pas la clé | site_id -> site_nom, pays ; telephone -> apicultrice, cooperative |
| BCNF | la partie gauche de toute dépendance est une clé | site_id -> … ; telephone -> … ; ruche_code -> … |

## Vérification BCNF des tables norm
- norm.site : seule DF site_id -> site_nom, pays, et site_id est la clé.
- norm.apicultrice : seule DF telephone -> apicultrice, cooperative, et telephone est la clé.
- norm.ruche : seule DF ruche_code -> site_id, telephone, et ruche_code est la clé.
- norm.mesure : seule DF (ruche_code, horodatage) -> poids_kg, temp_int_c, c'est la clé.

Dans chaque table, la partie gauche de toute DF est la clé : les 4 tables sont en BCNF.
La comparaison avec norm.reconstruit donne 0 ligne, donc la décomposition est sans perte.

Une seule ligne modifiée a fait passer l'enquête de 3 à 4 pays. Une base non normalisée ne peut pas servir de preuve.
