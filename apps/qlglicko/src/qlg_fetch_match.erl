-module(qlg_fetch_match).

-include("match.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1, run/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, { id }).

%%%===================================================================

start_link(Name) ->
    gen_server:start_link(?MODULE, [Name], []).

run(Pid) ->
    gen_server:cast(Pid, run).

%%%===================================================================

%% @private
init([Id]) ->
    true = gproc:add_local_name({fetch_match, Id}),
    {ok, #state{ id = Id }}.

%% @private
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% @private
handle_cast(run, State) ->
    %% @todo Handle errors and overloads
    case jobs:ask(ql_fetch) of
        {ok, _Opaque} ->
            fetch_and_store(State),
            {stop, normal, State}
    end;
handle_cast(_Msg, State) ->
    {noreply, State}.

%% @private
handle_info(_Info, State) ->
    {noreply, State}.

%% @private
terminate(_Reason, _State) ->
    ok.

%% @private
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================

fetch_and_store(#state { id = Id }) ->
    lager:debug("Fetching match ~p", [Id]),
    {ok, JSON} = ql_fetch:match(Id),
    persist_duel_match(Id, JSON),
    %% Do this last as a confirmation we got through the other parts
    %% This ensures an idempotent database.
    {ok, 1} = qlg_pgsql_srv:store_match(
                Id,
                term_to_binary(JSON, [compressed])),
    ok.

persist_duel_match(Id, JSON) ->
    case {proplists:get_value(<<"GAME_TYPE">>, JSON),
          proplists:get_value(<<"RANKED">>, JSON)} of
        {<<"duel">>, <<"1">>} ->
            %% Duel game type. And ranked. Find the winner and the loser
            [P1, P2] = proplists:get_value(<<"SCOREBOARD">>, JSON),
            Played = proplists:get_value(<<"GAME_TIMESTAMP">>, JSON),
            P1S = extract_scores(P1),
            P2S = extract_scores(P2),
            {ok, P1_Id} = add_new_player(P1S),
            {ok, P2_Id} = add_new_player(P2S),
            M = mk_match(decode_timestamp(Played),
                         {P1_Id, P1S},
                         {P2_Id, P2S}),
            qlg_pgsql_srv:store_match(Id, M),
            ok;
        {<<"duel">>, <<"0">>} ->
            %% Unranked game, do not store it
            ok
    end.

add_new_player({Name, _, _} = In) ->
    case qlg_pgsql_srv:select_player(Name) of
        {ok, _, []} ->
            ok = qlg_pgsql_srv:mk_player(Name),
            add_new_player(In);
        {ok, _, [{Id, Name}]} ->
            {ok, Id}
    end.

decode_timestamp(Bin) when is_binary(Bin) ->
    {ok, [Month, Day, Year, HH, MM, AMPM], ""} =
        io_lib:fread("~u/~u/~u ~u:~u ~s", binary_to_list(Bin)),
    Date = {Year, Month, Day},
    Time = {case AMPM of
                "AM" -> HH;
                "PM" -> HH + 12
            end, MM, 0},
    {Date, Time}.

extract_scores(Obj) ->
    case {proplists:get_value(<<"PLAYER_NICK">>, Obj),
          proplists:get_value(<<"RANK">>, Obj),
          proplists:get_value(<<"SCORE">>, Obj)} of
        {undefined, _, _} ->
            exit(invariant_breach);
        {_, undefined, _} ->
            exit(invariant_breach);
        {_, _, undefined} ->
            exit(invariant_breach);
        {Player, Rank, Score} ->
            {Player, decode_rank(Rank), Score}
    end.

decode_rank(<<"1">>) -> 1;
decode_rank(<<"2">>) -> 2;
decode_rank(<<"-1">>) -> 999.

mk_match(Played, {Id1, {_P1, R1, S1}},
                 {Id2, {_P2, R2, S2}}) when R1 < R2 ->
    #duel_match { played = Played,
                  winner = Id1, winner_score = S1,
                  loser  = Id2, loser_score = S2 };
mk_match(Played, {Id1, {_P1, R1, S1}},
                 {Id2, {_P2, R2, S2}}) when R2 < R1 ->
    #duel_match { played = Played,
                  winner = Id2, winner_score = S2,
                  loser = Id1, loser_score = S1 }.
