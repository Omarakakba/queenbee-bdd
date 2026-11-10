-- denormalisation.sql : synthèse, export pour le bailleur, journal d'audit
DROP MATERIALIZED VIEW IF EXISTS synthese_site_jour;
DROP VIEW IF EXISTS v_export_bailleur;
DROP TABLE IF EXISTS cle_pseudonymisation;

-- synthèse par site et par jour
CREATE MATERIALIZED VIEW synthese_site_jour AS
SELECT r.site_id,
       (m.horodatage AT TIME ZONE 'UTC')::date AS jour,
       count(*)                    AS nb_mesures,
       round(avg(m.poids_kg), 2)   AS poids_moyen,
       min(m.poids_kg)             AS poids_min,
       min(m.batterie_pct)         AS batterie_min
FROM mesure m JOIN ruche r ON r.id = m.ruche_id
GROUP BY r.site_id, (m.horodatage AT TIME ZONE 'UTC')::date;
CREATE UNIQUE INDEX synthese_site_jour_pk ON synthese_site_jour (site_id, jour);

-- export pseudonymisé pour le bailleur
CREATE EXTENSION IF NOT EXISTS pgcrypto;               -- fournit hmac()
CREATE TABLE cle_pseudonymisation (
   id  int PRIMARY KEY CHECK (id = 1),                 -- une seule ligne
   cle text NOT NULL
);
INSERT INTO cle_pseudonymisation VALUES (1, encode(gen_random_bytes(32), 'hex'));
REVOKE ALL ON cle_pseudonymisation FROM PUBLIC;

CREATE VIEW v_export_bailleur AS
SELECT left(encode(hmac(a.id::text, k.cle, 'sha256'), 'hex'), 12) AS apicultrice_pseudo,
       s.pays, s.id AS site_id,
       round(r.latitude, 1) AS latitude, round(r.longitude, 1) AS longitude,
       sum(rc.quantite_kg) FILTER (WHERE rc.statut = 'validee') AS total_valide_kg
FROM ruche r
JOIN apicultrice a ON a.id = r.apicultrice_id
JOIN site s        ON s.id = r.site_id
LEFT JOIN recolte rc ON rc.ruche_id = r.id
CROSS JOIN cle_pseudonymisation k
GROUP BY 1, 2, 3, 4, 5;

-- journal d'audit (modèle du TP)
DROP TABLE IF EXISTS journal_audit CASCADE;
CREATE TABLE journal_audit (
   id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
   horodatage  timestamptz NOT NULL DEFAULT clock_timestamp(),
   acteur      text NOT NULL,              -- qui
   table_cible text NOT NULL,              -- sur quoi
   operation   text NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
   ligne_id    text,                       -- quelle ligne
   avant       jsonb,                      -- la ligne avant
   apres       jsonb                       -- la ligne après
);
REVOKE ALL ON journal_audit FROM PUBLIC;
