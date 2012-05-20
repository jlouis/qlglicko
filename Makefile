.PHONY: all graph compile get-deps clean test_console console graph \
	relclean rel postgres_start postgres_stop distclean plt analyze \
	publish

all: compile

get-deps:
	rebar get-deps

publish:
	cp rankings_dhs_2012.pdf rankings.pdf ladder.pdf volatility.pdf ~/Dropbox/Public

distclean: clean releaseclean

clean:
	rebar clean

compile:
	rebar compile

test_console:
	erl -pa apps/*/ebin deps/*/ebin

console:
	rel/qlglicko/bin/qlglicko console \
		-pa ../../apps/*/ebin \
		-pa ../../deps/*/ebin

graph:
	R CMD BATCH plot.R

graph2:
	R CMD BATCH plot2.R

dhs:
	echo 'Player,R,RD,Sigma' > rel/qlglicko/dhs2012.csv
	grep -if dhs2012.match rel/qlglicko/rankings.csv >> rel/qlglicko/dhs2012.csv
	echo 'a1r_ra1d,1500,397,0.07' >> rel/qlglicko/dhs2012.csv
	R CMD BATCH dhs.R

relclean:
	rm -fr rel/qlglicko

rel:
	rebar generate

postgres_start:
	  pg_ctl -D /usr/local/var/postgres \
		-l /usr/local/var/postgres/server.log start

postgres_stop:
	  pg_ctl -D /usr/local/var/postgres stop -s -m fast

postgres_restore:
	dropdb qlglicko
	createdb qlglicko
	pg_restore -C -d postgres ~/Dropbox/qlglicko.dump

DIALYZER=dialyzer

plt:
	$(DIALYZER) --build_plt --output_plt .qlglicko.plt \
		-pa deps/*/ebin \
		deps/*/ebin \
		--apps kernel stdlib sasl inets crypto \
		public_key ssl runtime_tools erts \
		compiler tools syntax_tools hipe webtool

analyze: compile
	$(DIALYZER) --no_check_plt \
		     apps/*/ebin \
		--plt .qlglicko.plt
