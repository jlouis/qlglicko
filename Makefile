PROJECT = qlglicko
.DEFAULT_GOAL = deps

.PHONY: release clean-release push

push:
	rsync -ar rel/qlglicko myrddraal:P/qlglicko/rel

release: clean-release deps
	relx -o rel/$(PROJECT)

clean-release:
	rm -rf rel/$(PROJECT)

DEPS = qlglicko_core qlglicko_web
dep_qlglicko_core = git@github.com:jlouis/qlglicko_core.git master
dep_qlglicko_web  = git@github.com:jlouis/qlglicko_web.git master

include erlang.mk

##### ----------------------------------------------------------------------

publish:
	cp rankings_*.pdf ladder_*.pdf.pdf ~/Dropbox/Public

matchup:
	echo "Player,Map,R,RD,Sigma" > players.csv
	grep -f select_players.match rel/qlglicko/rankings.csv | grep -f select_maps.match >> players.csv
	R CMD BATCH plot-1v1.R
	cp matchup.pdf ~/Dropbox/Public/matchup.pdf

gd-studio:
	echo "Player,Map,R,RD,Sigma" > players.csv
	grep -f select_players-gdstudio.match rel/qlglicko/rankings.csv | grep -f select_maps.match >> players.csv
	R CMD BATCH plot-1v1.R
	cp matchup.pdf ~/Dropbox/Public/gd-studio.pdf

graph: graph_hektik graph_aerowalk graph_bloodrun graph_silence graph_furiousheights \
	graph_lostworld graph_toxicity

graph_hektik:
	# hektik
	echo "Player,Map,R,RD,Sigma" > rel/qlglicko/hektik.csv
	grep hektik rel/qlglicko/rankings.csv >> rel/qlglicko/hektik.csv
	R CMD BATCH --no-save --no-restore \
		'--args title="Hektik" output_rankings="rankings_hektik.pdf" output_ladder="ladder_hektik.pdf" limit=1200 rd_limit=120 f="rel/qlglicko/hektik.csv"'  plot2.R

graph_aerowalk:
	# aerowalk
	echo "Player,Map,R,RD,Sigma" > rel/qlglicko/aerowalk.csv
	grep aerowalk rel/qlglicko/rankings.csv >> rel/qlglicko/aerowalk.csv
	R CMD BATCH --no-save --no-restore \
		'--args title="Aerowalk" output_rankings="rankings_aerowalk.pdf" output_ladder="ladder_aerowalk.pdf" limit=1700 rd_limit=120 f="rel/qlglicko/aerowalk.csv"'  plot2.R

graph_bloodrun:
	# bloodrun
	echo "Player,Map,R,RD,Sigma" > rel/qlglicko/bloodrun.csv
	grep bloodrun rel/qlglicko/rankings.csv >> rel/qlglicko/bloodrun.csv
	R CMD BATCH --no-save --no-restore \
		'--args title="BloodRun" output_rankings="rankings_bloodrun.pdf" output_ladder="ladder_bloodrun.pdf" limit=1900 rd_limit=90 f="rel/qlglicko/bloodrun.csv"'  plot2.R

graph_silence:
	# silence
	echo "Player,Map,R,RD,Sigma" > rel/qlglicko/silence.csv
	grep silence rel/qlglicko/rankings.csv >> rel/qlglicko/silence.csv
	R CMD BATCH --no-save --no-restore \
		'--args title="Silence" output_rankings="rankings_silence.pdf" output_ladder="ladder_silence.pdf" limit=1300 rd_limit=180 f="rel/qlglicko/silence.csv"'  plot2.R

graph_furiousheights:	
	# furiousheights
	echo "Player,Map,R,RD,Sigma" > rel/qlglicko/furiousheights.csv
	grep furiousheights rel/qlglicko/rankings.csv >> rel/qlglicko/furiousheights.csv
	R CMD BATCH --no-save --no-restore \
		'--args title="FuriousHeights" output_rankings="rankings_furiousheights.pdf" output_ladder="ladder_furiousheights.pdf" limit=1650 rd_limit=120 f="rel/qlglicko/furiousheights.csv"'  plot2.R

graph_lostworld:	
	# lostworld
	echo "Player,Map,R,RD,Sigma" > rel/qlglicko/lostworld.csv
	grep lostworld rel/qlglicko/rankings.csv >> rel/qlglicko/lostworld.csv
	R CMD BATCH --no-save --no-restore \
		'--args title="LostWorld" output_rankings="rankings_lostworld.pdf" output_ladder="ladder_lostworld.pdf" limit=1650 rd_limit=120 f="rel/qlglicko/lostworld.csv"'  plot2.R

graph_houseofdecay:	
	# houseofdecay
	echo "Player,Map,R,RD,Sigma" > rel/qlglicko/houseofdecay.csv
	grep houseofdecay rel/qlglicko/rankings.csv >> rel/qlglicko/houseofdecay.csv
	R CMD BATCH --no-save --no-restore \
		'--args title="HouseOfDecay" output_rankings="rankings_houseofdecay.pdf" output_ladder="ladder_houseofdecay.pdf" limit=1350 rd_limit=200 f="rel/qlglicko/houseofdecay.csv"'  plot2.R

graph_toxicity:
	# toxicity
	echo "Player,Map,R,RD,Sigma" > rel/qlglicko/toxicity.csv
	grep toxicity rel/qlglicko/rankings.csv >> rel/qlglicko/toxicity.csv
	R CMD BATCH --no-save --no-restore \
		'--args title="Toxicity" output_rankings="rankings_toxicity.pdf" output_ladder="ladder_toxicity.pdf" limit=1500 rd_limit=120 f="rel/qlglicko/toxicity.csv"'  plot2.R

dhs:
	R CMD BATCH dhs.R

adroits:
	echo "Player,R,RD,Sigma" > adroits.csv
	grep -f adroits.match rel/qlglicko/rankings.csv >> adroits.csv
	wc -l adroits.csv
	R CMD BATCH adroits.R

thearena3:
	R CMD BATCH thearena3.R

postgres_start:
	  pg_ctl -D /usr/local/var/postgres \
		-l /usr/local/var/postgres/server.log start

postgres_stop:
	  pg_ctl -D /usr/local/var/postgres stop -s -m fast

postgres_dump:
	pg_dump -Fc qlglicko > qlglicko.dump

postgres_restore:
	dropdb qlglicko
	pg_restore -e -C -d postgres ./qlglicko.dump

console:
	_rel/qlglicko/bin/qlglicko console \
		-pa ../../deps/*/ebin

