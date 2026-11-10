-- corrections.sql : corrections de la revue de sécurité (lancé en postgres)

-- P2 : la vue de carte ne montre que ses ruches, sans nom ni téléphone
DROP VIEW IF EXISTS v_carte_ruches;
CREATE VIEW v_carte_ruches WITH (security_barrier = true) AS
SELECT r.code, r.latitude, r.longitude
FROM ruche r JOIN utilisateur u ON u.apicultrice_id = r.apicultrice_id
WHERE u.login = qui();
GRANT SELECT ON v_carte_ruches TO qb_apicultrice;

-- P3 / R2 : le filtre des vues passe avant les conditions de l'utilisateur
ALTER VIEW v_moi           SET (security_barrier = true);
ALTER VIEW v_mes_ruches    SET (security_barrier = true);
ALTER VIEW v_mes_mesures   SET (security_barrier = true);
ALTER VIEW v_mes_recoltes  SET (security_barrier = true);
ALTER VIEW v_ruches_site   SET (security_barrier = true);
ALTER VIEW v_recoltes_site SET (security_barrier = true);
-- plus de fonction espion dans pg_temp
DO $$ BEGIN EXECUTE format('REVOKE TEMPORARY ON DATABASE %I FROM PUBLIC', current_database()); END $$;

-- R1 : aucune fonction exécutable par PUBLIC, y compris celles créées plus tard
REVOKE ALL ON FUNCTION mon_apicultrice() FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
