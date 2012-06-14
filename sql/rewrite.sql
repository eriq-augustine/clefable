DROP TABLE IF EXISTS rewrite_rules;
CREATE TABLE rewrite_rules (
   target VARCHAR(128) PRIMARY KEY,
   rewrite VARCHAR(128) NOT NULL
);
