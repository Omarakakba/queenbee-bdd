-- requetes.sql : cinq questions à la base Queen Bee

-- Q1. Les ruches du site SN-CASA, avec leur position
-- Algèbre : π code, latitude, longitude ( σ site_id = 'SN-CASA' ( ruche ) )
SELECT code, latitude, longitude FROM ruche WHERE site_id = 'SN-CASA' ORDER BY code;
-- Résultat : 3 lignes

-- Q2. Chaque apicultrice et son nombre de ruches : apicultrice ⟕ ruche, puis comptage
SELECT a.nom, a.site_id, count(r.id) AS nb_ruches
FROM apicultrice a LEFT JOIN ruche r ON r.apicultrice_id = a.id
GROUP BY a.id, a.nom, a.site_id ORDER BY nb_ruches DESC, a.nom;
-- Résultat : 8 lignes (les deux Aminata Diop sont séparées)

-- Q3. Les ruches jamais inspectées
-- Algèbre : π code ( ruche ) − π ruche_id ( inspection )
SELECT code FROM ruche
WHERE id IN (SELECT id FROM ruche EXCEPT SELECT ruche_id FROM inspection) ORDER BY code;
-- Résultat : 6 lignes

-- Q4. Les sites qui ont au moins une alerte ouverte
-- Algèbre : π site_id ( σ statut = 'ouverte' ( alerte ) ⋈ ruche )
SELECT DISTINCT r.site_id
FROM alerte al JOIN ruche r ON r.id = al.ruche_id
WHERE al.statut = 'ouverte' ORDER BY r.site_id;
-- Résultat : 2 lignes

-- Q5. Vue pour le coordinateur : code, site, dernière pesée (sans nom ni téléphone)
CREATE OR REPLACE VIEW v_ruche_coordinateur AS
SELECT r.code, r.site_id, m.poids_kg, m.horodatage
FROM ruche r
JOIN LATERAL (SELECT poids_kg, horodatage FROM mesure
              WHERE ruche_id = r.id ORDER BY horodatage DESC LIMIT 1) m ON true;
SELECT * FROM v_ruche_coordinateur ORDER BY code;
-- Résultat : 11 lignes

-- Pourquoi une application ne doit jamais faire SELECT * sur apicultrice ?
-- Parce qu'elle récupère le nom et le téléphone même quand elle n'en a pas besoin.
-- Ces données peuvent ensuite fuiter (écran, logs, API). On ne sélectionne que les
-- colonnes utiles, et une colonne sensible ajoutée plus tard ne sortira pas par erreur.
