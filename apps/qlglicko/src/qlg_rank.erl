-module(qlg_rank).

-export([rank/2, rank_chunk/3]).

-define(CHUNK_SIZE, 1000).

rank(Tournament, Info) ->
    ets:new(qlg_rank, [named_table, public]),
    Players = fetch_players(Tournament),
    _ = rank_parallel([P || {P} <- Players], [], Tournament, Info),
    ok = write_csv(),
    ets:delete(qlg_rank),
    ok.

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
                             _ = [rank(P, C, Tournament) || P <- Players],
                             dispcount:checkin(Info, CheckinReference, C)
                     end,
                     ok
             end).

rank_collect(Workers) ->
    [rpc:yield(K) || K <- Workers].


fetch_players(_Tournament) ->
    {ok, _, Players} = qlg_pgsql_srv:players_in_tournament(),
    Players.

rank(P, C, T) ->
    {P, R, RD1, Sigma} = rank1(P, C, T),
    store_player_rating(P, R, RD1, Sigma, T),
    ok.

rank1(Player, C, _) ->
    {Player, R, RD, Sigma} =
        case qlg_pgsql_srv:fetch_player_rating(C, Player) of
            {ok, _, []} ->
                {Player, 1500.0, 350.0, 0.06};
            {ok, _, [Rating]} ->
                Rating
        end,
    Wins = qlg_pgsql_srv:fetch_wins(C, Player),
    Losses = qlg_pgsql_srv:fetch_losses(C, Player),
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


