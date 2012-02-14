.PHONY: all graph compile get-deps clean test_console console graph \
	relclean rel postgres_start postgres_stop distclean plt analyze

all: compile

get-deps:
	rebar get-deps

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

relclean:
	rm -fr rel/qlglicko

rel:
	rebar generate

postgres_start:
	  pg_ctl -D /usr/local/var/postgres \
		-l /usr/local/var/postgres/server.log start

postgres_stop:
	  pg_ctl -D /usr/local/var/postgres stop -s -m fast

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
