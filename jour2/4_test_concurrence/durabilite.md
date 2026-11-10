# Durabilité et sauvegarde – Groupe Omar Akakba

## Les réglages
`SHOW fsync;` -> on, `SHOW synchronous_commit;` -> on, `SHOW wal_level;` -> replica.
Un COMMIT ne répond qu'une fois le WAL écrit sur le disque.

## La sauvegarde vérifiée
```bash
pg_dump -d queenbee -Fc -f queenbee_j2.dump
shasum -a 256 queenbee_j2.dump > queenbee_j2.dump.sha256
createdb queenbee_restore
pg_restore -d queenbee_restore queenbee_j2.dump
psql -d queenbee_restore -c "SELECT count(*) AS journal FROM journal_audit"
psql -d queenbee_restore -c "DELETE FROM journal_audit"
shasum -a 256 -c queenbee_j2.dump.sha256
```
(sur macOS, `shasum -a 256` remplace `sha256sum`)

Résultat : le même nombre de lignes de journal dans la copie, le DELETE refusé (`journal_audit est en ajout seul : DELETE interdit`), et `queenbee_j2.dump: OK`. Seule l'empreinte est commitée, pas le dump (*.dump est dans le .gitignore).

## Ce qu'on perdrait avec synchronous_commit = off
Le COMMIT répondrait avant que le WAL soit sur le disque. En cas de panne, les dernières transactions confirmées (quelques centaines de millisecondes) seraient perdues, alors que l'application les croyait validées : une récolte validée, une ligne de journal d'audit, une session ouverte. La base resterait cohérente, mais la durabilité ne serait plus garantie.

## Pourquoi l'empreinte est gardée ailleurs
Si l'empreinte est à côté de la sauvegarde, celui qui modifie la sauvegarde (un attaquant, un rançongiciel) peut aussi recalculer l'empreinte, et la vérification passerait quand même. Gardée ailleurs (ici dans Git, en vrai dans un coffre ou un autre système), elle prouve que la sauvegarde n'a pas été touchée.

## Ce que pg_dump ne sauvegarde pas
Les rôles (qb_apicultrice, a.diop, coord.casa…) et leurs mots de passe sont communs à tout le serveur : pg_dump ne les contient pas. Il faut les sauvegarder à part avec `pg_dumpall --roles-only`, sinon la base restaurée sur un autre serveur n'a plus ses utilisateurs ni ses droits.

## Durabilité ou sauvegarde
- La durabilité (ACID) fait survivre une transaction validée à une panne : coupure de courant, crash du serveur. Elle ne protège pas contre la perte du disque, une erreur humaine (un DELETE de trop) ou un rançongiciel, qui sont eux aussi « durables ».
- La sauvegarde permet de revenir à un état antérieur : disque perdu, données effacées par erreur ou chiffrées. Elle doit être faite régulièrement, vérifiée (restauration et empreinte) et stockée hors du serveur.
