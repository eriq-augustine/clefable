DROP TABLE IF EXISTS commits;
CREATE TABLE commits (
   rev INT PRIMARY KEY,
   author VARCHAR(128),
   time INT NOT NULL,
   summary TEXT,
   INDEX(author)
);
