-- requetes.sql : cinq questions à la base Queen Bee (Lab 3)
--   psql -U postgres -h localhost -d queenbee -v ON_ERROR_STOP=1 -f requetes.sql

-- Q1. Les ruches du site SN-CASA, avec leur position
-- Algèbre : π code, latitude, longitude ( σ site_id = 'SN-CASA' ( ruche ) )
SELECT code, latitude, longitude
FROM ruche
WHERE site_id = 'SN-CASA'
ORDER BY code;
-- Résultat : 3 lignes

-- Q2. Chaque apicultrice et son nombre de ruches
-- Algèbre : apicultrice ⟕ ruche, puis comptage par apicultrice (id, pas nom)
SELECT a.nom, a.site_id, count(r.id) AS nb_ruches
FROM apicultrice a LEFT JOIN ruche r ON r.apicultrice_id = a.id
GROUP BY a.id, a.nom, a.site_id
ORDER BY nb_ruches DESC, a.nom;
-- Résultat : 8 lignes ; les deux « Aminata Diop » sont bien comptées séparément (SN-CASA et SN-KOLD)

-- Q3. Les ruches jamais inspectées
-- Algèbre : π code ( ruche ) − π code ( ruche ⋈ inspection )
SELECT code FROM ruche
EXCEPT
SELECT r.code FROM ruche r JOIN inspection i ON i.ruche_id = r.id
ORDER BY code;
-- Résultat : 6 lignes

-- Q4. Les sites qui ont au moins une alerte ouverte
-- Algèbre : π site_id, nom ( σ statut = 'ouverte' ( alerte ) ⋈ ruche ⋈ site )
SELECT DISTINCT s.id, s.nom
FROM alerte al
JOIN ruche r ON r.id = al.ruche_id
JOIN site  s ON s.id = r.site_id
WHERE al.statut = 'ouverte'
ORDER BY s.id;
-- Résultat : 2 lignes (chaque site une seule fois grâce à DISTINCT)

-- Q5. Une vue pour le coordinateur : code, site, dernière pesée. Ni nom, ni téléphone.
-- Algèbre : π code, site_id, poids_kg ( ruche ⋈ dernière mesure de chaque ruche )
CREATE OR REPLACE VIEW v_ruche_coordinateur AS
SELECT r.code, r.site_id, m.horodatage AS derniere_mesure, m.poids_kg AS dernier_poids_kg
FROM ruche r
LEFT JOIN LATERAL (
   SELECT horodatage, poids_kg FROM mesure
   WHERE ruche_id = r.id
   ORDER BY horodatage DESC
   LIMIT 1
) m ON true;

SELECT * FROM v_ruche_coordinateur ORDER BY code;
-- Résultat : 11 lignes (une par ruche)

-- Pourquoi une application ne doit-elle jamais faire SELECT * sur la table des apicultrices ?
-- Parce qu'elle récupérerait tout, y compris le nom et le téléphone, même quand elle n'en a pas
-- besoin. Ces données finissent alors dans les écrans, les logs ou les réponses de l'API, et une
-- seule faille suffit pour les faire fuiter. On ne demande que les colonnes utiles (projection),
-- et si on ajoute un jour une colonne sensible, elle ne sortira pas « par accident ».
