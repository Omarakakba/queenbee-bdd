BEGIN;
DROP SCHEMA IF EXISTS norm CASCADE;
CREATE SCHEMA norm;
CREATE TABLE norm.site        ( site_id text PRIMARY KEY, site_nom text NOT NULL, pays text NOT NULL );   -- déterminant : site_id
CREATE TABLE norm.apicultrice ( telephone text PRIMARY KEY, apicultrice text NOT NULL, cooperative text NOT NULL );   -- déterminant : telephone
CREATE TABLE norm.ruche       ( ruche_code text PRIMARY KEY,
                                site_id text NOT NULL REFERENCES norm.site,
                                telephone text NOT NULL REFERENCES norm.apicultrice );   -- déterminant : ruche_code
CREATE TABLE norm.mesure      ( ruche_code text REFERENCES norm.ruche, horodatage timestamptz,
                                poids_kg numeric(5,2), temp_int_c numeric(4,1),
                                PRIMARY KEY (ruche_code, horodatage) );   -- clé : (ruche_code, horodatage)
INSERT INTO norm.site        SELECT DISTINCT site_id, site_nom, pays FROM extrait_plat;
INSERT INTO norm.apicultrice SELECT DISTINCT telephone, apicultrice, cooperative FROM extrait_plat;
INSERT INTO norm.ruche       SELECT DISTINCT ruche_code, site_id, telephone FROM extrait_plat;
INSERT INTO norm.mesure      SELECT DISTINCT ruche_code, horodatage, poids_kg, temp_int_c FROM extrait_plat;
COMMIT;
