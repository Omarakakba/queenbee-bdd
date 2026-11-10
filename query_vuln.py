# Démonstration volontairement vulnérable (jour 1, lab 3) : ne jamais utiliser, voir query.py
import psycopg

conn = psycopg.connect(dbname="queenbee")
code = input("Code ruche : ")
sql = "SELECT code, site_id FROM ruche WHERE code = '" + code + "'"
print("Requête envoyée :", sql)
for row in conn.execute(sql):
    print(row)
