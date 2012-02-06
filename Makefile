.PHONY: all graph compile get-deps clean test_console console graph \
	releaseclean postgres_start postgres_stop distclean plt analyze

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
	rel/qlglicko/bin/qlglicko console

graph:
	R CMD BATCH plot.R

releaseclean:
	rm -fr rel/qlglicko

release:
	rebar generate

postgres_start:
	  pg_ctl -D /usr/local/var/postgres \
		-l /usr/local/var/postgres/server.log start

postgres_stop:
	  pg_ctl -D /usr/local/var/postgres stop -s -m fast

DIALYZER=dialyzer

plt:
	$(DIALYZER) --build_plt --output_plt .backend-api.plt \
		-pa deps/*/ebin \
		deps/*/ebin \
		--apps kernel stdlib sasl inets crypto \
		public_key ssl runtime_tools erts \
		compiler tools syntax_tools hipe webtool

analyze: compile
	$(DIALYZER) --no_check_plt \
		     apps/*/ebin \
		--plt .backend-api.plt \
		-Werror_handling \
		-Wunmatched_returns #-Wunderspecs

