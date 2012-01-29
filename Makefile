.PHONY: all graph compile get-deps

all: compile

get-deps:
	rebar get-deps

compile:
	rebar compile

console:
	erl -pa apps/*/ebin deps/*/ebin

graph:
	R CMD BATCH plot.R

release:
	rebar generate

postgres_start:
	  pg_ctl -D /usr/local/var/postgres \
		-l /usr/local/var/postgres/server.log start

postgres_stop:
	  pg_ctl -D /usr/local/var/postgres stop -s -m fast

