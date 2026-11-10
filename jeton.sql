-- jeton.sql : jetons de rafraîchissement (UC-T01), à usage unique
-- f.ba -> a.diop (même adaptation qu'au lab 8)
DROP TABLE IF EXISTS session_app, jeton;

CREATE TABLE jeton (
   id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   utilisateur_id uuid NOT NULL REFERENCES utilisateur (id),
   valeur         text NOT NULL UNIQUE,
   expire_le      timestamptz NOT NULL,
   utilise_le     timestamptz                    -- vide tant que le jeton n'a pas servi
);
CREATE TABLE session_app (
   id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
   utilisateur_id uuid NOT NULL REFERENCES utilisateur (id),
   jeton_id       uuid NOT NULL REFERENCES jeton (id),
   ouverte_le     timestamptz NOT NULL DEFAULT clock_timestamp()
);
INSERT INTO jeton (utilisateur_id, valeur, expire_le)
SELECT id, 'RT-' || login || '-' || n, now() + INTERVAL '1 day'
FROM utilisateur CROSS JOIN generate_series(1, 30) AS n
WHERE login = 'a.diop';

-- correction 3 (étape 9.4) : la base refuse deux sessions pour un même jeton, quel que soit le code
ALTER TABLE session_app ADD CONSTRAINT session_jeton_unique UNIQUE (jeton_id);
