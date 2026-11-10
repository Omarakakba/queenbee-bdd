-- tests_audit.sql : tests de l'étape 8.3 (points 2 à 4), lancés en postgres
-- (SN-CASA-011 n'existe pas chez nous : récolte validée de SN-CASA-014)

-- 2. une modification, et sa trace
UPDATE recolte SET quantite_kg = 20.00
WHERE ruche_id = (SELECT id FROM ruche WHERE code = 'SN-CASA-014');
SELECT acteur, table_cible, operation,
       avant ->> 'quantite_kg' AS avant, apres ->> 'quantite_kg' AS apres
FROM journal_audit;
-- UPDATE 1
--  acteur  | table_cible | operation | avant | apres
-- postgres | recolte     | UPDATE    | 18.50 | 20.00

-- 3. effacer ses traces
UPDATE journal_audit SET acteur = 'personne';
-- ERROR:  journal_audit est en ajout seul : UPDATE interdit
DELETE FROM journal_audit;
-- ERROR:  journal_audit est en ajout seul : DELETE interdit
TRUNCATE journal_audit;
-- ERROR:  journal_audit est en ajout seul : TRUNCATE interdit
SELECT count(*) FROM journal_audit;
-- le nombre de lignes n'a pas bougé

-- 4. la limite : le propriétaire peut couper la protection
ALTER TABLE journal_audit DISABLE TRIGGER journal_ajout_seul;
-- ALTER TABLE
ALTER TABLE journal_audit ENABLE TRIGGER journal_ajout_seul;
-- ALTER TABLE
-- d'où la copie du journal hors de la base, vers le SIEM (voir matrice_droits.md)
