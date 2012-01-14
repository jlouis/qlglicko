-module(glicko_db).

-export([create_db/1,
         del_db/0,
         lookup/1,
         update_rating/1]).

-define(TAB, glicko_player_db).

create_db(Players) ->
    ets:new(?TAB, [named_table, public]),
    update_rating([{P, 1500, 350, 0.06} || P <- Players]).

del_db() ->
    ets:delete(?TAB).

lookup(P) ->
    ets:lookup(?TAB, P).

update_rating(Players) when is_list(Players) ->
    ets:insert(?TAB, Players).

