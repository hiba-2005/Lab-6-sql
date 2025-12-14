USE bibliotheque;

-- Étape 2 

-- INNER JOIN : emprunts + nom de l’abonné
SELECT e.ouvrage_id, e.abonne_id, a.nom, e.date_debut, e.date_fin
FROM emprunt e
INNER JOIN abonne a ON e.abonne_id = a.id;

--  LEFT JOIN : tous les ouvrages + date de leur dernier emprunt (si existe)
SELECT o.id, o.titre, MAX(e.date_debut) AS dernier_emprunt
FROM ouvrage o
LEFT JOIN emprunt e ON e.ouvrage_id = o.id
GROUP BY o.id, o.titre;

-- CROSS JOIN 
SELECT a.nom AS abonne, au.nom AS auteur
FROM abonne a
CROSS JOIN auteur au;

-- Étape 3 

-- Créer  une vue 
CREATE VIEW vue_emprunts_par_abonne AS
SELECT a.id, a.nom, COUNT(e.ouvrage_id) AS total_emprunts
FROM abonne a
LEFT JOIN emprunt e ON e.abonne_id = a.id
GROUP BY a.id, a.nom;

--  Interroger la vue 
SELECT *
FROM vue_emprunts_par_abonne
WHERE total_emprunts > 5;

-- Étape 4 

-- Sous-requête dans SELECT : nb emprunts pour chaque ouvrage
SELECT
  o.titre,
  (SELECT COUNT(*)
   FROM emprunt e
   WHERE e.ouvrage_id = o.id
  ) AS nb_emprunts
FROM ouvrage o;

-- Sous-requête dans WHERE : abonnés avec > 3 emprunts sans GROUP BY externe
SELECT nom, email
FROM abonne
WHERE id IN (
  SELECT abonne_id
  FROM emprunt
  GROUP BY abonne_id
  HAVING COUNT(*) > 3
);

-- Étape 5 

-- Pour chaque abonné : titre du premier emprunt (si existe)
SELECT a.nom,
  (SELECT o.titre
   FROM emprunt e2
   JOIN ouvrage o ON o.id = e2.ouvrage_id
   WHERE e2.abonne_id = a.id
   ORDER BY e2.date_debut
   LIMIT 1
  ) AS premier_titre
FROM abonne a;


-- Étape 6 

--  Créer  une vue 
CREATE VIEW vue_emprunts_mensuels AS
SELECT 
  YEAR(date_debut) AS annee,
  MONTH(date_debut) AS mois,
  COUNT(*) AS total_emprunts
FROM emprunt
GROUP BY annee, mois;

SELECT v.annee, v.mois, v.total_emprunts
FROM vue_emprunts_mensuels v
WHERE v.total_emprunts = (
  SELECT MAX(v2.total_emprunts)
  FROM vue_emprunts_mensuels v2
  WHERE v2.annee = v.annee
);

-- Étape 7 

-- Exercice 1
SELECT au.id, au.nom
FROM auteur au
LEFT JOIN ouvrage o ON o.auteur_id = au.id
WHERE o.id IS NULL;

-- Exercice 2
CREATE OR REPLACE VIEW vue_abonnes_actifs_mensuels AS
SELECT
  YEAR(date_debut) AS annee,
  MONTH(date_debut) AS mois,
  COUNT(DISTINCT abonne_id) AS abonnes_actifs
FROM emprunt
GROUP BY YEAR(date_debut), MONTH(date_debut);


SELECT *
FROM vue_abonnes_actifs_mensuels
ORDER BY annee, mois;

-- Exercice 3
SELECT
  o.id,
  o.titre,
  (SELECT a.nom
   FROM emprunt e
   JOIN abonne a ON a.id = e.abonne_id
   WHERE e.ouvrage_id = o.id
   ORDER BY e.date_debut DESC
   LIMIT 1
  ) AS dernier_abonne
FROM ouvrage o;

