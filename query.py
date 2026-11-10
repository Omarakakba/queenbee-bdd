# | Saisie                 | query_vuln.py                     | query.py |
# | code normal            | 1 ligne                           | 1 ligne  |
# | ' OR '1'='1            | 11 lignes (toutes les ruches)     | 0 ligne  |
# | ' UNION SELECT ... --  | 8 lignes (noms et téléphones)     | 0 ligne  |
# Pourquoi query.py résiste : la requête et la valeur sont envoyées séparément.
# La saisie est toujours traitée comme un texte à comparer au code, jamais comme du SQL.
import psycopg

conn = psycopg.connect(dbname="queenbee")
code = input("Code ruche : ")
rows = conn.execute("SELECT code, site_id FROM ruche WHERE code = %s", (code,)).fetchall()
for row in rows:
    print(row)
