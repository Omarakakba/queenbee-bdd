-- tests_schema.sql : essayer de casser la base
-- lancé sans ON_ERROR_STOP : psql -U postgres -d queenbee -f tests_schema.sql

-- Test 1 : une ruche dont l'apicultrice n'existe pas. Attendu : refus
INSERT INTO ruche (code, latitude, longitude, date_installation, site_id, apicultrice_id)
VALUES ('SN-CASA-900', 12.5, -16.2, current_date, 'SN-CASA', gen_random_uuid());
-- Obtenu : refus
-- ERROR:  insert or update on table "ruche" violates foreign key constraint "ruche_apicultrice_fk"
-- DÉTAIL : Key (apicultrice_id)=(a107402c-bb6e-420d-bcef-7ef44488a699) is not present in table "apicultrice".

-- Test 2 : supprimer une apicultrice qui a des ruches (Awa Diop). Attendu : refus
DELETE FROM apicultrice WHERE telephone = '+221 77 123 45 03';
-- Obtenu : refus
-- ERROR:  update or delete on table "apicultrice" violates foreign key constraint "ruche_apicultrice_fk" on table "ruche"
-- DÉTAIL : Key (id)=(2f0db110-02d6-4da7-afac-2081d57fb0cc) is still referenced from table "ruche".

-- Test 3 : une ruche sans apicultrice. Attendu : refus
INSERT INTO ruche (code, latitude, longitude, date_installation, site_id, apicultrice_id)
VALUES ('SN-CASA-901', 12.5, -16.2, current_date, 'SN-CASA', NULL);
-- Obtenu : refus
-- ERROR:  null value in column "apicultrice_id" of relation "ruche" violates not-null constraint

-- Test 4 : table sans clé étrangère. Attendu : accepté, puis 0 ligne
DROP TABLE IF EXISTS ruche_sans_fk;
CREATE TABLE ruche_sans_fk (code text, apicultrice_id uuid);
INSERT INTO ruche_sans_fk VALUES ('SN-CASA-902', gen_random_uuid());
SELECT r.code, a.nom FROM ruche_sans_fk r JOIN apicultrice a ON a.id = r.apicultrice_id;
DROP TABLE ruche_sans_fk;
-- Obtenu : INSERT 0 1 puis (0 ligne), la ruche orpheline n'apparaît plus dans la jointure

-- Test 5 : table avec id serial. Attendu : 1, 2, 3
DROP TABLE IF EXISTS ruche_serial;
CREATE TABLE ruche_serial (id serial PRIMARY KEY, code text);
INSERT INTO ruche_serial (code) VALUES ('A'), ('B'), ('C');
SELECT id, code FROM ruche_serial;
DROP TABLE ruche_serial;
-- Obtenu : 1, 2, 3 -> on devine facilement l'id suivant

-- Test 6 : une mesure déjà reçue (même ruche, même instant). Attendu : refus
INSERT INTO mesure (ruche_id, horodatage, poids_kg)
SELECT ruche_id, horodatage, 48.00 FROM mesure LIMIT 1;
-- Obtenu : refus
-- ERROR:  duplicate key value violates unique constraint "mesure_anti_rejeu"
-- DÉTAIL : Key (ruche_id, horodatage)=(1bab1245-a149-4628-908d-06aa077d9ce1, 2027-03-14 01:00:00+01) already exists.

-- Test 7 : ruches dont le site diffère de celui de leur apicultrice.
-- Attendu : 0 ligne (hypothèse du lab 1 : les ruches d'une apicultrice sont sur son site)
SELECT r.code, r.site_id, a.site_id
FROM ruche r JOIN apicultrice a ON a.id = r.apicultrice_id
WHERE r.site_id <> a.site_id;
-- Obtenu : 0 ligne

-- Test 8 : passer une récolte déclarée à validée sans validateur. Attendu : refus
UPDATE recolte SET statut = 'validee' WHERE statut = 'declaree';
-- Obtenu : refus
-- ERROR:  new row for relation "recolte" violates check constraint "recolte_validation_tracee"

-- Un UUID suffit-il à protéger la ruche d'une autre apicultrice ?
-- Non. Il évite qu'on devine les id (test 5), mais si quelqu'un récupère l'UUID d'une
-- ruche (lien partagé, logs...), la base ne vérifie pas que cette ruche est à lui.
-- Il faut un contrôle d'accès en plus (droits par rôle, filtrage par apicultrice).
