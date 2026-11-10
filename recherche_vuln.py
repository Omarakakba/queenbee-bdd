# Démonstration volontairement vulnérable (lab 10) : ne jamais utiliser, voir recherche.py
import psycopg

conn = psycopg.connect(dbname="queenbee")
site = input("Site : ")
tri = input("Trier par (code ou date_installation) : ")
sql = ("SELECT code, site_id, date_installation FROM ruche "
       "WHERE site_id = %s ORDER BY " + tri)          # valeur paramétrée, tri recopié
try:
    for row in conn.execute(sql, (site,)):
        print(row)
except psycopg.Error as e:
    print("Erreur :", e)                              # affiche l'erreur de la base
