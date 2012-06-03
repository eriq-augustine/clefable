CREATE TABLE logs (
   timestamp BIGINT NOT NULL,
   user VARCHAR(128) NOT NULL,
   message TEXT NOT NULL,
   INDEX(timestamp),
   INDEX(user)
)DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
