-- anomalies.sql (après avoir relancé plat.sql)

-- Mise à jour
-- 1. enquête de référence
SELECT pays, count(*) AS nb_mesures, round(avg(poids_kg), 2) AS poids_moyen
FROM extrait_plat GROUP BY pays ORDER BY pays;
-- Cameroun 96 | Côte d'Ivoire 144 | Sénégal 288   -> 3 pays

-- 2.
UPDATE extrait_plat SET pays = 'Senegal'
WHERE ruche_code = 'SN-KOLD-011'
  AND horodatage = (SELECT min(horodatage) FROM extrait_plat WHERE ruche_code = 'SN-KOLD-011');
-- UPDATE 1
UPDATE extrait_plat SET telephone = '+221 70 999 99 99'
WHERE ruche_code = 'SN-KOLD-012'
  AND horodatage = (SELECT min(horodatage) FROM extrait_plat WHERE ruche_code = 'SN-KOLD-012');
-- UPDATE 1

-- 3. on relance l'enquête
SELECT pays, count(*) AS nb_mesures, round(avg(poids_kg), 2) AS poids_moyen
FROM extrait_plat GROUP BY pays ORDER BY pays;
-- Cameroun 96 | Côte d'Ivoire 144 | Senegal 1 | Sénégal 287   -> 4 pays

-- Suppression : Awa Diop n'a qu'une ruche (SN-CASA-099)
BEGIN;
DELETE FROM extrait_plat WHERE ruche_code = 'SN-CASA-099';
-- DELETE 48
SELECT telephone FROM extrait_plat WHERE apicultrice = 'Awa Diop';
-- (0 ligne) : son téléphone a disparu
ROLLBACK;

-- Insertion
ALTER TABLE extrait_plat ADD PRIMARY KEY (ruche_code, horodatage);
-- ALTER TABLE
INSERT INTO extrait_plat (site_id, site_nom, pays) VALUES ('CI-KORH', 'Korhogo', 'Côte d''Ivoire');
-- ERROR:  null value in column "ruche_code" of relation "extrait_plat" violates not-null constraint
-- DÉTAIL : Failing row contains (null, CI-KORH, Korhogo, Côte d'Ivoire, null, null, null, null, null, null).

-- migration_3nf.sql lancée ici : refus
-- ERROR:  duplicate key value violates unique constraint "site_pkey"
-- DÉTAIL : Key (site_id)=(SN-KOLD) already exists.

-- Nettoyage : les incohérences
SELECT site_id, array_agg(DISTINCT pays) FROM extrait_plat
GROUP BY site_id HAVING count(DISTINCT pays) > 1;
-- SN-KOLD | {Senegal,Sénégal}
SELECT ruche_code, array_agg(DISTINCT telephone) FROM extrait_plat
GROUP BY ruche_code HAVING count(DISTINCT telephone) > 1;
-- SN-KOLD-012 | {"+221 70 999 99 99","+221 77 123 45 04"}

UPDATE extrait_plat SET pays = 'Sénégal' WHERE pays = 'Senegal';
-- UPDATE 1
UPDATE extrait_plat SET telephone = '+221 77 123 45 04' WHERE telephone = '+221 70 999 99 99';
-- UPDATE 1

-- migration_3nf.sql relancée : COMMIT
SELECT (SELECT count(*) FROM norm.site) AS sites, (SELECT count(*) FROM norm.apicultrice) AS apicultrices,
       (SELECT count(*) FROM norm.ruche) AS ruches, (SELECT count(*) FROM norm.mesure) AS mesures;
-- 4 | 8 | 11 | 528

-- Preuve sans perte
CREATE VIEW norm.reconstruit AS
SELECT r.ruche_code, s.site_id, s.site_nom, s.pays,
       a.apicultrice, a.telephone, a.cooperative,
       m.horodatage, m.poids_kg, m.temp_int_c
FROM norm.mesure m
JOIN norm.ruche r       USING (ruche_code)
JOIN norm.site s        USING (site_id)
JOIN norm.apicultrice a USING (telephone);
-- CREATE VIEW

(SELECT * FROM extrait_plat EXCEPT SELECT * FROM norm.reconstruit)
UNION ALL
(SELECT * FROM norm.reconstruit EXCEPT SELECT * FROM extrait_plat);
-- (0 ligne)

-- Attaques rejouées
INSERT INTO norm.site VALUES ('SN-KOLD', 'Kolda', 'Senegal');
-- ERROR:  duplicate key value violates unique constraint "site_pkey"
-- DÉTAIL : Key (site_id)=(SN-KOLD) already exists.
INSERT INTO norm.site VALUES ('CI-KORH', 'Korhogo', 'Côte d''Ivoire');
-- INSERT 0 1

-- Enquête sur les tables norm
SELECT s.pays, count(*) AS nb_mesures, round(avg(m.poids_kg), 2) AS poids_moyen
FROM norm.mesure m JOIN norm.ruche r USING (ruche_code) JOIN norm.site s USING (site_id)
GROUP BY s.pays ORDER BY s.pays;
-- Cameroun 96 | Côte d'Ivoire 144 | Sénégal 288   -> 3 pays
