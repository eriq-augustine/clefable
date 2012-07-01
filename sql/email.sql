DROP TABLE IF EXISTS pending_emails;
CREATE TABLE pending_emails (
   `user` VARCHAR(128) PRIMARY KEY REFERENCES users(`user`),
   email TEXT NOT NULL,
   token VARCHAR(40) NOT NULL
);
