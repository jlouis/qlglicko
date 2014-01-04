BEGIN;

TRUNCATE core.player_rankings;

COPY core.player_rankings
  FROM '/home/jlouis/P/qlglicko/rel/prod/rankings.csv'
  WITH CSV HEADER;

COMMIT;
