-- check.sql : refuser les valeurs impossibles
ALTER TABLE mesure DROP CONSTRAINT IF EXISTS mesure_batterie_0_100,
                   DROP CONSTRAINT IF EXISTS mesure_humidite_0_100,
                   DROP CONSTRAINT IF EXISTS mesure_poids_positif;
ALTER TABLE mesure
  ADD CONSTRAINT mesure_batterie_0_100 CHECK (batterie_pct BETWEEN 0 AND 100),
  ADD CONSTRAINT mesure_humidite_0_100 CHECK (humidite_pct BETWEEN 0 AND 100),
  ADD CONSTRAINT mesure_poids_positif  CHECK (poids_kg >= 0);

-- le jour 1 utilisait 'administrateur' : la ligne existante violait la règle
SELECT login, role FROM utilisateur WHERE role NOT IN ('apicultrice', 'coordinateur', 'gestionnaire', 'admin');
-- admin | administrateur
ALTER TABLE utilisateur DROP CONSTRAINT IF EXISTS utilisateur_role_check,
                        DROP CONSTRAINT IF EXISTS utilisateur_role_valide;
UPDATE utilisateur SET role = 'admin' WHERE role = 'administrateur';
ALTER TABLE utilisateur
  ADD CONSTRAINT utilisateur_role_valide CHECK (role IN ('apicultrice', 'coordinateur', 'gestionnaire', 'admin'));

-- même chose pour les alertes : 'fermee' devient 'traitee'
SELECT id, statut FROM alerte WHERE statut NOT IN ('ouverte', 'en_cours', 'traitee');
-- 2 lignes 'fermee'
ALTER TABLE alerte DROP CONSTRAINT IF EXISTS alerte_statut_check,
                   DROP CONSTRAINT IF EXISTS alerte_statut_valide;
UPDATE alerte SET statut = 'traitee' WHERE statut = 'fermee';
ALTER TABLE alerte
  ADD CONSTRAINT alerte_statut_valide CHECK (statut IN ('ouverte', 'en_cours', 'traitee'));

ALTER TABLE recolte DROP CONSTRAINT IF EXISTS recolte_statut_valide;
ALTER TABLE recolte
  ADD CONSTRAINT recolte_statut_valide CHECK (statut IN ('declaree', 'validee', 'ecart'));
-- un écart est aussi constaté par un coordinateur : on garde qui et quand
ALTER TABLE recolte DROP CONSTRAINT recolte_validation_tracee,
  ADD CONSTRAINT recolte_validation_tracee CHECK (
        (statut = 'declaree' AND validee_par IS NULL AND validee_le IS NULL)
     OR (statut IN ('validee', 'ecart') AND validee_par IS NOT NULL AND validee_le IS NOT NULL));

-- Tests
-- INSERT INTO mesure (ruche_id, horodatage, poids_kg, batterie_pct)
-- SELECT id, '2027-03-16 06:00+00', 32.0, 150 FROM ruche WHERE code = 'SN-CASA-014';
-- ERROR:  new row for relation "mesure" violates check constraint "mesure_batterie_0_100"
-- UPDATE alerte SET statut = 'fermée' WHERE statut = 'traitee';
-- ERROR:  new row for relation "alerte" violates check constraint "alerte_statut_valide"
