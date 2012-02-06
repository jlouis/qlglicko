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

CREATE VIEW player_ratings AS
  SELECT player.name, r, rd, sigma
  FROM tournament_result
         INNER JOIN
       last_tournament ON (last_tournament.id = tournament_result.id)
         INNER JOIN
       player ON (player.id = player_id);

CREATE TABLE raw_match (
  id       UUID PRIMARY KEY NOT NULL,
  added   TIMESTAMP NOT NULL DEFAULT(now()),
  content  BYTEA
);

-- Partial index over raw matches
CREATE INDEX raw_match_missing ON raw_match (content, added)
  WHERE content IS NULL;

-- Query using that partial index
CREATE VIEW matches_to_refresh AS
  SELECT id
  FROM raw_match
  WHERE content IS NULL
  ORDER BY added ASC;
  
CREATE TABLE duel_match (
  id       UUID PRIMARY KEY NOT NULL,
  played   TIMESTAMP NOT NULL,
  winner   UUID NOT NULL REFERENCES player (id),
  winner_score INTEGER NOT NULL,
  loser    UUID NOT NULL REFERENCES player (id),
  loser_score INTEGER NOT NULL
);

CREATE INDEX duel_match_played ON duel_match (played);

-- TODO: Given a tournament ID, Player, find the duels won
--  for that player and pull out the ratings of all the losers
-- Select from and to out of the tournament.
-- Use this to constrain the duel_matches to that tournament
-- Now, JOIN duels_won over it.
-- Now, JOIN the losing players by the tournament that came before.

COMMIT;
 
