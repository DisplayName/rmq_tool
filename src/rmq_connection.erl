-module(rmq_connection).
-behaviour(gen_server).

-export([
        start_link/0,
        get_channel/0
]).

-export([
        init/1,
        handle_call/3,
        handle_cast/2,
        handle_info/2,
        terminate/2,
        code_change/3
]).


-include("logging.hrl").
-include_lib("amqp_client/include/amqp_client.hrl").


-record(state, {
            connection,
            channel
}).



%% ===================================================================
%% APIs
%% ===================================================================

%% @doc starting module
-spec start_link() -> {ok, pid()}.
start_link() ->
   gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


%% @doc get current channel
-spec get_channel() -> pid().
get_channel() ->
    gen_server:call(?MODULE, get_channel).


%% ===================================================================
%% gen_server callbacks
%% ===================================================================
init([]) ->
    AP = get_default_amqp_params(),


    case amqp_connection:start(AP) of
        {ok, Connection} ->
            ?log_info("Connected to RabbitMQ", []),
            {ok, Channel} = amqp_connection:open_channel(Connection),
            link(Channel),
            {ok, #state{connection = Connection, channel = Channel}};
        {error, _Reason} ->
            ?log_error("Can't connect to RabbitMQ", [])
    end.


handle_cast(Request, State) ->
    {stop, {bad_arg, Request}, State}.
  
handle_info(Info, State) ->
    {stop, {bad_arg, Info}, State}.


handle_call(get_channel, _From, State) ->
    {reply, State#state.channel, State};

handle_call(_Request, _From, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.


code_change(_OldSvn, State, _Extra) ->
    {ok, State}.


%% ===================================================================
%% Internal
%% ===================================================================


%% get default AMQP params from config
-spec get_default_amqp_params() -> #amqp_params_network{}.
get_default_amqp_params() ->
    {ok, Host} = application:get_env(rmq_tool, amqp_host),
    {ok, Port} = application:get_env(rmq_tool, amqp_port),
    {ok, User} = application:get_env(rmq_tool, amqp_user),
    {ok, Pass} = application:get_env(rmq_tool, amqp_pass),
    
    #amqp_params_network{ 
        username = User,
        password = Pass,
        host = Host,
        port = Port,
        heartbeat = 1
    }.