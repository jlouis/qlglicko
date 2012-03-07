-module(qlg).

-export([rank/0, rank/1, rank/2]).

rank() ->
    {ok, Ts} = qlg_pgsql_srv:all_tournaments(),
    [rank(T, [write_csv, save_tournament]) || T <- Ts].

rank(Id) ->
    rank(Id, []).

rank(Id, Opts) ->
    qlg_ranker:rank(Id, Opts).

