-- Plan for what we need to store:

--System bucket:
--  Last ranked tournament.

DROP DATABASE qlglicko;
CREATE DATABASE qlglicko;

\c qlglicko;

BEGIN;

CREATE EXTENSION "uuid-ossp";

CREATE TABLE tournament (
  id       UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  t_from     TIMESTAMP NOT NULL,
  t_to       TIMESTAMP NOT NULL,
  switch     TIMESTAMP DEFAULT NULL,
  done     BOOLEAN NOT NULL DEFAULT false
);

INSERT INTO tournament (t_from, t_to) VALUES ('2012-02-02', '2012-02-07');


CREATE VIEW last_tournament AS
  SELECT id FROM tournament
    WHERE done = true
    ORDER BY t_to DESC
    LIMIT 1;
          
CREATE TABLE player (
  id       UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  name     VARCHAR(32) UNIQUE NOT NULL,
  lastupdate TIMESTAMP NOT NULL
);

CREATE INDEX player_name ON player (name);
CREATE INDEX player_lastupdate ON player (lastupdate);

INSERT INTO player (name, lastupdate) VALUES ('strenx', now() - '5 days' :: interval);

CREATE OR REPLACE VIEW oldest_player AS
  SELECT lastupdate as tstamp
  FROM player
  ORDER BY lastupdate ASC
  LIMIT 1;

CREATE OR REPLACE VIEW tournament_all_players_refreshed AS
  SELECT id
  FROM tournament,oldest_player
  WHERE (t_to + '6 days' :: interval) < tstamp AND done = false
  ORDER BY t_to ASC;
         
CREATE OR REPLACE VIEW players_to_update AS
  SELECT id, name
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
  SELECT player.id, player.name, r, rd, sigma
  FROM tournament_result
         INNER JOIN
       last_tournament ON (last_tournament.id = tournament_result.id)
         INNER JOIN
       player ON (player.id = player_id);

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
  winner   UUID NOT NULL REFERENCES player (id),
  winner_score INTEGER NOT NULL,
  loser    UUID NOT NULL REFERENCES player (id),
  loser_score INTEGER NOT NULL
);

CREATE INDEX duel_match_played ON duel_match (played);

CREATE OR REPLACE VIEW duel_match_ratings AS
  SELECT played,
         winner, COALESCE(w.r, 1500.0) as wr,
                 COALESCE(w.rd, 350.0) as wrd,
                 COALESCE(w.sigma, 0.06) as wsigma,
         loser,  COALESCE(l.r, 1500.0) as lr,
                 COALESCE(l.rd, 350.0) as lrd,
                 COALESCE(l.sigma, 0.06) as lsigma
  FROM duel_match
         LEFT OUTER JOIN player_ratings w ON (w.id = winner)
         LEFT OUTER JOIN player_ratings l ON (l.id = loser);

CREATE VIEW oldest_match_not_done AS
  SELECT added as tstamp
  FROM raw_match
  WHERE content IS NULL
  ORDER BY added ASC
  LIMIT 1;

CREATE OR REPLACE VIEW tournament_with_all_matches AS
  SELECT t.id
  FROM tournament t, oldest_match_not_done nd
  WHERE nd.tstamp > t.t_to + '6 days' :: interval;

CREATE VIEW tournaments_to_rank AS
  SELECT t.id
  FROM tournament t
        INNER JOIN tournament_with_all_matches am USING (id)
        INNER JOIN tournament_all_players_refreshed pr USING (id);

CREATE OR REPLACE VIEW matches_played AS
  SELECT id, COUNT(id) as count
  FROM (  SELECT winner as id FROM duel_match
        UNION ALL
          SELECT loser  as id FROM duel_match) ss
  GROUP BY ss.id;


CREATE OR REPLACE VIEW avg_matches_played AS
  SELECT avg(count)
  FROM matches_played;

CREATE OR REPLACE VIEW match_played AS
 (SELECT played, winner as id FROM duel_match)
    UNION ALL
 (SELECT played, loser  as id FROM duel_match);

CREATE OR REPLACE VIEW tournament_players AS
  (SELECT DISTINCT t.id as tournament, mp.id as player
   FROM match_played mp, tournament t
   WHERE mp.played BETWEEN t.t_from AND t.t_to)

CREATE OR REPLACE VIEW tournament_matches AS
  SELECT t.id as tournament, dm.*
  FROM tournament t, duel_match dm
  WHERE dm.played BETWEEN t.t_from AND t.t_to;
  
CREATE OR REPLACE VIEW carry_over_players AS
  (SELECT id FROM player_ratings);
  

COMMIT;
 
