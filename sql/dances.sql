DROP TABLE IF EXISTS dances;
CREATE TABLE dances (
   name VARCHAR(128) NOT NULL,
   ordinal INT NOT NULL,
   step VARCHAR(128) NOT NULL,
   INDEX(name),
   UNIQUE(name, ordinal)
)DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO dances VALUES
 ('trungle', 0, '¯\_(ツ)_/¯'),
 ('trungle', 1, '---(ツ)_/¯'),
 ('trungle', 2, '_/¯(ツ)_/¯'),
 ('trungle', 3, '_/¯(ツ)---'),
 ('trungle', 4, '_/¯(ツ)¯\_'),
 ('trungle', 5, '_/¯(ツ)---'),
 ('trungle', 6, '_/¯(ツ)_/¯'),
 ('trungle', 7, '---(ツ)_/¯'),
 ('trungle', 8, '¯\_(ツ)_/¯');
