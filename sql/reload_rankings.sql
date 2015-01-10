BEGIN;

TRUNCATE processing.player_rankings;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/aerowalk'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/battleforged'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/bloodrun'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/campgrounds'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/cure'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/furiousheights'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/hektik'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/houseofdecay'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/lostworld'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/sinister'
  WITH CSV;

COPY processing.player_rankings
  FROM '/home/qlglicko/results/toxicity'
  WITH CSV;

COMMIT;
