.PHONY: all graph

all:
	rebar compile

graph:
	R CMD BATCH plot.R
