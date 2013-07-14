-- Plan for what we need to store:

BEGIN;

CREATE OR REPLACE FUNCTION processing.declare_match(match_id uuid) RETURNS integer AS $$
DECLARE
  knows uuid := NULL;
BEGIN
  SELECT INTO knows id FROM raw_match WHERE id = match_id;
  IF NOT FOUND THEN
    INSERT INTO raw_match (id, content) VALUES (match_id, NULL);
    RETURN 1;
  ELSE
    RETURN 0;
  END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION processing.store_match(match_id uuid, match_data bytea) RETURNS integer AS $$
DECLARE
  knows integer := NULL;
BEGIN
  SELECT INTO knows id FROM raw_match WHERE id = match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_id % not found', match_id;
  END IF;

  IF knows IS NULL THEN
    INSERT INTO raw_match (id, content) VALUES (match_id, match_data);
    RETURN 1;
  ELSE
    RETURN 0;
  END IF;
END
$$ LANGUAGE plpgsql;

COMMIT;

BEGIN;

ALTER TABLE raw_match SET SCHEMA core;
GRANT SELECT ON core.raw_match TO qlglicko_processing;



COMMIT;

\c qlglicko;

BEGIN;

-- User credentials
CREATE USER qlglicko_web WITH PASSWORD 'Diwikeefum';
CREATE USER qlglicko_processing WITH PASSWORD '0okTivlur7';

-- Schemas for physical data containers
CREATE SCHEMA core;
CREATE SCHEMA player;
CREATE SCHEMA duel;

-- Schemas for data access
CREATE SCHEMA web;
  GRANT SELECT ON ALL TABLES IN SCHEMA web TO qlglicko_web;
CREATE SCHEMA processing;
  GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA processing TO qlglicko_processing;
  GRANT USAGE ON ALL SEQUENCES IN SCHEMA processing TO qlglicko_processing;
  GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA processing TO qlglicko_processing;

COMMIT;



DROP DATABASE qlglicko;
CREATE DATABASE qlglicko;

\c qlglicko;

BEGIN;

CREATE EXTENSION "uuid-ossp";
CREATE EXTENSION "pg_trgm";

CREATE TABLE player_rankings (
  tournament INT NOT NULL,
  player VARCHAR(32) NOT NULL,
  map    VARCHAR(32) NOT NULL,
  rank    FLOAT NOT NULL,
  rd        FLOAT NOT NULL,
  sigma FLOAT NOT NULL
);

CREATE INDEX player_ranking_trgm ON player_rankings USING gin (player gin_trgm_ops);

CREATE TABLE tournament (
  id       UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  t_from     TIMESTAMP NOT NULL,
  t_to       TIMESTAMP NOT NULL,
  switch     TIMESTAMP DEFAULT NULL,
  done     BOOLEAN NOT NULL DEFAULT false
);

INSERT INTO tournament (t_from, t_to) VALUES ('2012-02-02', '2012-02-07');


CREATE TABLE player (
  id       UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  name     VARCHAR(32) UNIQUE NOT NULL,
  lastupdate TIMESTAMP NOT NULL,
  last_alive_check TIMESTAMP NOT NULL
);

CREATE INDEX player_name ON player (name);
CREATE INDEX player_lastupdate ON player (lastupdate);
CREATE INDEX player_trgm ON player USING gin (name gin_trgm_ops);

INSERT INTO player (name, lastupdate) VALUES ('strenx', now() - '5 days' :: interval);

CREATE TABLE hall_of_fame (
  id	UUID NOT NULL PRIMARY KEY,
  name	VARCHAR(32) NOT NULL,
  entry	TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX hall_of_fame_name ON hall_of_fame (name);

CREATE OR REPLACE VIEW players_to_update AS
  SELECT id, name, date_part('day', now() - lastupdate) as age_days
  FROM player
  -- Fetch old matches, but not young matches.
  -- We'd rather make a single efficient fetch
  WHERE lastupdate < (now() - '5 days' :: interval);

CREATE TABLE tournament_result (
  id UUID NOT NULL REFERENCES tournament (id),
  player_id UUID NOT NULL REFERENCES player (id),
  r          FLOAT NOT NULL,
  rd         FLOAT NOT NULL,
  sigma      FLOAT NOT NULL
);

CREATE INDEX tournament_result_player_id ON tournament_result (player_id);
CREATE INDEX tournament_result_id   ON tournament_result (id);

CREATE OR REPLACE VIEW player_ratings AS
  SELECT player_id, r, rd, sigma
  FROM tournament_result
         INNER JOIN
       last_tournament ON (last_tournament.id = tournament_result.id);

CREATE TABLE raw_match (
  id       UUID PRIMARY KEY NOT NULL,
  added    TIMESTAMP NOT NULL DEFAULT(now()),
  content  BYTEA
);

ALTER TABLE raw_match ADD COLUMN analyzed boolean NOT NULL default(false);


SELECT count(*) FROM duel_match;

-- Partial index over raw matches
CREATE INDEX raw_match_missing ON raw_match (added, id)
  WHERE content IS NULL;

-- Query using that partial index
CREATE VIEW matches_to_refresh AS
  SELECT id
  FROM raw_match
  WHERE content IS NULL
  ORDER BY added ASC;

CREATE INDEX raw_match_to_analyze ON raw_match (analyzed)
  WHERE analyzed = false AND content IS NOT NULL;

CREATE OR REPLACE VIEW matches_to_analyze AS
  SELECT id
  FROM raw_match
  WHERE analyzed = false AND content IS NOT NULL;

CREATE TABLE duel_match (
  id       UUID PRIMARY KEY NOT NULL,
  played   TIMESTAMP NOT NULL,
  map	VARCHAR(20) NOT NULL,
  winner   UUID NOT NULL REFERENCES player (id),
  winner_score INTEGER NOT NULL,
  loser    UUID NOT NULL REFERENCES player (id),
  loser_score INTEGER NOT NULL
);

CREATE INDEX duel_match_played ON duel_match (played);

CREATE INDEX duel_match_winner ON duel_match (winner);
CREATE INDEX duel_match_loser  ON duel_match (loser);

CREATE OR REPLACE VIEW duel_match_ratings AS
  SELECT played,
         winner, COALESCE(w.r, 1500.0) as wr,
                 COALESCE(w.rd, 350.0) as wrd,
                 COALESCE(w.sigma, 0.06) as wsigma,
         loser,  COALESCE(l.r, 1500.0) as lr,
                 COALESCE(l.rd, 350.0) as lrd,
                 COALESCE(l.sigma, 0.06) as lsigma
  FROM duel_match
         LEFT OUTER JOIN player_ratings w ON (w.player_id = winner)
         LEFT OUTER JOIN player_ratings l ON (l.player_id = loser);

CREATE VIEW oldest_match_not_done AS
  SELECT added as tstamp
  FROM raw_match
  WHERE content IS NULL
  ORDER BY added ASC
  LIMIT 1;

CREATE OR REPLACE VIEW duel.matches_played AS
  SELECT id, COUNT(id) as count
  FROM (  SELECT winner as id FROM duel_match
        UNION ALL
          SELECT loser  as id FROM duel_match) ss
  GROUP BY ss.id;


CREATE OR REPLACE VIEW web.avg_matches_played AS
  SELECT avg(count)
  FROM matches_played;

CREATE OR REPLACE VIEW match_played AS
 (SELECT played, winner as id FROM duel_match)
    UNION ALL
 (SELECT played, loser  as id FROM duel_match);

CREATE OR REPLACE VIEW tournament_matches AS
  SELECT t.id as tournament, dm.*
  FROM tournament t, duel_match dm
  WHERE dm.played BETWEEN t.t_from AND t.t_to;
  
CREATE OR REPLACE VIEW player_match_streak AS
      SELECT player.name, duel_match.map, 1 as res, duel_match.played
      FROM player INNER JOIN duel_match ON (player.id = duel_match.winner)
  UNION
      SELECT player.name, duel_match.map, -1 as res, duel_match.played
      FROM player INNER JOIN duel_match ON (player.id = duel_match.loser);
 
COMMIT;
 
