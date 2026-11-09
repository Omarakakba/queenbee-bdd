# query.py : VERSION CORRIGÉE, requête paramétrée (Lab 3)
#
# | Saisie                                                  | query_vuln.py                          | query.py |
# | code normal (SN-CASA-014)                               | 1 ligne                                | 1 ligne  |
# | ' OR '1'='1                                             | 11 lignes : toutes les ruches          | 0 ligne  |
# | ' UNION SELECT nom, telephone FROM apicultrice --       | 8 lignes : noms et téléphones des 8 apicultrices | 0 ligne  |
#
# Pourquoi query.py résiste : la requête et la valeur partent séparément vers PostgreSQL.
# Le %s est une case réservée : quoi que tape l'utilisateur, la base le traite comme UNE valeur
# de texte à comparer au code, jamais comme du SQL. Les apostrophes, OR, UNION et -- ne sont
# donc que des caractères ; aucune ruche ne s'appelle « ' OR '1'='1 », d'où 0 ligne.
#
# Aucun secret dans le code : la connexion se règle par les variables PG... du terminal.
import psycopg

conn = psycopg.connect(dbname="queenbee")
code = input("Code ruche : ")

rows = conn.execute(
    "SELECT code, site_id FROM ruche WHERE code = %s",
    (code,),
).fetchall()

for row in rows:
    print(row)
print(len(rows), "ligne(s)")
