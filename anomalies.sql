-- anomalies.sql : provoquer les anomalies, nettoyer, puis prouver la décomposition (Lab 5)
-- AVANT : relancer plat.sql dans le terminal pour repartir d'un extrait propre.
-- Chaque commande s'exécute une par une dans le Query Tool de pgAdmin, dans l'ordre.

----------------------------------------------------------------------
-- 5.1 · Anomalie de MISE À JOUR
----------------------------------------------------------------------

-- 1. L'enquête de référence : nombre de mesures et poids moyen par pays
SELECT pays, count(*) AS nb_mesures, round(avg(poids_kg), 2) AS poids_moyen
FROM extrait_plat GROUP BY pays ORDER BY pays;
-- Résultat : 3 pays : Cameroun (96 mesures), Côte d'Ivoire (144), Sénégal (288)

-- 2a. Sur UNE SEULE ligne, Sénégal devient Senegal
UPDATE extrait_plat SET pays = 'Senegal'
WHERE ruche_code = 'SN-KOLD-011'
  AND horodatage = (SELECT min(horodatage) FROM extrait_plat WHERE ruche_code = 'SN-KOLD-011');
-- Résultat : UPDATE 1

-- 2b. Sur UNE AUTRE ligne, le téléphone de Fatou Sow change
UPDATE extrait_plat SET telephone = '+221 70 999 99 99'
WHERE ruche_code = 'SN-KOLD-012'
  AND horodatage = (SELECT min(horodatage) FROM extrait_plat WHERE ruche_code = 'SN-KOLD-012');
-- Résultat : UPDATE 1

-- 3. On relance l'enquête
SELECT pays, count(*) AS nb_mesures, round(avg(poids_kg), 2) AS poids_moyen
FROM extrait_plat GROUP BY pays ORDER BY pays;
-- Résultat : 4 pays : Cameroun (96), Côte d'Ivoire (144), Senegal (1), Sénégal (287)
--   -> le même site a maintenant deux pays : la base se contredit

----------------------------------------------------------------------
-- 5.1 · Anomalie de SUPPRESSION (annulée par ROLLBACK)
----------------------------------------------------------------------
BEGIN;
-- Awa Diop n'a qu'une ruche (SN-CASA-099) : on veut seulement effacer ses mesures
DELETE FROM extrait_plat WHERE ruche_code = 'SN-CASA-099';
-- Résultat : DELETE 48
SELECT apicultrice, telephone FROM extrait_plat WHERE apicultrice = 'Awa Diop';
-- Résultat : 0 ligne -> son téléphone a disparu avec les mesures
ROLLBACK;

----------------------------------------------------------------------
-- 5.1 · Anomalie d'INSERTION
----------------------------------------------------------------------
ALTER TABLE extrait_plat ADD PRIMARY KEY (ruche_code, horodatage);
-- Résultat : ALTER TABLE

-- Un nouveau site, qui n'a encore ni ruche ni mesure
INSERT INTO extrait_plat (site_id, site_nom, pays) VALUES ('CI-KORH', 'Korhogo', 'Côte d''Ivoire');
-- Résultat : ERROR:  null value in column "ruche_code" of relation "extrait_plat" violates not-null constraint
--   -> refusé : on ne peut pas créer un site tant qu'il n'a ni ruche ni mesure

----------------------------------------------------------------------
-- 5.2 · Ici, lancer migration_3nf.sql dans le terminal : il échoue (voulu).
-- Puis retrouver les incohérences et les corriger :
----------------------------------------------------------------------

-- Les sites qui ont plusieurs pays
SELECT site_id, array_agg(DISTINCT pays) AS pays FROM extrait_plat
GROUP BY site_id HAVING count(DISTINCT pays) > 1;
-- Résultat : SN-KOLD | {Senegal,Sénégal}

-- Les ruches qui ont plusieurs téléphones
SELECT ruche_code, array_agg(DISTINCT telephone) AS telephones FROM extrait_plat
GROUP BY ruche_code HAVING count(DISTINCT telephone) > 1;
-- Résultat : SN-KOLD-012 | {"+221 70 999 99 99","+221 77 123 45 04"}

-- On garde la bonne valeur (celle de toutes les autres lignes) et on corrige
UPDATE extrait_plat SET pays = 'Sénégal' WHERE pays = 'Senegal';
-- Résultat : UPDATE 1
UPDATE extrait_plat SET telephone = '+221 77 123 45 04' WHERE telephone = '+221 70 999 99 99';
-- Résultat : UPDATE 1

-- Puis relancer migration_3nf.sql dans le terminal, et compter :
SELECT (SELECT count(*) FROM norm.site) AS sites, (SELECT count(*) FROM norm.apicultrice) AS apicultrices,
       (SELECT count(*) FROM norm.ruche) AS ruches, (SELECT count(*) FROM norm.mesure) AS mesures;
-- Résultat : 4 sites, 8 apicultrices, 11 ruches, 528 mesures

----------------------------------------------------------------------
-- 5.3 · Prouver que rien n'est perdu
----------------------------------------------------------------------

-- 1. La table de départ et la vue recomposée, comparées dans les deux sens
(SELECT * FROM extrait_plat EXCEPT SELECT * FROM norm.reconstruit)
UNION ALL
(SELECT * FROM norm.reconstruit EXCEPT SELECT * FROM extrait_plat);
-- Résultat : 0 ligne -> la décomposition est sans perte

-- 2a. Attaque : un second pays pour un site existant
INSERT INTO norm.site VALUES ('SN-KOLD', 'Kolda', 'Senegal');
-- Résultat : ERROR:  duplicate key value violates unique constraint "site_pkey"
--   DETAIL: Key (site_id)=(SN-KOLD) already exists.  -> refusé

-- 2b. Un site sans ruche
INSERT INTO norm.site VALUES ('CI-KORH', 'Korhogo', 'Côte d''Ivoire');
-- Résultat : INSERT 0 1 -> accepté : l'anomalie d'insertion a disparu

-- 3. L'enquête par pays, sur les tables norm
SELECT s.pays, count(*) AS nb_mesures, round(avg(m.poids_kg), 2) AS poids_moyen
FROM norm.mesure m
JOIN norm.ruche r ON r.ruche_code = m.ruche_code
JOIN norm.site  s ON s.site_id    = r.site_id
GROUP BY s.pays ORDER BY s.pays;
-- Résultat : de nouveau 3 pays : Cameroun (96), Côte d'Ivoire (144), Sénégal (288)
