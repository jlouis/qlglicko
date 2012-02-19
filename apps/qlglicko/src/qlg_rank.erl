-module(qlg_rank).

-export([rank/2, rank_chunk/3]).

-define(CHUNK_SIZE, 1000).

rank(T, I) ->
    rank(T, I, []).

rank(Tournament, Info, Options) ->
    ets:new(qlg_rank, [named_table, public]),
    Players = fetch_players(Tournament),
    _ = rank_parallel([P || {P} <- Players], [], Tournament, Info),
    case proplists:get_value(write_csv, Options) of
        undefined ->
            ok;
        true ->
            ok = write_csv()
    end,
    case proplists:get_value(save_tournament, Options) of
        undefined ->
            ok;
        true ->
            store_tournament_ranking(Tournament)
    end,
    ets:delete(qlg_rank),
    ok.

store_tournament_ranking(T) ->
    store_tournament_ranking(T, ets:match_object(qlg_rank, '$1', ?CHUNK_SIZE)).

store_tournament_ranking(T, '$end_of_table') ->
    qlg_pgsql_srv:tournament_mark_ranked(T);
store_tournament_ranking(T, {Matches, Continuation}) ->
    [store_player_ranking(T, P) || P <- Matches],
    store_tournament_ranking(T, ets:match_object(Continuation)).

store_player_ranking(T, {Id, R, RD, Sigma}) ->
    {ok, 1} = qlg_pgsql_srv:store_player_ranking(T, {Id, R, RD, Sigma}).

write_csv() ->
    Ratings = ets:match_object(qlg_rank, '$1'),
    IoData = ["Player,R,RD,Sigma", $\n,
              [[format_player(R), $\n] || R <- Ratings]],
    file:write_file("rankings.csv", IoData).

format_player({P, R, Rd, S}) ->
    Name = qlg_pgsql_srv:fetch_player_name(P),
    [Name, $,,
     float_to_list(R), $,,
     float_to_list(Rd), $,,
     float_to_list(S)].

rank_parallel([], Workers, _Tournament, _Info) ->
    rank_collect(Workers);
rank_parallel(Players, Workers, Tournament, Info) when is_list(Players) ->
    {Chunk, Rest} =
        try
            lists:split(?CHUNK_SIZE, Players)
        catch
            error:badarg ->
                {Players, []}
        end,
    rank_parallel(Rest,
                  [rpc:async_call(node(),
                                  ?MODULE,
                                  rank_chunk,
                                  [Chunk, Tournament, Info])
                   | Workers], Tournament, Info).

rank_chunk(Players, Tournament, Info) ->
    jobs:run(qlrank,
             fun() ->
                     case dispcount:checkout(Info) of
                         {ok, CheckinReference, C} ->
                             _ = [rank_player(P, C, Tournament) || P <- Players],
                             dispcount:checkin(Info, CheckinReference, C)
                     end,
                     ok
             end).

rank_collect(Workers) ->
    [rpc:yield(K) || K <- Workers].


fetch_players(Tournament) ->
    {ok, _, Players} = qlg_pgsql_srv:players_in_tournament(Tournament),
    Players.

rank_player(P, C, T) ->
    {P, R, RD1, Sigma} = rank1(P, C, T),
    store_player_rating(P, R, RD1, Sigma, T),
    ok.

rank1(Player, C, T) ->
    {Player, R, RD, Sigma} =
        case qlg_pgsql_srv:fetch_player_rating(C, Player) of
            {ok, _, []} ->
                {Player, 1500.0, 350.0, 0.06};
            {ok, _, [Rating]} ->
                Rating
        end,
    Wins = qlg_pgsql_srv:fetch_wins(C, Player, T),
    Losses = qlg_pgsql_srv:fetch_losses(C, Player, T),
    case Wins ++ Losses of
        [] ->
            RD1 = glicko2:phi_star(RD, Sigma),
            {Player, R, RD1, Sigma};
        Opponents ->
            {R1, RD1, Sigma1} =
                glicko2:rate(R, RD, Sigma, Opponents),
            {Player, R1, RD1, Sigma1}
    end.

store_player_rating(P, R, RD, Sigma, _T) ->
    ets:insert(qlg_rank, {P, R, RD, Sigma}).


