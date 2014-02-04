-module(o10k).
-export([test/0, results_for/1]).

-define(FOLDL_SPOOL_TIMEOUT, 10000).

foldl_spool(Fun, Acc0, Port) ->
    receive
        {Port, {data,{_eol_or_noeol, Line}}} ->
            Acc1 = Fun(Line, Acc0),
            foldl_spool(Fun, Acc1, Port);
        {Port, eof} ->
            port_close(Port),
            Acc0
    after ?FOLDL_SPOOL_TIMEOUT ->
            port_close(Port),
            {error, timeout}
    end.

fold_line(Line, Acc) ->
    Uri = lists:nth(7, string:tokens(Line, " ")),
    case Uri of
        "/ongoing/When/" ++ Trailer ->
            case lists:member($., Trailer) of
                true ->
                    Acc;
                false ->
                    Acc + 1
            end;
        _ ->
            Acc
    end.

test() ->
    results_for("o10k.ap").

results_for(File) ->
    Port = open_port({spawn, "cat "++File},
                     [eof, stream, {line, 4096}]),
    foldl_spool(fun fold_line/2, 0, Port).
