-- tests_contournement.sql : on joue l'attaquant
-- f.ba -> a.diop, coord.sn -> coord.casa ; la récolte d'un autre site (CM-BAF) -> CI-BOUA-001
SELECT id AS ruche_autre FROM ruche WHERE code = 'SN-KOLD-011' \gset
SELECT rc.id AS recolte_autre_site FROM recolte rc JOIN ruche r ON r.id = rc.ruche_id
WHERE r.code = 'CI-BOUA-001' \gset

SET ROLE "a.diop";

-- 1. lire apicultrice directement
SELECT nom, telephone FROM apicultrice;
-- ERROR:  permission denied for table apicultrice  -> attendu

-- 2. lire v_mes_ruches
SELECT code FROM v_mes_ruches;
-- SN-CASA-014, SN-CASA-015 : ses deux ruches seulement  -> attendu

-- 3. déclarer une récolte sur sa ruche
INSERT INTO v_mes_recoltes (ruche_id, date_recolte, quantite_kg)
SELECT id, '2027-03-16', 9.50 FROM v_mes_ruches WHERE code = 'SN-CASA-015';
-- INSERT 0 1  -> attendu

-- 4. déclarer une récolte sur la ruche d'une autre
INSERT INTO v_mes_recoltes (ruche_id, date_recolte, quantite_kg)
VALUES (:'ruche_autre', '2027-03-16', 9.50);
-- ERROR:  new row violates check option for view "v_mes_recoltes"  -> attendu

-- 5. déclarer une récolte déjà validée
INSERT INTO v_mes_recoltes (ruche_id, date_recolte, quantite_kg, statut)
SELECT id, '2027-03-16', 9.50, 'validee' FROM v_mes_ruches WHERE code = 'SN-CASA-015';
-- ERROR:  permission denied for view v_mes_recoltes (pas de droit sur la colonne statut)  -> attendu

-- 6. modifier un volume
UPDATE recolte SET quantite_kg = 99;
-- ERROR:  permission denied for table recolte  -> attendu

-- 7. valider elle-même
SELECT valider_recolte(:'recolte_autre_site');
-- ERROR:  permission denied for function valider_recolte  -> attendu

-- 8. fausse ligne dans le journal
INSERT INTO journal_audit (acteur, table_cible, operation) VALUES ('coord.casa', 'recolte', 'DELETE');
-- ERROR:  permission denied for table journal_audit  -> attendu

-- 9. couper l'audit
ALTER TABLE recolte DISABLE TRIGGER recolte_audit;
-- ERROR:  must be owner of table recolte  -> attendu

RESET ROLE;
SELECT id AS recolte_test3 FROM recolte WHERE date_recolte = '2027-03-16' AND quantite_kg = 9.50 \gset

SET ROLE "coord.casa";

-- 10. valider la récolte du test 3, puis la revalider
SELECT valider_recolte(:'recolte_test3');
SELECT valider_recolte(:'recolte_test3');
-- 1er appel : passe ; 2e appel : ERROR:  récolte introuvable, déjà traitée ou hors de votre site  -> attendu

-- 11. valider une récolte d'un autre site
SELECT valider_recolte(:'recolte_autre_site');
-- ERROR:  récolte introuvable, déjà traitée ou hors de votre site  -> attendu

RESET ROLE;
SET ROLE "admin.beeafrica";

-- 12. lire le journal, puis supprimer un utilisateur
SELECT acteur, table_cible, operation FROM journal_audit ORDER BY id;
DELETE FROM utilisateur WHERE login = 'awa.diop';
-- journal lu :
--   postgres   | recolte     | UPDATE   (test de audit.sql)
--   postgres   | utilisateur | INSERT   (gest.beeafrica ajouté par roles.sql)
--   a.diop     | recolte     | INSERT   (test 3)
--   coord.casa | recolte     | UPDATE   (test 10, via la fonction SECURITY DEFINER)
-- puis ERROR:  permission denied for table utilisateur  -> attendu

RESET ROLE;
