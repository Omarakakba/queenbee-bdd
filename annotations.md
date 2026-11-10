# Annotations Queen Bee

## Lab 1 · Partie A

### Question 1
site, ruche, apicultrice, coopérative, mesure, inspection, récolte, alerte, compte : 9 choses.
Le pays est une information sur le site, le poids ou la température des informations sur la mesure. Le coordinateur est un compte avec un rôle.

### Question 2
| Chose | Ce qu'on garde | Ce qui la distingue |
|---|---|---|
| site | nom, pays | un code (SN-CASA) |
| ruche | code, latitude, longitude, date d'installation | le code (SN-CASA-014) |
| apicultrice | nom, téléphone | un numéro attribué (deux Aminata Diop existent) |
| coopérative | nom | un numéro attribué |
| mesure | heure, poids, température int. et ext., humidité, activité sonore, batterie | la ruche et l'heure |
| inspection | date, état de la colonie, présence de la reine, observations | un numéro attribué |
| récolte | date, quantité, date de validation | un numéro attribué |
| alerte | type, date et heure, niveau de confiance | un numéro attribué |
| compte | login, rôle, mot de passe | un numéro attribué |

### Question 3
| Lien | Dans un sens | Dans l'autre sens |
|---|---|---|
| ruche – apicultrice | une ruche appartient à une seule apicultrice | une apicultrice possède zéro, une ou plusieurs ruches |
| site – ruche | une ruche est installée sur un seul site | un site a zéro, une ou plusieurs ruches |
| apicultrice – coopérative | une apicultrice adhère à une ou plusieurs coopératives | une coopérative a zéro, une ou plusieurs adhérentes |
| ruche – mesure | une mesure vient d'une seule ruche | une ruche émet zéro, une ou plusieurs mesures |
| ruche – récolte | une récolte vient d'une seule ruche | une ruche donne zéro, une ou plusieurs récoltes |
| coordinateur – récolte validée | une récolte est validée par au plus un coordinateur | un coordinateur valide zéro, une ou plusieurs récoltes |
| apicultrice – compte de connexion | une apicultrice a au plus un compte | un compte appartient au plus à une apicultrice |

### Question 4
| Question au client | Notre hypothèse |
|---|---|
| Une ruche peut-elle changer de site ? | oui, mais on ne garde que le site actuel |
| Les ruches d'une apicultrice sont-elles toutes sur son site ? | oui, une apicultrice n'a qu'un site |
| Une ruche peut-elle changer d'apicultrice ? | oui, on ne garde que l'apicultrice actuelle |
| Qui valide une récolte ? | un coordinateur du site de la ruche ; on garde qui a validé et quand |
| Une récolte peut-elle être refusée ? | non, elle reste déclarée tant qu'elle n'est pas validée |
| Faut-il suivre les capteurs eux-mêmes ? | non, la mesure est rattachée à la ruche |

### Question 5
- la position GPS des ruches : aller les voler ;
- le nom et le téléphone des apicultrices : arnaque ou hameçonnage en se faisant passer pour l'association ;
- les récoltes : déclarer une fausse récolte et la faire valider pour toucher l'argent.

### Étape B1
Les deux boîtes sans équivalent dans GreenFarm sont RÉCOLTE et ALERTE : Queen Bee doit suivre le miel produit (qui doit être validé) et prévenir en cas d'essaimage, de vol ou de capteur silencieux.

## Lab 1 · Partie C
| Entité | Sensibilité | Qui lit | Qui modifie | Menace STRIDE et ce que gagne l'attaquant |
|---|---|---|---|---|
| RUCHE | confidentielle | apicultrice (les siennes), coordinateur, gestionnaire | coordinateur, administrateur | I : connaître la position GPS pour voler la ruche |
| SITE | interne | apicultrice, coordinateur, gestionnaire, administrateur | gestionnaire, administrateur | I : savoir où sont regroupées les ruches |
| APICULTRICE | confidentielle | elle-même, coordinateur, gestionnaire | gestionnaire, administrateur | I : nom et téléphone pour l'hameçonnage |
| COOPÉRATIVE | publique | tous les rôles | gestionnaire | T : modifier les adhésions |
| MESURE | interne | apicultrice, coordinateur, gestionnaire | les capteurs | T : rejouer une ancienne mesure de poids pour cacher un vol |
| INSPECTION | interne | apicultrice, coordinateur | apicultrice | T : fausse observation pour cacher une colonie malade |
| RÉCOLTE | confidentielle | apicultrice, coordinateur, gestionnaire | apicultrice (déclare), coordinateur (valide) | R : une récolte validée sans savoir par qui, personne n'en est responsable |
| ALERTE | interne | apicultrice, coordinateur | le système | D : couper le capteur ou noyer les alertes pour qu'on ne voie pas le vol |
| COMPTE | critique | administrateur | administrateur | S : se connecter comme coordinateur ; E : une apicultrice qui se donne le rôle administrateur ; R : effacer l'historique des actions |

## Schéma relationnel

| Table | Clé primaire | Autres colonnes | Clés étrangères (vers quelle table) |
|---|---|---|---|
| site | id (code) | nom, pays | |
| cooperative | id (uuid) | code, nom | |
| apicultrice | id (uuid) | nom, telephone | site_id (site) |
| ruche | id (uuid) | code, latitude, longitude, date_installation | site_id (site), apicultrice_id (apicultrice) |
| adhesion | apicultrice_id, cooperative_id | date_adhesion | apicultrice_id (apicultrice), cooperative_id (cooperative) |
| utilisateur | id (uuid) | login, mot_de_passe_hash, role | site_id (site), apicultrice_id UNIQUE (apicultrice) |
| mesure | id | horodatage, poids_kg, temp_int_c, temp_ext_c, humidite_pct, activite_sonore, batterie_pct | ruche_id (ruche) |
| inspection | id (uuid) | date_inspection, etat_colonie, reine_presente, observations | ruche_id (ruche), apicultrice_id (apicultrice) |
| recolte | id (uuid) | date_recolte, quantite_kg, statut, validee_le | ruche_id (ruche), apicultrice_id (apicultrice), validee_par (utilisateur) |
| alerte | id (uuid) | type_alerte, horodatage, niveau_confiance, statut | ruche_id (ruche) |

- Règle 1 : le site garde un code lisible, le reste a un UUID car l'application l'exposera.
- Règle 2 : la clé étrangère est du côté 1,1.
- Règle 3 : ADHÈRE devient la table adhesion.
- Règle 4 : apicultrice_id dans utilisateur, avec UNIQUE.
- Total : 10 tables, 14 clés étrangères.

Relancer donnees.sql sans schema.sql : erreur dès le premier INSERT (`duplicate key value violates unique constraint "site_pkey"`) et rien n'est inséré grâce à BEGIN / COMMIT. C'est la clé primaire du site qui protège.
