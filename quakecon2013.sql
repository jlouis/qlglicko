BEGIN;

CREATE TABLE core.tourney_players (
       tourney   varchar(16), 
       name      varchar(16),
       PRIMARY KEY(tourney, name)
);

INSERT INTO core.tourney_players (tourney, name)
VALUES
  ('quakecon2013', 'rapha'),
  ('quakecon2013', 'evil');

INSERT INTO core.tourney_players (tourney, name)
VALUES
  ('quakecon2013', 'carnage'),
  ('quakecon2013', 'cha0ticz'),
  ('quakecon2013', 'chance'),
  ('quakecon2013', 'cl0ck'),
  ('quakecon2013', 'DaHanG'),
  ('quakecon2013', 'dkt'),
  ('quakecon2013', 'FienD'),
  ('quakecon2013', 'h41'),
  ('quakecon2013', 'id_'),
  ('quakecon2013', 'jok0'),
  ('quakecon2013', 'klaovhwn'),
  ('quakecon2013', 'NemesiS'),
  ('quakecon2013', 'Nightmare'),
  ('quakecon2013', 'pthy'),
  ('quakecon2013', 'Samer'),
  ('quakecon2013', 'STAcY_'),
  ('quakecon2013', 'stermy'),
  ('quakecon2013', 'Vo0'),
  ('quakecon2013', 'whaz'),
  ('quakecon2013', 'ZeRo4');
  
CREATE TABLE core.tourney_maps (
       tourney   varchar(16),
       name      varchar(16),
       PRIMARY KEY(tourney, name)
);

INSERT INTO core.tourney_maps (tourney, name)
VALUES
  ('quakecon2013', 'bloodrun'),
  ('quakecon2013', 'toxicity'),
  ('quakecon2013', 'cure'),
  ('quakecon2013', 'furiousheights'),
  ('quakecon2013', 'lostworld');

CREATE OR REPLACE VIEW web.tourney AS
  SELECT tp.tourney, tp.name as player, m.name as map
  FROM core.tourney_players tp INNER JOIN core.tourney_maps m ON (tp.tourney = m.tourney);

CREATE OR REPLACE VIEW web.tourney_ranking AS
  SELECT r.tournament as tournament, wt.tourney, wt.player AS Player, wt.map AS Map,
         r.rank AS rank, r.rd AS rd, r.sigma AS sigma
  FROM web.tourney wt INNER JOIN core.player_rankings r
         ON (lower(wt.player) = lower(r.player) AND wt.map = r.map);

COMMIT;                               

\copy (SELECT * from web.tourney_ranking WHERE tournament = 75 AND tourney = 'quakecon2013') TO 'quakecon2013.csv' WITH CSV HEADER

