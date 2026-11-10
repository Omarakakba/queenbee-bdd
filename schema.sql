-- schema.sql : base Queen Bee
DROP TABLE IF EXISTS alerte, recolte, inspection, mesure, utilisateur, adhesion,
                     ruche, apicultrice, cooperative, site CASCADE;

CREATE TABLE site (
   id   text PRIMARY KEY,                -- code lisible : 'SN-CASA'
   nom  text NOT NULL,
   pays text NOT NULL
);

CREATE TABLE cooperative (
   id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   code text NOT NULL UNIQUE,            -- 'COOP-SN-CASA'
   nom  text NOT NULL
);

CREATE TABLE apicultrice (
   id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   nom       text NOT NULL,
   telephone text NOT NULL UNIQUE,
   site_id   text NOT NULL CONSTRAINT apicultrice_site_fk REFERENCES site(id)
);

CREATE TABLE ruche (
   id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   code              text NOT NULL UNIQUE,
   latitude          numeric(8,5) NOT NULL,
   longitude         numeric(8,5) NOT NULL,
   date_installation date NOT NULL,
   site_id           text NOT NULL CONSTRAINT ruche_site_fk REFERENCES site(id),
   apicultrice_id    uuid NOT NULL CONSTRAINT ruche_apicultrice_fk REFERENCES apicultrice(id)
);

CREATE TABLE adhesion (
   apicultrice_id uuid NOT NULL CONSTRAINT adhesion_apicultrice_fk REFERENCES apicultrice(id),
   cooperative_id uuid NOT NULL CONSTRAINT adhesion_cooperative_fk REFERENCES cooperative(id),
   date_adhesion  date NOT NULL DEFAULT current_date,
   PRIMARY KEY (apicultrice_id, cooperative_id)
);

-- une apicultrice a au plus un compte : UNIQUE sur apicultrice_id
CREATE TABLE utilisateur (
   id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   login             text NOT NULL,
   mot_de_passe_hash text,
   role              text NOT NULL CHECK (role IN ('apicultrice', 'coordinateur', 'gestionnaire', 'administrateur')),
   site_id           text CONSTRAINT utilisateur_site_fk REFERENCES site(id),
   apicultrice_id    uuid UNIQUE CONSTRAINT utilisateur_apicultrice_fk REFERENCES apicultrice(id)
);

CREATE TABLE mesure (
   id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
   ruche_id        uuid NOT NULL CONSTRAINT mesure_ruche_fk REFERENCES ruche(id),
   horodatage      timestamptz NOT NULL,
   poids_kg        numeric(5,2),
   temp_int_c      numeric(4,1),
   temp_ext_c      numeric(4,1),
   humidite_pct    smallint,
   activite_sonore smallint,
   batterie_pct    smallint,
   CONSTRAINT mesure_anti_rejeu UNIQUE (ruche_id, horodatage)
);

CREATE TABLE inspection (
   id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   ruche_id        uuid NOT NULL CONSTRAINT inspection_ruche_fk REFERENCES ruche(id),
   apicultrice_id  uuid NOT NULL CONSTRAINT inspection_apicultrice_fk REFERENCES apicultrice(id),
   date_inspection date NOT NULL,
   etat_colonie    text NOT NULL,
   reine_presente  boolean NOT NULL,
   observations    text
);

CREATE TABLE recolte (
   id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   ruche_id       uuid NOT NULL CONSTRAINT recolte_ruche_fk REFERENCES ruche(id),
   apicultrice_id uuid NOT NULL CONSTRAINT recolte_apicultrice_fk REFERENCES apicultrice(id),
   date_recolte   date NOT NULL,
   quantite_kg    numeric(6,2) NOT NULL,
   statut         text NOT NULL DEFAULT 'declaree',
   validee_par    uuid CONSTRAINT recolte_validee_par_fk REFERENCES utilisateur(id),
   validee_le     timestamptz,
   CONSTRAINT recolte_quantite_positive CHECK (quantite_kg > 0),
   -- validée = on sait par qui et quand
   CONSTRAINT recolte_validation_tracee CHECK (
         (statut = 'declaree' AND validee_par IS NULL AND validee_le IS NULL)
      OR (statut = 'validee' AND validee_par IS NOT NULL AND validee_le IS NOT NULL))
);

CREATE TABLE alerte (
   id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   ruche_id         uuid NOT NULL CONSTRAINT alerte_ruche_fk REFERENCES ruche(id),
   type_alerte      text NOT NULL CHECK (type_alerte IN ('essaimage', 'vol', 'capteur_silencieux')),
   horodatage       timestamptz NOT NULL,
   niveau_confiance numeric(3,2) NOT NULL CONSTRAINT alerte_confiance_0_1 CHECK (niveau_confiance BETWEEN 0 AND 1),
   statut           text NOT NULL DEFAULT 'ouverte' CHECK (statut IN ('ouverte', 'fermee'))
);
