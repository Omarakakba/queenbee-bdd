-- references.sql : que se passe-t-il quand on supprime ?
-- (CI-MAN-012 n'existe pas chez nous : tests faits sur CI-BOUA-002, qui n'a que des mesures)
--
-- DELETE FROM ruche WHERE code = 'CI-BOUA-002';
-- ERROR:  update or delete on table "ruche" violates foreign key constraint "mesure_ruche_fk" on table "mesure"  -> refus
--
-- BEGIN;
-- ALTER TABLE mesure DROP CONSTRAINT mesure_ruche_fk,
--   ADD CONSTRAINT mesure_ruche_fk FOREIGN KEY (ruche_id) REFERENCES ruche (id) ON DELETE CASCADE;
-- SELECT count(*) FROM mesure;                      -- 48049
-- DELETE FROM ruche WHERE code = 'CI-BOUA-002';     -- DELETE 1
-- SELECT count(*) FROM mesure;                      -- 43681  -> 4 368 mesures de moins ; après le ROLLBACK, tout revient
-- ROLLBACK;

-- une adhésion n'a pas de valeur sans l'apicultrice ou la coopérative : on la supprime avec
ALTER TABLE adhesion
  DROP CONSTRAINT adhesion_apicultrice_fk,
  ADD CONSTRAINT adhesion_apicultrice_fk FOREIGN KEY (apicultrice_id)
      REFERENCES apicultrice (id) ON DELETE CASCADE;
ALTER TABLE adhesion
  DROP CONSTRAINT adhesion_cooperative_fk,
  ADD CONSTRAINT adhesion_cooperative_fk FOREIGN KEY (cooperative_id)
      REFERENCES cooperative (id) ON DELETE CASCADE;

-- les mesures sont des preuves (poids avant un vol) : on refuse de supprimer la ruche
ALTER TABLE mesure
  DROP CONSTRAINT mesure_ruche_fk,
  ADD CONSTRAINT mesure_ruche_fk FOREIGN KEY (ruche_id)
      REFERENCES ruche (id) ON DELETE RESTRICT;
-- les inspections gardent l'historique sanitaire de la ruche
ALTER TABLE inspection
  DROP CONSTRAINT inspection_ruche_fk,
  ADD CONSTRAINT inspection_ruche_fk FOREIGN KEY (ruche_id)
      REFERENCES ruche (id) ON DELETE RESTRICT;
-- les récoltes sont la preuve de production (UC-C02)
ALTER TABLE recolte
  DROP CONSTRAINT recolte_ruche_fk,
  ADD CONSTRAINT recolte_ruche_fk FOREIGN KEY (ruche_id)
      REFERENCES ruche (id) ON DELETE RESTRICT;
-- une alerte (vol, essaimage) doit rester même si on retire la ruche
ALTER TABLE alerte
  DROP CONSTRAINT alerte_ruche_fk,
  ADD CONSTRAINT alerte_ruche_fk FOREIGN KEY (ruche_id)
      REFERENCES ruche (id) ON DELETE RESTRICT;

SELECT conrelid::regclass AS table_, conname,
       CASE confdeltype WHEN 'a' THEN 'NO ACTION' WHEN 'r' THEN 'RESTRICT'
            WHEN 'c' THEN 'CASCADE' WHEN 'n' THEN 'SET NULL' END AS on_delete
FROM pg_constraint
WHERE contype = 'f' AND connamespace = 'public'::regnamespace
ORDER BY on_delete, 1;
-- adhesion_apicultrice_fk et adhesion_cooperative_fk : CASCADE
-- mesure_ruche_fk, inspection_ruche_fk, recolte_ruche_fk, alerte_ruche_fk : RESTRICT
-- les 10 autres : NO ACTION   -> 2 CASCADE, 4 RESTRICT
