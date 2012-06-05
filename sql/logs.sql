DROP TABLE IF EXISTS logs;
CREATE TABLE logs (
   timestamp BIGINT NOT NULL,
   `to` VARCHAR(128) NOT NULL,
   `from` VARCHAR(128) NOT NULL,
   message TEXT NOT NULL,
   INDEX(timestamp),
   INDEX(`from`),
   INDEX(`to`)
)DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
