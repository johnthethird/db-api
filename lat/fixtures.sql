BEGIN;
INSERT INTO concepts (title, concept) VALUES ('roses', 'roses are red');
INSERT INTO concepts (title, concept) VALUES ('violets', 'violets are blue');
INSERT INTO concepts (title, concept) VALUES ('sugar', 'sugar is sweet');
INSERT INTO urls (url) VALUES ('http://www.rosesarered.co.nz/');
INSERT INTO urls (url) VALUES ('http://en.wikipedia.org/wiki/Roses_are_red');
INSERT INTO urls (url, notes) VALUES ('http://en.wikipedia.org/wiki/Violets_Are_Blue', 'many refs here');
INSERT INTO concepts_urls (concept_id, url_id) VALUES (1, 1);
INSERT INTO concepts_urls (concept_id, url_id) VALUES (1, 2);
INSERT INTO concepts_urls (concept_id, url_id) VALUES (2, 3);
INSERT INTO tags (tag) VALUES ('flower');
INSERT INTO tags (tag) VALUES ('color');
INSERT INTO tags (tag) VALUES ('flavor');
INSERT INTO concepts_tags (concept_id, tag_id) VALUES (1, 1);
INSERT INTO concepts_tags (concept_id, tag_id) VALUES (2, 1);
INSERT INTO concepts_tags (concept_id, tag_id) VALUES (1, 2);
INSERT INTO concepts_tags (concept_id, tag_id) VALUES (2, 2);
INSERT INTO concepts_tags (concept_id, tag_id) VALUES (3, 3);
INSERT INTO pairings (concept1_id, concept2_id, thoughts) VALUES (1, 2, 'describing flowers');
COMMIT;

