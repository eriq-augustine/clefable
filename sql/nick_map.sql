DROP TABLE IF EXISTS nick_map;
CREATE TABLE nick_map(
   nick VARCHAR(64) NOT NULL,
   email VARCHAR(64) NOT NULL,
   domain VARCHAR(64) NOT NULL,
   INDEX(nick, email),
   UNIQUE(nick)
);

INSERT INTO nick_map (nick, email, domain) VALUES ('eriq', 'eaugusti', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('eriq_home', 'eaugusti', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('dcronin', 'rdevlin.cronin', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('chebert', 'hebert.christopherj', 'chromium.org');

INSERT INTO nick_map (nick, email, domain) VALUES ('aboodman', 'aa', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('acleung', 'acleung', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('aklein', 'adamk', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('awong', 'ajwong', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('awalker', 'amanda', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('joshia', 'amit', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('iyengar', 'ananta', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('anantha', 'anantha', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('motownavi', 'avi', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('beng', 'ben', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('bxs', 'bxx', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('ccameron', 'ccameron', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('csharp1', 'csharp', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('fishd', 'fishd', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('danbeam', 'dbeam', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('dmurph', 'dmurph', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('eglaysher', 'erg', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('eroman', 'eroman', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('evmar', 'evan', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('gabc', 'gab', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('hwennborg', 'hans', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('ifette', 'ian', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('inferno', 'inferno', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('iannucci', 'iannucci', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('jankeromnes', 'janx', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('jam2', 'jam', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('jeremymos', 'jeremy', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('jochen`__`', 'jochen', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('johnny_g', 'johnnyg', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('joisig', 'joi', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('jshin', 'jshin', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('kareng', 'karen', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('kuchhal', 'kuchhal', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('dave_levin', 'levin', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('markmentovai', 'mark', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('mattm_g', 'mattm', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('dullb0yj4ck', 'mlinck', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('msw`_`', 'msw', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('nickcarter', 'nick', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('pamg', 'pam', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('pjohnson', 'patrick', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('beverloo', 'peter', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('phajdan-jr', 'phajdan.jr', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('RyanHamilton', 'rch', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('rpetterson', 'rlp', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('rsleevi', 'rsleevi', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('sleevi', 'rsleevi', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('satish`_`', 'satish', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('sbyer', 'scottbyer', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('sheridan', 'scr', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('leiz', 'thestig', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('timsteele', 'tim', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('tony^work', 'tony', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('tonyg-cr', 'tonyg', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('tyoshino', 'tyoshino', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('trungl', 'viettrungluu', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('redpig', 'wad', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('real_wez', 'wez', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('seumas', 'wjmaclean', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('wjmaclean', 'wjmaclean', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('wjm', 'wjmaclean', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('yaws', 'yoz', 'chromium.org');
INSERT INTO nick_map (nick, email, domain) VALUES ('zhenyao', 'zmo', 'chromium.org');
