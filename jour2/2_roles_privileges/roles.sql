-- roles.sql : groupes, personnes, vues de moindre privilège
-- noms adaptés à notre jeu d'essai : f.ba -> a.diop (Aminata Diop, SN-CASA), coord.sn -> coord.casa

-- 1. Les groupes, puis les personnes
-- (rôles communs à tout le serveur : on ne les crée que s'ils n'existent pas, pour pouvoir relancer
--  le fichier ; aucun secret dans le dépôt : les mots de passe se définissent à part, dans psql)
DO $$
DECLARE
  g text;
  p text[];
BEGIN
  FOREACH g IN ARRAY ARRAY['qb_apicultrice', 'qb_coordinateur', 'qb_gestionnaire', 'qb_admin'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = g) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN', g);
    END IF;
  END LOOP;
  FOREACH p SLICE 1 IN ARRAY ARRAY[['a.diop', 'qb_apicultrice'], ['awa.diop', 'qb_apicultrice'],
                                   ['coord.casa', 'qb_coordinateur'], ['gest.beeafrica', 'qb_gestionnaire'],
                                   ['admin.beeafrica', 'qb_admin']] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p[1]) THEN
      EXECUTE format('CREATE ROLE %I LOGIN', p[1]);
    END IF;
    EXECUTE format('GRANT %I TO %I', p[2], p[1]);
  END LOOP;
END $$;

INSERT INTO utilisateur (login, role)
SELECT 'gest.beeafrica', 'gestionnaire'
WHERE NOT EXISTS (SELECT 1 FROM utilisateur WHERE login = 'gest.beeafrica');

-- 2. Tout fermer, puis ouvrir le minimum (CONNECT seulement : le lab 10 a besoin de TEMPORARY)
DO $$ BEGIN EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC', current_database()); END $$;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
DO $$ BEGIN EXECUTE format('GRANT CONNECT ON DATABASE %I TO qb_apicultrice, qb_coordinateur, qb_gestionnaire, qb_admin', current_database()); END $$;
GRANT USAGE ON SCHEMA public       TO qb_apicultrice, qb_coordinateur, qb_gestionnaire, qb_admin;
GRANT EXECUTE ON FUNCTION qui()    TO qb_apicultrice, qb_coordinateur, qb_gestionnaire, qb_admin;

-- 3. Chacun ne voit que ses lignes, et les colonnes utiles
CREATE OR REPLACE VIEW v_moi AS
SELECT id, login, role, site_id, apicultrice_id FROM utilisateur WHERE login = qui();

-- apicultrice
CREATE OR REPLACE VIEW v_mes_ruches AS
SELECT r.id, r.code, r.site_id, r.latitude, r.longitude, r.date_installation
FROM ruche r JOIN utilisateur u ON u.apicultrice_id = r.apicultrice_id
WHERE u.login = qui();

CREATE OR REPLACE VIEW v_mes_mesures AS
SELECT m.ruche_id, m.horodatage, m.poids_kg, m.temp_int_c, m.temp_ext_c, m.humidite_pct, m.batterie_pct
FROM mesure m
WHERE m.ruche_id IN (SELECT id FROM v_mes_ruches);

-- l'apicultrice ne donne que ruche_id, date_recolte et quantite_kg : son id est rempli par la base
CREATE OR REPLACE FUNCTION mon_apicultrice() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
  SELECT apicultrice_id FROM utilisateur WHERE login = qui()
$$;

CREATE OR REPLACE VIEW v_mes_recoltes AS
SELECT rc.id, rc.ruche_id, rc.apicultrice_id, rc.date_recolte, rc.quantite_kg, rc.statut
FROM recolte rc
WHERE rc.ruche_id IN (SELECT id FROM v_mes_ruches)
  AND rc.apicultrice_id = mon_apicultrice()
WITH CHECK OPTION;
ALTER VIEW v_mes_recoltes ALTER COLUMN apicultrice_id SET DEFAULT mon_apicultrice();

-- coordinateur : son site seulement
CREATE OR REPLACE VIEW v_ruches_site AS
SELECT r.id, r.code, r.site_id, a.nom, a.telephone
FROM ruche r JOIN apicultrice a ON a.id = r.apicultrice_id
WHERE r.site_id = (SELECT site_id FROM utilisateur WHERE login = qui());

CREATE OR REPLACE VIEW v_recoltes_site AS
SELECT rc.id, r.code, rc.date_recolte, rc.quantite_kg, rc.statut, rc.validee_par, rc.validee_le
FROM recolte rc JOIN ruche r ON r.id = rc.ruche_id
WHERE r.site_id = (SELECT site_id FROM utilisateur WHERE login = qui());

-- 4. Les droits (voir matrice_droits.md)
GRANT SELECT ON v_moi TO qb_apicultrice, qb_coordinateur, qb_gestionnaire, qb_admin;
GRANT SELECT ON v_mes_ruches, v_mes_mesures TO qb_apicultrice;
GRANT SELECT, INSERT (ruche_id, date_recolte, quantite_kg) ON v_mes_recoltes TO qb_apicultrice;
REVOKE ALL ON FUNCTION mon_apicultrice() FROM PUBLIC;            -- créée après le REVOKE général (constat R1)
GRANT EXECUTE ON FUNCTION mon_apicultrice() TO qb_apicultrice;
GRANT SELECT ON v_ruches_site, v_recoltes_site TO qb_coordinateur;
GRANT SELECT ON synthese_site_jour, v_export_bailleur TO qb_gestionnaire;
GRANT EXECUTE ON FUNCTION hmac(text, text, text) TO qb_gestionnaire;   -- utilisée par v_export_bailleur
GRANT SELECT, INSERT, UPDATE ON utilisateur TO qb_admin;               -- pas de DELETE
GRANT SELECT ON journal_audit TO qb_admin;

-- 5. Valider une récolte : le coordinateur, sur son site, et rien d'autre
CREATE OR REPLACE FUNCTION valider_recolte(p_recolte uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  u utilisateur%ROWTYPE;
  n int;
BEGIN
  SELECT * INTO u FROM utilisateur WHERE login = qui();
  IF u.id IS NULL OR u.role <> 'coordinateur' THEN
    RAISE EXCEPTION 'seul un coordinateur peut valider une récolte';
  END IF;
  UPDATE recolte
  SET statut = 'validee', validee_par = u.id, validee_le = now()
  WHERE id = p_recolte
    AND statut = 'declaree'
    AND ruche_id IN (SELECT id FROM ruche WHERE site_id = u.site_id);
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n = 0 THEN
    RAISE EXCEPTION 'récolte introuvable, déjà traitée ou hors de votre site';
  END IF;
END;
$$;
REVOKE ALL ON FUNCTION valider_recolte(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION valider_recolte(uuid) TO qb_coordinateur;

-- vérification
SELECT g.rolname AS groupe, r.rolname AS personne
FROM pg_auth_members m
JOIN pg_roles r ON r.oid = m.member
JOIN pg_roles g ON g.oid = m.roleid
WHERE g.rolname LIKE 'qb\_%' ORDER BY 1, 2;
