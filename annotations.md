# Lab 1 · Queen Bee — Annotations

## Partie A · Comprendre le sujet

### Question 1 · De quoi le système doit-il se souvenir ?
Site, ruche, apicultrice, coopérative, mesure, inspection, récolte, alerte, compte.
**9 choses.**

Le pays n'en fait pas partie : c'est juste une info sur le site. Pareil pour le poids ou la température, qui décrivent une mesure. Et le coordinateur n'est pas une chose à part : c'est un compte qui a le rôle « coordinateur ».

### Question 2 · Ce qu'on garde, et ce qui distingue
| Chose | Ce qu'on garde | Ce qui la distingue |
|---|---|---|
| site | nom, pays | un code court (SN-CASA) |
| ruche | code, latitude, longitude, date d'installation | son code (SN-CASA-014) |
| apicultrice | nom, téléphone | un numéro attribué : deux femmes peuvent s'appeler Aminata Diop |
| coopérative | nom | un numéro attribué |
| mesure | date et heure, poids, température intérieure et extérieure, humidité, activité sonore, batterie | la ruche + la date et l'heure |
| inspection | date, état de la colonie, reine présente ou non, observations | un numéro attribué |
| récolte | date, quantité, date de validation | un numéro attribué |
| alerte | type (essaimage, vol, capteur silencieux), date et heure, niveau de confiance | un numéro attribué |
| compte | login, rôle, mot de passe chiffré | un numéro attribué |

### Question 3 · Comment elles sont liées
| Lien | Dans un sens | Dans l'autre sens |
|---|---|---|
| ruche – apicultrice | une ruche appartient à une seule apicultrice | une apicultrice a zéro, une ou plusieurs ruches |
| site – ruche | une ruche est sur un seul site | un site a zéro, une ou plusieurs ruches |
| apicultrice – coopérative | une apicultrice adhère à une ou plusieurs coopératives | une coopérative a zéro, une ou plusieurs adhérentes |
| ruche – mesure | une mesure vient d'une seule ruche | une ruche envoie zéro, une ou plusieurs mesures |
| ruche – récolte | une récolte vient d'une seule ruche | une ruche donne zéro, une ou plusieurs récoltes |
| coordinateur – récolte validée | une récolte est validée par au plus un coordinateur (tant qu'elle attend, personne) | un coordinateur valide zéro, une ou plusieurs récoltes |
| apicultrice – compte | une apicultrice a au plus un compte | un compte appartient au plus à une apicultrice (un compte admin n'en a pas) |

Les autres liens : une apicultrice est rattachée à un seul site, une inspection porte sur une seule ruche et est faite par une seule apicultrice, une récolte est déclarée par une seule apicultrice, une alerte concerne une seule ruche, et un coordinateur s'occupe d'au plus un site.

### Question 4 · Ce que le sujet ne dit pas
| Question au client | Notre hypothèse |
|---|---|
| Une ruche peut-elle être déplacée sur un autre site ? | Oui, mais on ne garde que le site actuel. |
| Une ruche peut-elle changer de propriétaire ? | Oui, on ne garde que l'apicultrice actuelle. |
| Qui a le droit de valider une récolte ? | Seulement un coordinateur du site de la ruche, et on note qui l'a validée et quand. |
| Une récolte peut-elle être refusée ? | Non, elle reste « en attente » tant que personne ne la valide. |
| Une apicultrice peut-elle travailler sur deux sites ? | Non, un seul. |
| Faut-il suivre les capteurs eux-mêmes ? | Non, on rattache chaque mesure directement à la ruche. |

### Question 5 · Ce qui intéresserait un fraudeur
- **La position GPS des ruches** : il sait exactement où aller pour voler les ruches.
- **Le nom et le téléphone des apicultrices** : il peut les appeler en se faisant passer pour l'association et leur soutirer de l'argent ou des infos.
- **Les récoltes** : il déclare du miel qui n'existe pas, ou fait valider une fausse récolte pour toucher l'argent.

### Étape B1 · Les deux boîtes en plus par rapport à GreenFarm
**RÉCOLTE** et **ALERTE**. Queen Bee doit suivre le miel produit, qui a de la valeur et qu'il faut faire valider. Elle doit aussi prévenir quand il se passe quelque chose d'anormal : un essaimage, un vol ou un capteur qui ne répond plus. GreenFarm n'avait besoin ni de l'un ni de l'autre.

## Partie C · Sensibilité et menaces (STRIDE)
| Entité | Sensibilité | Qui lit | Qui modifie | Menace STRIDE et ce que gagne l'attaquant |
|---|---|---|---|---|
| RUCHE | confidentielle | l'apicultrice (les siennes), le coordinateur (son site), le gestionnaire | le coordinateur, l'admin | **I** : il connaît la position GPS et peut aller voler la ruche. |
| SITE | interne | tous | le gestionnaire, l'admin | **I** : il sait où sont regroupées beaucoup de ruches. |
| APICULTRICE | confidentielle | elle-même, le coordinateur, le gestionnaire | le gestionnaire, l'admin | **I** : il récupère nom et téléphone pour de l'arnaque ou de l'hameçonnage. |
| COOPÉRATIVE | publique | tous | le gestionnaire | **T** : il modifie la liste des adhésions pour exclure quelqu'un. |
| MESURE | interne | l'apicultrice, le coordinateur, le gestionnaire | les capteurs uniquement | **T** : il renvoie une ancienne mesure de poids (rejeu), et la ruche a l'air pleine alors qu'elle vient d'être vidée. |
| INSPECTION | interne | l'apicultrice, le coordinateur | l'apicultrice (les siennes) | **T** : il écrit une fausse observation pour cacher une colonie malade. |
| RÉCOLTE | confidentielle | l'apicultrice, le coordinateur, le gestionnaire | l'apicultrice déclare, le coordinateur valide | **R** : une récolte est validée sans qu'on sache par qui, donc le fraudeur peut toujours dire « ce n'est pas moi ». |
| ALERTE | interne | l'apicultrice, le coordinateur | le système | **D** : il coupe le capteur ou noie le système de fausses alertes pour qu'on ne voie pas le vol. |
| COMPTE | critique | l'admin | l'admin | **S** : il vole le login d'un coordinateur et valide ses propres récoltes. **E** : une apicultrice qui se donne le rôle admin. **R** : il efface l'historique des actions pour qu'on ne puisse plus prouver ce qu'il a fait. |

## Testez-vous · Lab 1
1. Au **lien** entre les deux (l'association ADHÈRE) : la date dépend du couple apicultrice + coopérative.
2. Parce que deux personnes peuvent avoir le même nom, et qu'un nom peut changer ou être mal écrit.
3. **T** (altération) : on fait passer une vieille valeur pour une nouvelle.
4. **1,1**, du côté de **RUCHE**.

## Schéma relationnel

### Du MCD aux tables
| Table | Clé primaire | Autres colonnes | Clés étrangères (vers quelle table) |
|---|---|---|---|
| site | id (code lisible, ex. SN-CASA) | nom, pays | — |
| cooperative | id (UUID) | code, nom | — |
| apicultrice | id (UUID) | nom, telephone | site_id (site) |
| ruche | id (UUID) | code, latitude, longitude, date_installation | site_id (site), apicultrice_id (apicultrice) |
| adhesion | (apicultrice_id, cooperative_id) | date_adhesion | apicultrice_id (apicultrice), cooperative_id (cooperative) |
| utilisateur | id (UUID) | login, mot_de_passe_hash, role | site_id (site), apicultrice_id UNIQUE (apicultrice) |
| mesure | id (nombre auto) | horodatage, poids_kg, temp_int_c, temp_ext_c, humidite_pct, activite_sonore, batterie_pct | ruche_id (ruche) |
| inspection | id (UUID) | date_inspection, etat_colonie, reine_presente, observations | ruche_id (ruche), apicultrice_id (apicultrice) |
| recolte | id (UUID) | date_recolte, quantite_kg, statut, validee_le | ruche_id (ruche), apicultrice_id (apicultrice), validee_par (utilisateur) |
| alerte | id (UUID) | type_alerte, horodatage, niveau_confiance, statut | ruche_id (ruche) |

- **Règle 1** : chaque entité devient une table. Le site garde un code lisible (court, stable, pas secret) ; tout ce que l'application exposera a un UUID, pour qu'on ne puisse pas deviner l'identifiant suivant.
- **Règle 2** : pour chaque lien 1,1 – 0,n, la clé étrangère va du côté 1,1 (la ruche garde son site et son apicultrice, la mesure garde sa ruche, etc.).
- **Règle 3** : ADHÈRE (n des deux côtés) devient la table `adhesion`, avec une clé primaire sur deux colonnes et la date d'adhésion.
- **Règle 4** : apicultrice – compte (0,1 – 0,1) : la clé étrangère va dans `utilisateur`, avec UNIQUE pour qu'une apicultrice n'ait jamais deux comptes.
- **Total : 10 tables et 14 clés étrangères.**

### Relancer donnees.sql une seconde fois
Ça plante dès la première ligne : `duplicate key value violates unique constraint "site_pkey"`, car le site SN-CASA existe déjà. Grâce à BEGIN / COMMIT, tout le fichier est annulé : on n'a pas la moitié des données en double. C'est la clé primaire du site qui nous protège (et derrière, le UNIQUE sur le code des ruches et sur les téléphones).

### Testez-vous · Lab 2
1. Dans la table du côté **1,1** (ex. la ruche garde `apicultrice_id`).
2. Parce que c'est le **couple** qui est unique : une apicultrice peut adhérer à plusieurs coopératives, une coopérative a plusieurs adhérentes, mais le même couple ne doit exister qu'une fois.
3. Elle empêche de **rejouer une mesure** : on ne peut pas renvoyer une ancienne valeur pour la même ruche au même instant.
4. Parce que la ruche **pointe vers** le site : la table visée par une clé étrangère doit déjà exister.
