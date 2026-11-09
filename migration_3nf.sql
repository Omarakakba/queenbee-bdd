-- migration_3nf.sql : découper extrait_plat en 3NF, une table par déterminant (Lab 5)
--   psql -U postgres -h localhost -d queenbee -v ON_ERROR_STOP=1 -f migration_3nf.sql
-- Sur des données corrompues, la migration DOIT échouer : la base découpée ne peut plus se contredire.
BEGIN;
DROP SCHEMA IF EXISTS norm CASCADE;
CREATE SCHEMA norm;

-- déterminant : site_id  (site_id -> site_nom, pays)
CREATE TABLE norm.site (
   site_id  text PRIMARY KEY,
   site_nom text NOT NULL,
   pays     text NOT NULL
);

-- déterminant : telephone  (telephone -> apicultrice, cooperative)
CREATE TABLE norm.apicultrice (
   telephone   text PRIMARY KEY,
   apicultrice text NOT NULL,
   cooperative text NOT NULL
);

-- déterminant : ruche_code  (ruche_code -> site_id, telephone)
CREATE TABLE norm.ruche (
   ruche_code text PRIMARY KEY,
   site_id    text NOT NULL REFERENCES norm.site(site_id),
   telephone  text NOT NULL REFERENCES norm.apicultrice(telephone)
);

-- clé : (ruche_code, horodatage)  (ruche_code, horodatage -> poids_kg, temp_int_c)
CREATE TABLE norm.mesure (
   ruche_code text NOT NULL REFERENCES norm.ruche(ruche_code),
   horodatage timestamptz NOT NULL,
   poids_kg   numeric(5,2),
   temp_int_c numeric(4,1),
   PRIMARY KEY (ruche_code, horodatage)
);

INSERT INTO norm.site        SELECT DISTINCT site_id, site_nom, pays FROM extrait_plat;
INSERT INTO norm.apicultrice SELECT DISTINCT telephone, apicultrice, cooperative FROM extrait_plat;
INSERT INTO norm.ruche       SELECT DISTINCT ruche_code, site_id, telephone FROM extrait_plat;
INSERT INTO norm.mesure      SELECT DISTINCT ruche_code, horodatage, poids_kg, temp_int_c FROM extrait_plat;

-- La vue qui recompose extrait_plat (mêmes colonnes, même ordre) : sert à prouver qu'il n'y a pas de perte
CREATE VIEW norm.reconstruit AS
SELECT r.ruche_code, s.site_id, s.site_nom, s.pays, a.apicultrice, a.telephone, a.cooperative,
       m.horodatage, m.poids_kg, m.temp_int_c
FROM norm.mesure m
JOIN norm.ruche       r ON r.ruche_code = m.ruche_code
JOIN norm.site        s ON s.site_id    = r.site_id
JOIN norm.apicultrice a ON a.telephone  = r.telephone;

COMMIT;

-- Premier lancement, sur les données corrompues de anomalies.sql :
--   ERROR:  duplicate key value violates unique constraint "site_pkey"
--   DETAIL: Key (site_id)=(SN-KOLD) already exists.  -> refus : SN-KOLD a deux pays, tout est annulé
-- Après le nettoyage (fin de anomalies.sql), second lancement :
--   COMMIT -> 4 sites, 8 apicultrices, 11 ruches, 528 mesures
