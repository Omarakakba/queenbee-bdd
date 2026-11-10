# Matrice des droits – Groupe Omar Akakba

| Objet | apicultrice | coordinateur | gestionnaire | admin |
|---|---|---|---|---|
| ses ruches et leurs mesures | lire (v_mes_ruches, v_mes_mesures) | lire les ruches de son site | non (seulement la synthèse) | non |
| déclarer une récolte | sur ses ruches (v_mes_recoltes) | non | non | non |
| valider une récolte (UC-C02) | non | sur son site, par valider_recolte() | non | non |
| ruches et téléphones de son site | non | lire (v_ruches_site) | non | non |
| synthèse et export (UC-G01, UC-G02) | non | non | lire (synthese_site_jour, v_export_bailleur) | non |
| comptes utilisateurs (UC-AD01) | lire le sien (v_moi) | lire le sien (v_moi) | lire le sien (v_moi) | lire, créer, modifier (pas supprimer) |
| journal d'audit | non | non | non | lire |

Personne n'a de droit direct sur les tables, sauf l'admin sur utilisateur et journal_audit. Tout passe par des vues qui filtrent avec qui().

Noms adaptés à notre jeu d'essai : f.ba -> a.diop (Aminata Diop, SN-CASA), coord.sn -> coord.casa.

## Limite du journal d'audit
En postgres, `ALTER TABLE journal_audit DISABLE TRIGGER journal_ajout_seul;` passe : le propriétaire de la table (ou un superutilisateur) peut couper la protection, modifier le journal, puis la remettre. Le journal dans la base ne suffit donc pas comme preuve contre un administrateur malveillant : il faut aussi l'envoyer hors de la base, vers le SIEM du cahier des charges, où l'administrateur de la base ne peut pas l'effacer.
