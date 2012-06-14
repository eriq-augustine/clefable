DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
   to_user VARCHAR(128) NOT NULL,
   message TEXT NOT NULL,
   INDEX(to_user)
);
