# Concurrence – Groupe Omar Akakba

Adaptations : f.ba -> a.diop (jetons RT-a.diop-1 à RT-a.diop-30), coord.sn -> coord.casa, SN-CASA-011 -> SN-KOLD-012 (la seule récolte encore déclarée sur un site sénégalais).

## 9.1 · L'action et sa trace

Sans transaction, l'application écrit sa trace avant d'agir :
- `journal_appli` : « récolte SN-KOLD-012 validée par coord.casa » ;
- l'UPDATE sans validee_par est refusé : `new row for relation "recolte" violates check constraint "recolte_validation_tracee"` ;
- la récolte est toujours `declaree`. La trace ment.

Avec une transaction et le trigger d'audit :

| Étape | journal_audit |
|---|---|
| avant BEGIN | 4 lignes |
| après la validation complète, dans la transaction | 5 lignes |
| après `SELECT 1 / 0;` | `ERROR: current transaction is aborted, commands ignored until end of transaction block` |
| après ROLLBACK | 4 lignes, récolte de nouveau `declaree` |

L'action et sa trace partent ensemble, ou pas du tout.

## 9.2 · La course au jeton, dans deux terminaux (RT-a.diop-5 ; un premier essai avec RT-a.diop-1 a échoué car tout était tapé dans la même fenêtre)

| Temps | Terminal A | Terminal B |
|---|---|---|
| T1 | BEGIN | |
| T2 | | BEGIN |
| T3 | SELECT du jeton : utilise_le vide | |
| T4 | | SELECT du jeton : utilise_le vide |
| T5 | UPDATE jeton : UPDATE 1 | |
| T6 | INSERT INTO session_app : INSERT 0 1 | |
| T7 | COMMIT | |
| T8 | | UPDATE jeton : UPDATE 1 |
| T9 | | INSERT INTO session_app : INSERT 0 1 |
| T10 | | COMMIT |
| T11 | comptage : **2 sessions** avec ce jeton | |

Les deux SELECT ont vérifié avant que l'un n'agisse : un jeton à usage unique a servi deux fois.

## 9.3 · La course par un programme

| Programme | Jeton | Résultat |
|---|---|---|
| course_jeton.py | RT-a.diop-10 | accepté, accepté : 2 sessions |
| course_jeton.py | RT-a.diop-11 | accepté, accepté : 2 sessions |
| course_jeton_corrige.py | RT-a.diop-12 | un accepté, un refusé : 1 session |
| course_jeton_corrige.py | RT-a.diop-13 | un accepté, un refusé : 1 session |

## 9.4 · Les quatre corrections

1. FOR UPDATE (RT-a.diop-2) : au T4, B se fige. Dès le COMMIT de A, B voit utilise_le rempli ; ROLLBACK dans B.
2. UPDATE … RETURNING (RT-a.diop-3) : A reçoit un id, B attend puis reçoit 0 ligne.
3. UNIQUE (jeton_id) : d'abord `could not create unique index "session_jeton_unique"` (doublons des tests), DELETE 2 en gardant la plus ancienne session, puis ALTER TABLE. course_jeton.py RT-a.diop-14 : 1 session, et `erreur de la base : duplicate key value violates unique constraint "session_jeton_unique"` pour l'autre requête.
4. REPEATABLE READ (RT-a.diop-4) : l'UPDATE de B échoue avec `could not serialize access due to concurrent update`.

| Correction | Où agit-elle ? | Que voit la seconde requête ? | Avantage | Limite |
|---|---|---|---|---|
| SELECT … FOR UPDATE | dans le code, au moment de la lecture | elle attend, puis voit le jeton déjà utilisé | simple, la vérification reste lisible | il faut penser à l'écrire partout ; un oubli suffit |
| UPDATE … WHERE … RETURNING | dans le code, une seule instruction | elle attend, puis 0 ligne | pas de verrou explicite, impossible de séparer vérifier et agir | ne protège que ce code-là |
| UNIQUE (jeton_id) | dans la base | une erreur duplicate key | protège quel que soit le programme, même le code vulnérable | l'application reçoit une erreur à gérer |
| REPEATABLE READ | dans la transaction | une erreur could not serialize access | aucune modification de la requête | l'application doit annuler et réessayer |

Le trigger du lab 6 est aussi un « vérifier, puis agir » : il regarde suivi_formation, puis laisse insérer. Deux insertions simultanées pour la même apicultrice et le même thème, avec deux formateurs différents, ne voient pas la ligne de l'autre (pas encore validée) : les deux passent, et la règle est contournée. La correction la plus sûre est une contrainte : recopier le thème dans suivi_formation avec UNIQUE (apicultrice_id, theme) et une clé étrangère (formateur_id, theme) vers formateur (id, theme). La base refuse alors le doublon, comme UNIQUE (jeton_id). On pourrait aussi verrouiller la ligne de l'apicultrice (SELECT … FOR UPDATE dans le trigger) ou passer en SERIALIZABLE.
