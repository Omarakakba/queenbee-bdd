# query_vuln.py : VERSION VULNÉRABLE, à ne jamais utiliser en vrai (Lab 3)
# Aucun secret dans le code : la connexion se règle par les variables PG... du terminal.
import psycopg

conn = psycopg.connect(dbname="queenbee")
code = input("Code ruche : ")

# DANGER : la saisie est collée directement dans le texte de la requête
sql = "SELECT code, site_id FROM ruche WHERE code = '" + code + "'"
print("Requête envoyée :", sql)

rows = conn.execute(sql).fetchall()
for row in rows:
    print(row)
print(len(rows), "ligne(s)")
