DROP TABLE IF EXISTS glossary;
CREATE TABLE glossary (
   word VARCHAR(128) PRIMARY KEY,
   description TEXT,
   `user` VARCHAR(128) REFERENCES admin
);
