-- audit.sql : qui a fait quoi (fonctions identiques à l'exemple)

-- 1. Qui agit ? Le rôle choisi par SET ROLE, sinon l'utilisateur connecté
CREATE OR REPLACE FUNCTION qui() RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT CASE WHEN current_setting('role') = 'none' THEN session_user::text
              ELSE current_setting('role') END
$$;

-- 2. Une ligne de journal par ligne touchée
CREATE OR REPLACE FUNCTION audit_ligne() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO journal_audit (acteur, table_cible, operation, ligne_id, avant, apres)
  VALUES (qui(), TG_TABLE_NAME, TG_OP,
          CASE WHEN TG_OP = 'DELETE' THEN OLD.id::text ELSE NEW.id::text END,
          CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
          CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END);
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS recolte_audit ON recolte;
CREATE TRIGGER recolte_audit                       -- preuve de production (UC-C02)
AFTER INSERT OR UPDATE OR DELETE ON recolte
FOR EACH ROW EXECUTE FUNCTION audit_ligne();

DROP TRIGGER IF EXISTS utilisateur_audit ON utilisateur;
CREATE TRIGGER utilisateur_audit                   -- gestion des comptes (UC-AD01)
AFTER INSERT OR UPDATE OR DELETE ON utilisateur
FOR EACH ROW EXECUTE FUNCTION audit_ligne();

-- 3. Le journal en ajout seul
CREATE OR REPLACE FUNCTION journal_interdit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'journal_audit est en ajout seul : % interdit', TG_OP;
END;
$$;
DROP TRIGGER IF EXISTS journal_ajout_seul ON journal_audit;
CREATE TRIGGER journal_ajout_seul
BEFORE UPDATE OR DELETE ON journal_audit
FOR EACH ROW EXECUTE FUNCTION journal_interdit();
DROP TRIGGER IF EXISTS journal_sans_truncate ON journal_audit;
CREATE TRIGGER journal_sans_truncate          -- TRUNCATE a besoin de son propre trigger
BEFORE TRUNCATE ON journal_audit
FOR EACH STATEMENT EXECUTE FUNCTION journal_interdit();

-- Tests (SN-CASA-011 n'existe pas chez nous : récolte validée de SN-CASA-014, 18.50 kg)
-- UPDATE recolte SET quantite_kg = 20.00
-- WHERE ruche_id = (SELECT id FROM ruche WHERE code = 'SN-CASA-014');
-- SELECT acteur, table_cible, operation, avant ->> 'quantite_kg' AS avant, apres ->> 'quantite_kg' AS apres
-- FROM journal_audit;
--  postgres | recolte | UPDATE | 18.50 | 20.00
--
-- UPDATE journal_audit SET acteur = 'personne';
-- DELETE FROM journal_audit;
-- TRUNCATE journal_audit;
-- SELECT count(*) FROM journal_audit;
-- ERROR:  journal_audit est en ajout seul : UPDATE interdit
-- ERROR:  journal_audit est en ajout seul : DELETE interdit
-- ERROR:  journal_audit est en ajout seul : TRUNCATE interdit
-- count = 1 : le journal n'a pas bougé
--
-- ALTER TABLE journal_audit DISABLE TRIGGER journal_ajout_seul;
-- ALTER TABLE journal_audit ENABLE TRIGGER journal_ajout_seul;
-- ALTER TABLE, ALTER TABLE : le propriétaire peut couper le trigger (limite notée dans matrice_droits.md)
