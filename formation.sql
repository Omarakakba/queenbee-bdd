-- formation.sql : formations des apicultrices
DROP TABLE IF EXISTS suivi_formation, formateur, formation_plat CASCADE;

-- les téléphones du sujet n'existent pas dans notre jeu d'essai : on a mis ceux de nos apicultrices
CREATE TABLE formation_plat (
   telephone text,
   theme     text,
   formateur text,
   PRIMARY KEY (telephone, theme)
);
INSERT INTO formation_plat VALUES
  ('+221 77 123 45 01',   'varroa',   'Moussa Sarr'),      -- Aminata Diop (SN-CASA)
  ('+221 77 123 45 01',   'recolte',  'Khady Ndiaye'),
  ('+221 77 123 45 04',   'varroa',   'Moussa Sarr'),      -- Fatou Sow
  ('+221 77 123 45 03',   'varroa',   'Ibrahima Fall'),    -- Awa Diop
  ('+221 77 123 45 03',   'capteurs', 'Oumar Diallo'),
  ('+225 07 11 22 33 01', 'varroa',   'Kouassi Yao'),      -- Mariam Kone
  ('+225 07 11 22 33 02', 'capteurs', 'Oumar Diallo'),     -- Adjoua Kouassi
  ('+237 6 70 11 22 01',  'recolte',  'Khady Ndiaye');     -- Brigitte Ngo

CREATE TABLE formateur (
   id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   nom   text NOT NULL UNIQUE,                             -- formateur -> theme
   theme text NOT NULL CHECK (theme IN ('varroa', 'recolte', 'capteurs'))
);

CREATE TABLE suivi_formation (
   apicultrice_id uuid NOT NULL REFERENCES apicultrice (id),
   formateur_id   uuid NOT NULL REFERENCES formateur (id),
   PRIMARY KEY (apicultrice_id, formateur_id)
);

INSERT INTO formateur (nom, theme)
SELECT DISTINCT formateur, theme FROM formation_plat;

INSERT INTO suivi_formation (apicultrice_id, formateur_id)
SELECT a.id, f.id
FROM formation_plat p
JOIN apicultrice a ON a.telephone = p.telephone
JOIN formateur f   ON f.nom = p.formateur;

CREATE OR REPLACE FUNCTION suivi_un_formateur_par_theme() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
     SELECT 1
     FROM suivi_formation s
     JOIN formateur f ON f.id = s.formateur_id
     WHERE s.apicultrice_id = NEW.apicultrice_id      -- même apicultrice
       AND s.formateur_id <> NEW.formateur_id         -- un autre formateur
       AND f.theme = (SELECT theme FROM formateur WHERE id = NEW.formateur_id)
       AND (TG_OP = 'INSERT'                          -- en UPDATE, on ne se compare pas
            OR (s.apicultrice_id, s.formateur_id) <> (OLD.apicultrice_id, OLD.formateur_id))
  ) THEN                                              -- pour le même thème
     RAISE EXCEPTION 'DF violée : cette apicultrice a déjà un formateur pour ce thème';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER suivi_formation_df
BEFORE INSERT OR UPDATE ON suivi_formation
FOR EACH ROW EXECUTE FUNCTION suivi_un_formateur_par_theme();

-- changer le thème d'un formateur ne doit pas donner deux formateurs du même thème à une apicultrice
CREATE OR REPLACE FUNCTION formateur_theme_coherent() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
     SELECT 1
     FROM suivi_formation s1                          -- les apicultrices de ce formateur
     JOIN suivi_formation s2 ON s2.apicultrice_id = s1.apicultrice_id
                            AND s2.formateur_id <> s1.formateur_id
     JOIN formateur f ON f.id = s2.formateur_id
     WHERE s1.formateur_id = NEW.id
       AND f.theme = NEW.theme                        -- ont déjà un autre formateur sur le nouveau thème
  ) THEN
     RAISE EXCEPTION 'DF violée : une apicultrice aurait deux formateurs pour ce thème';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER formateur_theme_df
BEFORE UPDATE OF theme ON formateur
FOR EACH ROW EXECUTE FUNCTION formateur_theme_coherent();
