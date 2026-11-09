-- tests_schema.sql : on joue l'attaquant (Lab 2)
-- À lancer SANS ON_ERROR_STOP : les erreurs sont voulues.
--   psql -U postgres -h localhost -d queenbee -f tests_schema.sql

-- Test 1 : une ruche dont l'apicultrice n'existe pas. Attendu : refus
INSERT INTO ruche (code, latitude, longitude, date_installation, site_id, apicultrice_id)
VALUES ('SN-CASA-900', 12.5, -16.2, current_date, 'SN-CASA', gen_random_uuid());
-- Obtenu : ERROR:  insert or update on table "ruche" violates foreign key constraint "ruche_apicultrice_fk"
--          DETAIL: Key (apicultrice_id)=(...) is not present in table "apicultrice".  -> refusé par la clé étrangère

-- Test 2 : supprimer une apicultrice qui a des ruches. Attendu : refus
DELETE FROM apicultrice WHERE telephone = '+221 77 123 45 03';   -- Awa Diop, ruche SN-CASA-099
-- Obtenu : ERROR:  update or delete on table "apicultrice" violates foreign key constraint "ruche_apicultrice_fk" on table "ruche"
--          DETAIL: Key (id)=(...) is still referenced from table "ruche".  -> refusé, ses ruches la protègent

-- Test 3 : une ruche sans apicultrice. Attendu : refus
INSERT INTO ruche (code, latitude, longitude, date_installation, site_id, apicultrice_id)
VALUES ('SN-CASA-901', 12.5, -16.2, current_date, 'SN-CASA', NULL);
-- Obtenu : ERROR:  null value in column "apicultrice_id" of relation "ruche" violates not-null constraint  -> refusé par NOT NULL

-- Test 4 : une table SANS clé étrangère, une ruche orpheline, puis la jointure.
-- Attendu : accepté, puis 0 ligne (l'orpheline devient invisible)
DROP TABLE IF EXISTS ruche_sans_fk;
CREATE TABLE ruche_sans_fk (code text, apicultrice_id uuid);
INSERT INTO ruche_sans_fk VALUES ('SN-CASA-902', gen_random_uuid());
SELECT r.code, a.nom FROM ruche_sans_fk r JOIN apicultrice a ON a.id = r.apicultrice_id;
DROP TABLE ruche_sans_fk;
-- Obtenu : INSERT 0 1 (accepté), puis (0 rows) : la ruche orpheline existe mais disparaît de toute jointure

-- Test 5 : une table avec id serial, 3 lignes. Attendu : 1, 2, 3 (devinable)
DROP TABLE IF EXISTS ruche_serial;
CREATE TABLE ruche_serial (id serial PRIMARY KEY, code text);
INSERT INTO ruche_serial (code) VALUES ('A'), ('B'), ('C');
SELECT id, code FROM ruche_serial;
DROP TABLE ruche_serial;
-- Obtenu : id = 1, 2, 3 : il suffit d'essayer 4 pour tomber sur la ligne suivante

-- Test 6 : rejouer une mesure déjà reçue (même ruche, même instant). Attendu : refus
INSERT INTO mesure (ruche_id, horodatage, poids_kg)
SELECT ruche_id, horodatage, 48.00 FROM mesure ORDER BY id LIMIT 1;
-- Obtenu : ERROR:  duplicate key value violates unique constraint "mesure_anti_rejeu"
--          DETAIL: Key (ruche_id, horodatage)=(..., 2027-03-14 00:00:00+00) already exists.  -> rejeu refusé

-- Test 7 : les ruches dont le site diffère de celui de leur apicultrice.
-- Attendu (hypothèse du lab 1 : une apicultrice n'a qu'un site, ses ruches sont dessus) : 0 ligne
SELECT r.code, r.site_id AS site_ruche, a.site_id AS site_apicultrice
FROM ruche r JOIN apicultrice a ON a.id = r.apicultrice_id
WHERE r.site_id <> a.site_id;
-- Obtenu : (0 rows) : conforme à notre hypothèse

-- Test 8 : passer une récolte « déclarée » à « validée » sans validateur. Attendu : refus
UPDATE recolte SET statut = 'validee' WHERE statut = 'declaree';
-- Obtenu : ERROR:  new row for relation "recolte" violates check constraint "recolte_validation_tracee"  -> refusé, on doit savoir qui a validé et quand

-- Question : un UUID suffit-il à protéger la ruche d'une autre apicultrice ?
-- Non. L'UUID empêche seulement de deviner les identifiants (fini le /ruches/42 -> /ruches/43).
-- Mais si quelqu'un récupère l'UUID d'une autre ruche (un lien partagé, un log, une liste
-- renvoyée par l'API), rien dans la base ne l'empêche de la lire ou de la modifier.
-- La vraie protection, c'est le contrôle d'accès : vérifier que la ruche appartient bien
-- à la personne connectée (droits par rôle, sécurité au niveau des lignes).
