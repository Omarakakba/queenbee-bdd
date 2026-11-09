-- contraintes.sql : confronter les dépendances aux données, puis rendre les logins uniques (Lab 4)
-- À exécuter requête par requête dans le Query Tool de pgAdmin (F5), dans l'ordre.

----------------------------------------------------------------------
-- Étape 4.3 · Chaque DF du tableau : une valeur de X ne doit avoir qu'une valeur de Y
----------------------------------------------------------------------

-- DF 1 : site_id -> site_nom, pays
SELECT site_id FROM extrait_plat GROUP BY site_id
HAVING count(DISTINCT site_nom) > 1 OR count(DISTINCT pays) > 1;
-- Résultat : 0 ligne : rien ne contredit la DF

-- DF 2 : telephone -> apicultrice, cooperative
SELECT telephone FROM extrait_plat GROUP BY telephone
HAVING count(DISTINCT apicultrice) > 1 OR count(DISTINCT cooperative) > 1;
-- Résultat : 0 ligne

-- DF 3 : ruche_code -> site_id, telephone
SELECT ruche_code FROM extrait_plat GROUP BY ruche_code
HAVING count(DISTINCT site_id) > 1 OR count(DISTINCT telephone) > 1;
-- Résultat : 0 ligne

-- DF 4 : ruche_code, horodatage -> poids_kg, temp_int_c
SELECT ruche_code, horodatage FROM extrait_plat GROUP BY ruche_code, horodatage
HAVING count(DISTINCT poids_kg) > 1 OR count(DISTINCT temp_int_c) > 1;
-- Résultat : 0 ligne

-- La fausse dépendance : apicultrice -> telephone (le nom donnerait le téléphone)
SELECT apicultrice, count(DISTINCT telephone) AS nb_telephones
FROM extrait_plat GROUP BY apicultrice
HAVING count(DISTINCT telephone) > 1;
-- Résultat : 1 ligne : « Aminata Diop » avec 2 téléphones -> la DF est fausse, le nom ne donne pas la personne

----------------------------------------------------------------------
-- Étape 4.4 · Rendre les logins uniques
----------------------------------------------------------------------

-- 1. Les logins en double
SELECT login, count(*) AS nb FROM utilisateur GROUP BY login HAVING count(*) > 1;
-- Résultat : a.diop | 3  -> trois comptes ont le même login

-- 2. Poser la contrainte d'unicité
ALTER TABLE utilisateur ADD CONSTRAINT utilisateur_login_unique UNIQUE (login);
-- Résultat : ERROR:  could not create unique index "utilisateur_login_unique"
--             DETAIL: Key (login)=(a.diop) is duplicated.  -> refusé

-- 3. Un login différent pour chaque personne (on vise la personne par son téléphone, pas par son nom)
UPDATE utilisateur SET login = 'am.diop.casa'
WHERE apicultrice_id = (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 01');
UPDATE utilisateur SET login = 'am.diop.kold'
WHERE apicultrice_id = (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 02');
-- Awa Diop garde a.diop
-- Résultat : UPDATE 1, UPDATE 1

-- 4. La même contrainte
ALTER TABLE utilisateur ADD CONSTRAINT utilisateur_login_unique UNIQUE (login);
-- Résultat : ALTER TABLE -> acceptée

-- 5. Un compte « A.Diop » (avec majuscules)
INSERT INTO utilisateur (login, role) VALUES ('A.Diop', 'apicultrice');
-- Résultat : INSERT 0 1 -> accepté : pour la base, « A.Diop » n'est pas « a.diop »
DELETE FROM utilisateur WHERE login = 'A.Diop';

-- 6. Unicité sans tenir compte des majuscules, puis de nouveau A.Diop
CREATE UNIQUE INDEX utilisateur_login_ci ON utilisateur (lower(login));
INSERT INTO utilisateur (login, role) VALUES ('A.Diop', 'apicultrice');
-- Résultat : ERROR:  duplicate key value violates unique constraint "utilisateur_login_ci"
--             DETAIL: Key (lower(login))=(a.diop) already exists.  -> refusé

-- Quelles lettres STRIDE un login partagé permet-il ?
-- S (usurpation) : avec le même login, on peut se connecter à la place de l'autre personne.
-- R (répudiation) : si deux personnes partagent un login, on ne sait plus qui a fait une action
--   (qui a déclaré ou validé une récolte) ; chacune peut dire « ce n'est pas moi ».
-- I (divulgation) : l'une voit les ruches, les positions GPS et les récoltes de l'autre.
