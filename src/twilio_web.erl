%%%-------------------------------------------------------------------
%%% @author Ryan Huffman <ryanhuffman@gmail.com>
%%% @copyright 2011, Ryan Huffman
%%% @doc Twilio web server.  Routes requests to handler modules.
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(twilio_web).

-export([start/0, start/1, loop/1, route/2]).

-include("twilio.hrl").

-define(DEFAULT_PORT, 8080).

%% @equiv start(8080)
start() ->
    start(?DEFAULT_PORT).

%% @doc Starts a mochiweb HTTP server on the specified port.  Incoming
%% requests will be routed to the handling "twilio_rt_*" module.
start(Port) ->
    io:format("Starting mochiweb bound to port ~p~n", [Port]),
    mochiweb_http:start([{name, ?MODULE}, {port, Port},
                         {loop, {?MODULE, loop}}]).

%% @doc Mochiweb loop, handling incoming twilio requests.
loop(Req) ->
    case Req:get(method) of
        'GET' ->
            Params = Req:parse_qs();
        'POST' ->
            Params = Req:parse_post()
    end,
    "/" ++ Path = Req:get(path),
    PathList = string:tokens(Path, "/"),

    % TRADITIONAL TwiML
    % uncomment this option to use traditional Twiml and
    % manual routing
    XML = route(PathList, Params),

    % EXTENDED TwiML
    % uncomment this option to use Extended TwiML
    % NOTE to use this option you will need to break out the state from
    %      the path - it will be the last URL segment
    %XML = twilio_ext:handle(Params, PathList),

    % finally respond to Twilio
    Req:ok({"text/xml", XML}).


    

%% @doc Routes a twilio request to a handler that will
%% return a twiml XML document.

%     
% route(Data1,Data2) ->
%     io:format("Data1 [~p]   Data2[~p]", [Data1, Data2]),
%     "".
    
route([XData], []) ->
    io:format("XData ~p ~n", [XData]),
    "";
  
route([Head | PathTail], Params) ->
    io:format("Head [~p]~n", [Head]),
    io:format("Params [~p]~n", [Params]),
    io:format("PathTail [~p] ~n", [PathTail]),
    HandlerModule = list_to_existing_atom("twilio_rt_" ++ Head),
    %%FIXME: El twiml encode no utiliza encoding utf8 y no funcionan
    %%tts con caracteres extraños
    Twiml = HandlerModule:handle_request(PathTail, Params),
    twiml:encode(Twiml);

route([], []) ->
    io:format("No web info ~n", []),
    "".