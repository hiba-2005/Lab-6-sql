-- A) Création du schéma (DDL complet)
CREATE DATABASE IF NOT EXISTS universite
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE universite;


CREATE TABLE IF NOT EXISTS etudiant (
  id    INT AUTO_INCREMENT PRIMARY KEY,
  nom   VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS professeur (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nom         VARCHAR(100) NOT NULL,
  email       VARCHAR(150) NOT NULL UNIQUE,
  departement VARCHAR(100) NOT NULL
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS cours (
  id      INT AUTO_INCREMENT PRIMARY KEY,
  titre   VARCHAR(200) NOT NULL,
  code    VARCHAR(50)  NOT NULL UNIQUE,
  credits INT NOT NULL
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS enseignement (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  cours_id      INT NOT NULL,
  professeur_id INT NULL,
  semestre      VARCHAR(20) NOT NULL,

  CONSTRAINT fk_ens_cours
    FOREIGN KEY (cours_id) REFERENCES cours(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_ens_prof
    FOREIGN KEY (professeur_id) REFERENCES professeur(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

 
  UNIQUE (cours_id, professeur_id, semestre)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS inscription (
  etudiant_id      INT NOT NULL,
  enseignement_id  INT NOT NULL,
  date_inscription DATE NOT NULL DEFAULT (CURRENT_DATE),

  PRIMARY KEY (etudiant_id, enseignement_id, date_inscription),

  CONSTRAINT fk_ins_etudiant
    FOREIGN KEY (etudiant_id) REFERENCES etudiant(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_ins_enseignement
    FOREIGN KEY (enseignement_id) REFERENCES enseignement(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS examen (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  etudiant_id    INT NOT NULL,
  enseignement_id INT NOT NULL,
  date_inscription DATE NOT NULL,
  date_examen    DATE NOT NULL,
  score          DECIMAL(4,2) NOT NULL,

  CONSTRAINT fk_exam_inscription
    FOREIGN KEY (etudiant_id, enseignement_id, date_inscription)
    REFERENCES inscription(etudiant_id, enseignement_id, date_inscription)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT ck_score
    CHECK (score BETWEEN 0 AND 20)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

--  Contraintes d’intégrité
ALTER TABLE inscription
ADD CONSTRAINT uq_ins_unique
UNIQUE (etudiant_id, enseignement_id);  

-- Expliquer pourquoi on utilise UNIQUE(code) dans COURS et UNIQUE(email) dans ETUDIANT et PROFESSEUR.
-- code identifie un cours de manière unique (ex: CS101)
-- email évite les doublons d’identités et sert souvent de login

--  Insertion et tests


INSERT INTO professeur (nom, email, departement) VALUES
('Prof A', 'prof.a@uni.ma', 'Informatique'),
('Prof B', 'prof.b@uni.ma', 'Math');


INSERT INTO cours (titre, code, credits) VALUES
('Intro SQL', 'CS101', 3),
('Algo', 'CS102', 4),
('Math Discrètes', 'MA201', 3);


INSERT INTO etudiant (nom, email) VALUES
('Alice', 'alice@mail.com'),
('Youssef', 'youssef@mail.com');


INSERT INTO enseignement (cours_id, professeur_id, semestre) VALUES
((SELECT id FROM cours WHERE code='CS101'), (SELECT id FROM professeur WHERE email='prof.a@uni.ma'), 'S1'),
((SELECT id FROM cours WHERE code='CS102'), (SELECT id FROM professeur WHERE email='prof.a@uni.ma'), 'S1');


INSERT INTO inscription (etudiant_id, enseignement_id, date_inscription) VALUES
((SELECT id FROM etudiant WHERE nom='Alice'),   1, '2025-01-10'),
((SELECT id FROM etudiant WHERE nom='Alice'),   2, '2025-01-12'),
((SELECT id FROM etudiant WHERE nom='Youssef'), 1, '2025-01-11'),
((SELECT id FROM etudiant WHERE nom='Youssef'), 2, '2025-01-13');


INSERT INTO examen (etudiant_id, enseignement_id, date_inscription, date_examen, score)
VALUES ((SELECT id FROM etudiant WHERE nom='Alice'), 1, '2025-01-10', CURDATE(), 25);


INSERT INTO examen (etudiant_id, enseignement_id, date_inscription, date_examen, score)
SELECT etudiant_id, enseignement_id, date_inscription, CURDATE(), 15
FROM inscription;

-- D. Sélection et filtrage

SELECT DISTINCT e.id, e.nom, e.email
FROM etudiant e
JOIN inscription i ON i.etudiant_id = e.id
JOIN enseignement en ON en.id = i.enseignement_id
JOIN cours c ON c.id = en.cours_id
WHERE c.code = 'CS101';

SELECT nom, email
FROM professeur
WHERE departement = 'Informatique';

SELECT i.*
FROM inscription i
JOIN etudiant e ON e.id = i.etudiant_id
WHERE e.nom = 'Alice'
ORDER BY i.date_inscription DESC;

-- E. Jointures et sous-requêtes

SELECT
  e.nom AS etudiant,
  c.titre AS cours,
  en.semestre,
  i.date_inscription
FROM inscription i
JOIN etudiant e ON e.id = i.etudiant_id
JOIN enseignement en ON en.id = i.enseignement_id
JOIN cours c ON c.id = en.cours_id;

SELECT e.id, e.nom,
  (SELECT COUNT(DISTINCT i.enseignement_id)
   FROM inscription i
   WHERE i.etudiant_id = e.id
  ) AS total_cours
FROM etudiant e;


CREATE OR REPLACE VIEW vue_etudiant_charges AS
SELECT
  e.id,
  e.nom,
  COUNT(i.enseignement_id) AS nb_inscriptions,
  COALESCE(SUM(c.credits), 0) AS total_credits
FROM etudiant e
LEFT JOIN inscription i ON i.etudiant_id = e.id
LEFT JOIN enseignement en ON en.id = i.enseignement_id
LEFT JOIN cours c ON c.id = en.cours_id
GROUP BY e.id, e.nom;

-- F. Agrégation et rapports

SELECT c.code, c.titre, COUNT(i.etudiant_id) AS nb_inscriptions
FROM cours c
LEFT JOIN enseignement en ON en.cours_id = c.id
LEFT JOIN inscription i ON i.enseignement_id = en.id
GROUP BY c.id, c.code, c.titre;

SELECT c.code, c.titre, COUNT(i.etudiant_id) AS nb_inscriptions
FROM cours c
JOIN enseignement en ON en.cours_id = c.id
JOIN inscription i ON i.enseignement_id = en.id
GROUP BY c.id, c.code, c.titre
HAVING COUNT(i.etudiant_id) > 10;

SELECT en.semestre, ROUND(AVG(ex.score), 2) AS moyenne_score
FROM examen ex
JOIN enseignement en ON en.id = ex.enseignement_id
GROUP BY en.semestre;

-- G. Maintenance du schéma

ALTER TABLE examen
ADD COLUMN commentaire TEXT;