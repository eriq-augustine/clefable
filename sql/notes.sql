DROP TABLE IF EXISTS notes;
CREATE TABLE notes (
   id INT PRIMARY KEY AUTO_INCREMENT,
   note TEXT NOT NULL
);

DROP TABLE IF EXISTS note_tags;
CREATE TABLE note_tags (
   note_id INT REFERENCES notes,
   tag VARCHAR(128) NOT NULL,
   UNIQUE(note_id, tag),
   INDEX(tag)
);
