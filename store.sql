-- Plan for what we need to store:

--System bucket:
--  Last ranked tournament.

BEGIN;

CREATE TABLE tournament (
  id       UUID NOT NULL PRIMARY KEY,
  t_from     TIMESTAMP NOT NULL,
  t_to       TIMESTAMP NOT NULL,
  done     BOOLEAN NOT NULL DEFAULT false
);

CREATE VIEW last_tournament AS
  SELECT id FROM tournament
    WHERE done = true
    ORDER BY t_to DESC
    LIMIT 1;
          
CREATE TABLE player (
  name     VARCHAR(32) UNIQUE NOT NULL PRIMARY KEY,
  lastupdate TIMESTAMP NOT NULL
);

CREATE INDEX player_lastupdate ON player (lastupdate);

CREATE VIEW players_to_update AS
  SELECT name
  FROM player
  WHERE lastupdate + interval '5 days' < now()
  ORDER BY lastupdate ASC;

CREATE TABLE tournament_result (
  id UUID NOT NULL REFERENCES tournament (id),
  name       VARCHAR(32) NOT NULL REFERENCES player (name),
  r          FLOAT NOT NULL,
  rd         FLOAT NOT NULL,
  sigma      FLOAT NOT NULL
);

CREATE INDEX tournament_result_name ON tournament_result (name);
CREATE INDEX tournament_result_id   ON tournament_result (id);

CREATE VIEW player_ratings AS
  SELECT name, r, rd, sigma
  FROM tournament_result
         INNER JOIN
       last_tournament ON (last_tournament.id = tournament_result.id);

CREATE TABLE raw_match (
  id       UUID PRIMARY KEY NOT NULL,
  tstamp   TIMESTAMP NOT NULL DEFAULT(now()),
  content  TEXT
);

-- Partial index over raw matches
CREATE INDEX raw_match_missing ON raw_match (content)
  WHERE content IS NULL
  ORDER BY tstamp ASC;

-- Query using that partial index
CREATE VIEW matches_to_fetch AS
  SELECT id
  FROM raw_match
  WHERE content IS NULL;
  
CREATE TABLE duel_match (
  id       UUID PRIMARY KEY NOT NULL,
  played   TIMESTAMP NOT NULL,
  winner   VARCHAR(32) NOT NULL REFERENCES player (name),
  winner_score INTEGER NOT NULL,
  loser    VARCHAR(32) NOT NULL REFERENCES player (name),
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
 
