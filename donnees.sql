-- donnees.sql : jeu d'essai Queen Bee
BEGIN;
INSERT INTO site (id, nom, pays) VALUES
  ('SN-CASA', 'Casamance', 'Sénégal'),
  ('SN-KOLD', 'Kolda',     'Sénégal'),
  ('CI-BOUA', 'Bouaké',    'Côte d''Ivoire'),
  ('CM-ADAM', 'Adamaoua',  'Cameroun');

INSERT INTO cooperative (code, nom) VALUES
  ('COOP-SN-CASA', 'Les abeilles de Casamance'),
  ('COOP-SN-KOLD', 'Miel de Kolda'),
  ('COOP-CI-BOUA', 'Coopérative apicole de Bouaké'),
  ('COOP-CM-ADAM', 'Ruchers de l''Adamaoua');

INSERT INTO apicultrice (nom, telephone, site_id) VALUES
  ('Aminata Diop',    '+221 77 123 45 01',   'SN-CASA'),
  ('Aminata Diop',    '+221 77 123 45 02',   'SN-KOLD'),     -- homonyme volontaire
  ('Awa Diop',        '+221 77 123 45 03',   'SN-CASA'),
  ('Fatou Sow',       '+221 77 123 45 04',   'SN-KOLD'),
  ('Mariam Kone',     '+225 07 11 22 33 01', 'CI-BOUA'),
  ('Adjoua Kouassi',  '+225 07 11 22 33 02', 'CI-BOUA'),
  ('Brigitte Ngo',    '+237 6 70 11 22 01',  'CM-ADAM'),
  ('Clarisse Mbarga', '+237 6 70 11 22 02',  'CM-ADAM');

INSERT INTO ruche (code, latitude, longitude, date_installation, site_id, apicultrice_id) VALUES
  ('SN-CASA-014', 12.58310, -16.27190, '2024-03-02', 'SN-CASA', (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 01')),
  ('SN-CASA-015', 12.58420, -16.27050, '2024-03-02', 'SN-CASA', (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 01')),
  ('SN-CASA-099', 12.59010, -16.26480, '2025-01-15', 'SN-CASA', (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 03')),
  ('SN-KOLD-011', 12.89440, -14.94120, '2024-06-10', 'SN-KOLD', (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 02')),
  ('SN-KOLD-012', 12.89510, -14.94300, '2024-06-10', 'SN-KOLD', (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 04')),
  ('SN-KOLD-013', 12.89620, -14.94470, '2025-02-20', 'SN-KOLD', (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 04')),
  ('CI-BOUA-001',  7.69020,  -5.03050, '2024-09-01', 'CI-BOUA', (SELECT id FROM apicultrice WHERE telephone = '+225 07 11 22 33 01')),
  ('CI-BOUA-002',  7.69140,  -5.02880, '2024-09-01', 'CI-BOUA', (SELECT id FROM apicultrice WHERE telephone = '+225 07 11 22 33 02')),
  ('CI-BOUA-003',  7.69230,  -5.02710, '2025-03-12', 'CI-BOUA', (SELECT id FROM apicultrice WHERE telephone = '+225 07 11 22 33 02')),
  ('CM-ADAM-001',  7.32150,  13.58420, '2024-11-05', 'CM-ADAM', (SELECT id FROM apicultrice WHERE telephone = '+237 6 70 11 22 01')),
  ('CM-ADAM-002',  7.32280,  13.58610, '2024-11-05', 'CM-ADAM', (SELECT id FROM apicultrice WHERE telephone = '+237 6 70 11 22 02'));

-- chaque apicultrice adhère à la coopérative de son site
INSERT INTO adhesion (apicultrice_id, cooperative_id)
SELECT a.id, c.id FROM apicultrice a JOIN cooperative c ON c.code = 'COOP-' || a.site_id;

-- un compte par apicultrice (a.diop sort trois fois)
INSERT INTO utilisateur (login, role, site_id, apicultrice_id)
SELECT lower(left(nom, 1)) || '.' || lower(split_part(nom, ' ', 2)), 'apicultrice', site_id, id
FROM apicultrice;

INSERT INTO utilisateur (login, role, site_id) VALUES
  ('coord.casa', 'coordinateur', 'SN-CASA'),
  ('admin', 'administrateur', NULL);

-- 48 mesures par ruche
INSERT INTO mesure (ruche_id, horodatage, poids_kg, temp_int_c, temp_ext_c, humidite_pct, activite_sonore, batterie_pct)
SELECT r.id, TIMESTAMPTZ '2027-03-14 00:00+00' + h * INTERVAL '30 minutes',
       round((35 + random() * 10)::numeric, 2), round((33 + random() * 3)::numeric, 1),
       round((22 + random() * 12)::numeric, 1), 50 + floor(random() * 30)::int,
       200 + floor(random() * 300)::int, 100 - h
FROM ruche r CROSS JOIN generate_series(0, 47) AS h;

-- 6 inspections, 6 ruches jamais inspectées
INSERT INTO inspection (ruche_id, apicultrice_id, date_inspection, etat_colonie, reine_presente, observations) VALUES
  ((SELECT id FROM ruche WHERE code = 'SN-CASA-014'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 01'), '2027-03-01', 'forte',   true,  'beaucoup de couvain'),
  ((SELECT id FROM ruche WHERE code = 'SN-CASA-014'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 01'), '2027-03-12', 'forte',   true,  'cadres pleins'),
  ((SELECT id FROM ruche WHERE code = 'SN-KOLD-011'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 02'), '2027-03-05', 'moyenne', true,  NULL),
  ((SELECT id FROM ruche WHERE code = 'SN-KOLD-012'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 04'), '2027-03-06', 'faible',  false, 'reine pas trouvée'),
  ((SELECT id FROM ruche WHERE code = 'CI-BOUA-001'), (SELECT id FROM apicultrice WHERE telephone = '+225 07 11 22 33 01'), '2027-03-08', 'forte',  true,  NULL),
  ((SELECT id FROM ruche WHERE code = 'CM-ADAM-001'), (SELECT id FROM apicultrice WHERE telephone = '+237 6 70 11 22 01'), '2027-03-10', 'moyenne', true,  'fourmis');

-- 3 récoltes : une validée, deux déclarées
INSERT INTO recolte (ruche_id, apicultrice_id, date_recolte, quantite_kg, statut, validee_par, validee_le) VALUES
  ((SELECT id FROM ruche WHERE code = 'SN-CASA-014'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 01'),
   '2027-03-12', 18.50, 'validee', (SELECT id FROM utilisateur WHERE login = 'coord.casa'), '2027-03-13 09:15+00'),
  ((SELECT id FROM ruche WHERE code = 'SN-KOLD-012'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 123 45 04'),
   '2027-03-11', 12.00, 'declaree', NULL, NULL),
  ((SELECT id FROM ruche WHERE code = 'CI-BOUA-001'), (SELECT id FROM apicultrice WHERE telephone = '+225 07 11 22 33 01'),
   '2027-03-13', 15.75, 'declaree', NULL, NULL);

-- 4 alertes sur 2 sites, 2 ouvertes
INSERT INTO alerte (ruche_id, type_alerte, horodatage, niveau_confiance, statut) VALUES
  ((SELECT id FROM ruche WHERE code = 'SN-CASA-099'), 'essaimage',          '2027-03-14 11:30+00', 0.82, 'ouverte'),
  ((SELECT id FROM ruche WHERE code = 'SN-CASA-015'), 'capteur_silencieux', '2027-03-10 06:00+00', 0.95, 'fermee'),
  ((SELECT id FROM ruche WHERE code = 'CM-ADAM-001'), 'vol',                '2027-03-14 02:00+00', 0.67, 'ouverte'),
  ((SELECT id FROM ruche WHERE code = 'CM-ADAM-002'), 'essaimage',          '2027-03-09 14:30+00', 0.40, 'fermee');
COMMIT;
