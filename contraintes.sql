-- contraintes.sql : les DF face aux données, puis les logins

-- DF site_id -> site_nom, pays
SELECT site_id, count(DISTINCT (site_nom, pays)) AS versions
FROM extrait_plat GROUP BY site_id HAVING count(DISTINCT (site_nom, pays)) > 1;
-- (0 ligne)

-- DF telephone -> apicultrice, cooperative
SELECT telephone, count(DISTINCT (apicultrice, cooperative)) AS versions
FROM extrait_plat GROUP BY telephone HAVING count(DISTINCT (apicultrice, cooperative)) > 1;
-- (0 ligne)

-- DF ruche_code -> site_id, telephone
SELECT ruche_code, count(DISTINCT (site_id, telephone)) AS versions
FROM extrait_plat GROUP BY ruche_code HAVING count(DISTINCT (site_id, telephone)) > 1;
-- (0 ligne)

-- DF ruche_code, horodatage -> poids_kg, temp_int_c
SELECT ruche_code, horodatage, count(DISTINCT (poids_kg, temp_int_c)) AS versions
FROM extrait_plat GROUP BY ruche_code, horodatage HAVING count(DISTINCT (poids_kg, temp_int_c)) > 1;
-- (0 ligne)

-- fausse DF apicultrice -> telephone
SELECT apicultrice, count(DISTINCT telephone) AS nb_telephones
FROM extrait_plat GROUP BY apicultrice HAVING count(DISTINCT telephone) > 1;
--  apicultrice  | nb_telephones
-- Aminata Diop  |             2
-- (1 ligne)

-- 1. logins en double
SELECT u.login, a.nom, a.site_id FROM utilisateur u LEFT JOIN apicultrice a ON a.id = u.apicultrice_id
WHERE u.login IN (SELECT login FROM utilisateur GROUP BY login HAVING count(*) > 1) ORDER BY a.nom, a.site_id;
--  login  |     nom      | site_id
-- a.diop  | Aminata Diop | SN-CASA
-- a.diop  | Aminata Diop | SN-KOLD
-- a.diop  | Awa Diop     | SN-CASA
-- (3 lignes)

-- 2.
ALTER TABLE utilisateur ADD CONSTRAINT utilisateur_login_unique UNIQUE (login);
-- ERROR:  could not create unique index "utilisateur_login_unique"
-- DÉTAIL : Key (login)=(a.diop) is duplicated.

-- 3.
UPDATE utilisateur u SET login = 'awa.diop' FROM apicultrice a
WHERE a.id = u.apicultrice_id AND a.nom = 'Awa Diop';
-- UPDATE 1
UPDATE utilisateur u SET login = 'aminata.diop.kold' FROM apicultrice a
WHERE a.id = u.apicultrice_id AND a.telephone = '+221 77 123 45 02';
-- UPDATE 1

-- 4.
ALTER TABLE utilisateur ADD CONSTRAINT utilisateur_login_unique UNIQUE (login);
-- ALTER TABLE

-- 5.
INSERT INTO utilisateur (login, role) VALUES ('A.Diop', 'apicultrice');
-- INSERT 0 1
DELETE FROM utilisateur WHERE login = 'A.Diop';
-- DELETE 1

-- 6.
CREATE UNIQUE INDEX utilisateur_login_ci ON utilisateur (lower(login));
-- CREATE INDEX
INSERT INTO utilisateur (login, role) VALUES ('A.Diop', 'apicultrice');
-- ERROR:  duplicate key value violates unique constraint "utilisateur_login_ci"
-- DÉTAIL : Key (lower(login))=(a.diop) already exists.

-- Lettres STRIDE permises par un login partagé :
-- S : on peut se connecter à la place de l'autre personne
-- R : on ne sait plus qui a fait une action (déclarer ou valider une récolte)
-- I : chacune voit les données de l'autre
