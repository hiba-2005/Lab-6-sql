USE universite;


-- 1) INNER JOIN
SELECT
  et.nom       AS etudiant,
  c.titre      AS cours,
  ex.date_examen,
  ex.score
FROM examen ex
INNER JOIN inscription i
  ON i.etudiant_id = ex.etudiant_id
 AND i.enseignement_id = ex.enseignement_id
 AND i.date_inscription = ex.date_inscription
INNER JOIN etudiant et
  ON et.id = i.etudiant_id
INNER JOIN enseignement en
  ON en.id = i.enseignement_id
INNER JOIN cours c
  ON c.id = en.cours_id;


-- 2) LEFT JOIN

SELECT
  et.id,
  et.nom,
  COALESCE(COUNT(ex.id), 0) AS total_examens
FROM etudiant et
LEFT JOIN examen ex
  ON ex.etudiant_id = et.id
GROUP BY et.id, et.nom;


-- 3) RIGHT JOIN
SELECT
  c.id,
  c.titre,
  COALESCE(COUNT(DISTINCT i.etudiant_id), 0) AS nb_etudiants
FROM inscription i
JOIN enseignement en
  ON en.id = i.enseignement_id
RIGHT JOIN cours c
  ON c.id = en.cours_id
GROUP BY c.id, c.titre;

-- 4) CROSS JOIN

SELECT
  et.nom AS etudiant,
  pr.nom AS professeur
FROM etudiant et
CROSS JOIN professeur pr
LIMIT 20;

-- 5) Création de vue

CREATE OR REPLACE VIEW vue_performances AS
SELECT
  et.id AS etudiant_id,
  et.nom,
  AVG(ex.score) AS moyenne_score   
FROM etudiant et
LEFT JOIN examen ex
  ON ex.etudiant_id = et.id
GROUP BY et.id, et.nom;


-- 6) CTE : top_cours

WITH top_cours AS (
  SELECT
    c.id AS cours_id,
    AVG(ex.score) AS moyenne_score
  FROM cours c
  JOIN enseignement en
    ON en.cours_id = c.id
  JOIN inscription i
    ON i.enseignement_id = en.id
  JOIN examen ex
    ON ex.etudiant_id = i.etudiant_id
   AND ex.enseignement_id = i.enseignement_id
   AND ex.date_inscription = i.date_inscription
  GROUP BY c.id
  ORDER BY moyenne_score DESC
  LIMIT 3
)
SELECT
  c.titre,
  c.credits,
  t.moyenne_score
FROM top_cours t
JOIN cours c
  ON c.id = t.cours_id
ORDER BY t.moyenne_score DESC;

-- INNER JOIN :
-- Combine EXAMEN, INSCRIPTION, ENSEIGNEMENT, COURS et ETUDIANT
-- pour afficher uniquement les examens ayant toutes les relations existantes.
-- LEFT JOIN :
-- Affiche tous les étudiants même s’ils n’ont passé aucun examen,
-- avec un compteur d’examens égal à 0 le cas échéant.
-- RIGHT JOIN :
-- Garantit l’affichage de tous les cours,
-- même ceux sans inscriptions, avec un nombre d’étudiants à 0.
-- CROSS JOIN :
-- Génère le produit cartésien Étudiant × Professeur.
-- Cette opération est coûteuse car le nombre de lignes = N × M.
-- VUE vue_performances :
-- Calcule la moyenne des scores par étudiant.
-- Les étudiants sans examen apparaissent avec une moyenne NULL (ou 0).
-- CTE top_cours :
-- Identifie les 3 cours ayant la meilleure moyenne de score,
-- puis joint avec COURS pour afficher les informations détaillées.
