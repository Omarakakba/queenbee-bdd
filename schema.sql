-- schema.sql : base Queen Bee (Lab 2)
-- On supprime tout pour pouvoir relancer le fichier autant de fois qu'on veut.
DROP TABLE IF EXISTS alerte, recolte, inspection, mesure, utilisateur, adhesion,
                     ruche, apicultrice, cooperative, site CASCADE;

-- Le site : code lisible, court et stable (ex. 'SN-CASA')
CREATE TABLE site (
   id   text PRIMARY KEY,
   nom  text NOT NULL,
   pays text NOT NULL
);

-- La coopérative : UUID, car elle sera exposée par l'application
CREATE TABLE cooperative (
   id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   code text NOT NULL UNIQUE,            -- ex. 'COOP-SN-CASA'
   nom  text NOT NULL
);

-- L'apicultrice : le nom ne suffit pas (homonymes), d'où l'UUID
CREATE TABLE apicultrice (
   id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   nom       text NOT NULL,              -- sensible
   telephone text NOT NULL UNIQUE,       -- sensible ; sert à retrouver une personne
   site_id   text NOT NULL CONSTRAINT apicultrice_site_fk REFERENCES site(id)
);

-- La ruche : le code ne doit jamais se répéter
CREATE TABLE ruche (
   id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   code              text NOT NULL UNIQUE,     -- ex. 'SN-CASA-014'
   latitude          numeric(8,5) NOT NULL,    -- sensible (vol de ruche)
   longitude         numeric(8,5) NOT NULL,    -- sensible
   date_installation date NOT NULL,
   site_id           text NOT NULL CONSTRAINT ruche_site_fk REFERENCES site(id),
   apicultrice_id    uuid NOT NULL CONSTRAINT ruche_apicultrice_fk REFERENCES apicultrice(id)
);

-- Lien n,n ADHÈRE : une table en plus, clé primaire sur deux colonnes
CREATE TABLE adhesion (
   apicultrice_id uuid NOT NULL CONSTRAINT adhesion_apicultrice_fk REFERENCES apicultrice(id),
   cooperative_id uuid NOT NULL CONSTRAINT adhesion_cooperative_fk REFERENCES cooperative(id),
   date_adhesion  date NOT NULL DEFAULT current_date,
   PRIMARY KEY (apicultrice_id, cooperative_id)
);

-- Les comptes : une apicultrice a au plus un compte -> UNIQUE sur apicultrice_id
-- (le login unique attendra le lab 4)
CREATE TABLE utilisateur (
   id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   login             text NOT NULL,            -- sensible
   mot_de_passe_hash text,                     -- sensible ; rempli par l'application, jamais en clair
   role              text NOT NULL
                     CHECK (role IN ('apicultrice', 'coordinateur', 'gestionnaire', 'administrateur')),
   site_id           text CONSTRAINT utilisateur_site_fk REFERENCES site(id),
   apicultrice_id    uuid UNIQUE CONSTRAINT utilisateur_apicultrice_fk REFERENCES apicultrice(id)
);

-- Les mesures des capteurs, toutes les 30 minutes
CREATE TABLE mesure (
   id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
   ruche_id        uuid NOT NULL CONSTRAINT mesure_ruche_fk REFERENCES ruche(id),
   horodatage      timestamptz NOT NULL,
   poids_kg        numeric(5,2),
   temp_int_c      numeric(4,1),
   temp_ext_c      numeric(4,1),
   humidite_pct    smallint,
   activite_sonore smallint,
   batterie_pct    smallint CHECK (batterie_pct BETWEEN 0 AND 100),
   CONSTRAINT mesure_anti_rejeu UNIQUE (ruche_id, horodatage)   -- une seule mesure par ruche et par instant
);

-- Les inspections, faites par l'apicultrice
CREATE TABLE inspection (
   id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   ruche_id        uuid NOT NULL CONSTRAINT inspection_ruche_fk REFERENCES ruche(id),
   apicultrice_id  uuid NOT NULL CONSTRAINT inspection_apicultrice_fk REFERENCES apicultrice(id),
   date_inspection date NOT NULL,
   etat_colonie    text NOT NULL,
   reine_presente  boolean NOT NULL,
   observations    text
);

-- Les récoltes : déclarées par l'apicultrice, validées par un coordinateur
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
   -- validée  <=>  on sait par qui ET quand
   CONSTRAINT recolte_validation_tracee CHECK (
         (statut = 'declaree' AND validee_par IS NULL     AND validee_le IS NULL)
      OR (statut = 'validee'  AND validee_par IS NOT NULL AND validee_le IS NOT NULL))
);

-- Les alertes du système
CREATE TABLE alerte (
   id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   ruche_id         uuid NOT NULL CONSTRAINT alerte_ruche_fk REFERENCES ruche(id),
   type_alerte      text NOT NULL CHECK (type_alerte IN ('essaimage', 'vol', 'capteur_silencieux')),
   horodatage       timestamptz NOT NULL,
   niveau_confiance numeric(3,2) NOT NULL
                    CONSTRAINT alerte_confiance_0_1 CHECK (niveau_confiance BETWEEN 0 AND 1),
   statut           text NOT NULL DEFAULT 'ouverte' CHECK (statut IN ('ouverte', 'fermee'))
);
