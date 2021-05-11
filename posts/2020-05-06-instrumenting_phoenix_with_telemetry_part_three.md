%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2020-05-06],
  tags: ["phoenix", "telemetry", "instrumenting"],
  title: "Instrumenting Phoenix with Telemetry Part III: Phoenix + Ecto Telemetry Events",
  excerpt: """
  In this series, we're instrumenting a Phoenix app and sending metrics to StatsD with the help of Elixir and Erlang's Telemetry offerings.
  In Part III we'll examine Phoenix and Ecto's out-of-the-box Telemetry events and use `Telemetry.Metrics` to observe a wide-range of such events.
  """
}

---

## Table Of Contents

In this series, we're instrumenting a Phoenix app and sending metrics to StatsD with the help of Elixir and Erlang's Telemetry offerings.

* [Part I: Telemetry Under The Hood](https://elixirschool.com/blog/instrumenting-phoenix-with-telemetry-part-one/)
* [Part II: Handling Telemetry Events with `TelemetryMetrics` + `TelemetryMetricsStatsd`](https://elixirschool.com/blog/instrumenting_phoenix_with_telemetry_part_two/)
* Part III: Observing Phoenix + Ecto Telemetry Events
* [Part IV: Erlang VM Measurements with `telemetry_poller`, `TelemetryMetrics` + `TelemetryMetricsStatsd`](https://elixirschool.com/blog/instrumenting-phoenix-with-telemetry-part-four/)

## Intro

In the [previous post](https://elixirschool.com/blog/instrumenting_phoenix_with_telemetry_part_two/), we saw how the `Telemetry.Metrics` and `TelemetryMetricsStatsd` libraries abstracted away the need to define custom handlers, attach those handlers to events, and implement our own metric reporting logic. But our Telemetry pipeline still needs a little work--we're still on the hook for emitting all of our own Telemetry events!

In order to really be able to observe the state of our production Phoenix app, we need to be reporting on much more than just one endpoint's request duration and count. We need to report information-rich metrics describing web requests across the app, database queries, the behavior and state of the Erlang VM, the behavior and state of any workers in our app, and more.

Instrumenting all of that by hand, by executing custom Telemetry events wherever we need them, will be tedious and time-consuming. On top of that, it will be a challenge to standardize event naming conventions, measurements, and metadata across the app.

In this post, we'll examine Phoenix and Ecto's out-of-the-box Telemetry events and use `Telemetry.Metrics` to observe a wide-range of such events.

## Achieving Observability with Phoenix and Ecto Telemetry Events

To achieve observability, we know we nee to track things like:

* Count and duration of all requests to all endpoints, with the ability to view this information broken down by things like:
  * Route
  * Response status
* Count and duration of all Ecto queries, with the ability to view this information broken down by things like:
  * Query command (e.g. `SELECT`, `UPDATE`)
  * Table (e.g. `Users`)

Luckily for us, pretty much _all_ of these events are already being emitted by Phoenix and Ecto directly!

In the following tutorial, we will teach `Telemetry.Metrics` to observe these out-of-the-box events and format the appropriate set of metrics, with information-rich tags, for each event.

## A Note On Formatting Metrics

In our previous post, we used the `TelemetryMetricsStatsd` reporting library to format metrics and send them to StatsD over UDP. We can configure this reporter with either the standard formatter or the DogStatsD formatter. The standard formatter constructs and emits metrics that are compatible with the Etsy implementation of StatsD. This implementation does _not_ support tagging, so `TelemetryMetricsStatsd` accommodates the tags we assign to metrics by including the tag values in the metric name.

For example, if we specify the following counter metric:

```elixir
counter(
  "phoenix.request",
  tags: [:request_path]
)
```

And execute a Telemetry event where the `conn` we pass in for the metadata argument contains `%{request_path: "/register/new"}`, then `TelemetryMetricsStatsd` will construct a metric:

```
"phoenix.request.-register-new"
```

What if we ultimately want to send StatsD metrics to Datadog, which _does_ support metric tagging? In that case, we can configure the `TelemetryMetricsStatsd` reporter to use the DogStatsD formatter, which would emit the following counter metric for the above event, including tags:

```
"phoenix.request:1|c|#request_path:/register/new"
```

For the purposes of this tutorial, we'll use the DogStatsD formatter to make it easy to read and understand the metrics and tags that we are constructing and sending to StatsD.


```elixir
defmodule Quantum.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {TelemetryMetricsStatsd, metrics: metrics(), formatter: :datadog} # Add the formatter here!
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics do
    [
      # coming soon!
    ]
  end
end
```

## Getting Started

You can follow along with this tutorial by cloning down the repo [here]
(https://github.com/elixirschool/telemetry-code-along/tree/part-3-start).
* Checking out the starting state of our code on the branch [part-3-start](https://github.com/elixirschool/telemetry-code-along/tree/part-3-start)
* Find the solution code on the branch [part-3-solution](https://github.com/elixirschool/telemetry-code-along/tree/part-3-solution)


## Phoenix Telemetry Events

### The `[:phoenix, :router_dispatch, :stop]` Event

First up, we'll leverage one of the out-of-the-box Phoenix events to help us track and report metrics for web request counts and durations--the `[:phoenix, :router_dispatch, :stop]` event.

The `Phoenix.Router` module executes this event after the request is processed by the Plug pipeline and the controller, but _before_ a response is rendered. Looking in Phoenix source code we can see the event being emitted [here](https://github.com/phoenixframework/phoenix/blob/d4596650df21e7e0603debcb5f2ad25eb9ac082d/lib/phoenix/router.ex#L357):

```elixir
# phoenix/lib/phoenix/router.ex

duration = System.monotonic_time() - start
metadata = %{metadata | conn: conn}
:telemetry.execute([:phoenix, :router_dispatch, :stop], %{duration: duration}, metadata)
```

Here, Phoenix is calculating the duration by subtracting the start time, set at the beginning of the request processing pipeline, from the current time. Then it's updating the metadata map to include the `conn`. Lastly, it's executing the Telemetry metric with this information.

Now that we know which Telemetry event we care about, let's make our `Telemetry.Metrics`, `Quantum.Telemetry` module aware of it.


```elixir
# lib/quantum/telemetry.ex

def metrics do
  [
    summary(
      "phoenix.router_dispatch.stop.duration",
      unit: {:native, :millisecond},
      tags: [:plug, :plug_opts]
    ),

    counter(
      "phoenix.router_dispatch.stop.count",
      tags: [:plug, :plug_opts]
    )
  ]
end
```

Now, whenever the `Phoenix.Router` executes the `[:phoenix, :router_dispatch, :stop]` Telemetry event for a given web request, we will see counter and timer metrics emitted to StatsD tagged with the `:plug` and `:plug_opts` values from the event metadata.

By running the app and visiting the landing page, we see the following reported to StatsD:

```
# timing
"phoenix.router_dispatch.stop.duration:5.411|ms|#plug:Elixir.QuantumWeb.PageController,plug_opts:index"

# counter
"phoenix.router_dispatch.stop.count:1|c|#plug:Elixir.QuantumWeb.PageController,plug_opts:index"
```

This represents a BIG win for us, as compared to our previous approach of manually executing a Telemetry event from _every controller action in our app_. By defining metrics for this event in our `Quantum.Telemetry` module and providing those metrics to the `TelemetryMetricsStatsd` reporter, we are able to report metrics for every web request our app receives, across all endpoints.

### Getting More Out Of Tags

We can also see how helpful the `:tags` option of the metrics functions can be. These tags are ensuring that the metrics we report to StatsD are information-rich--they contain data from the context of the web request. Recall from the previous post that the `TelemetryMetricsStatsd` reporter will apply tags for a given metric where those tags are present as keys in the event metadata. So, when `Phoenix.Router` executes the following Telemetry event:

```elixir
# phoenix/lib/phoenix/router.ex

duration = System.monotonic_time() - start
metadata = %{metadata | conn: conn}
:telemetry.execute([:phoenix, :router_dispatch, :stop], %{duration: duration}, metadata)
```

It provides the `:telemetry.execute/3` call with `metadata` that includes top-level keys of `:plug` and `:plug_opts`.

It _also_ includes the request `conn` in that metadata map, under a key of `:conn`. What if we want to grab some data out of the `conn` to include in our metric tags?

It would be great if we could tag these web request counter metrics with the response status--that way we can aggregate counts of successful and failed web requests.

The response status _is_ present in the `conn`, under a key of `:status`. But the `Telemetry.Metrics.counter/2` function only knows how to deal with tags that are top-level in the provided `metadata`. If only there was some way to tell the counter metric how to apply tags from data that is _nested inside_ the provided metadata.

This is where the metrics functions' `:tag_values` option comes in! We can use the `:tag_values` option to store a function that will be called later on during the Telemetry event handling process to construct additional tags from nested metadata info.

All _we_ have to do is implement a function that expects to receive the event metadata and returns a map that includes all of the tags we want to apply to our metric:

```elixir
# lib/quantum/telemetry.ex

def endpoint_metadata(%{conn: %{status: status}, plug: plug, plug_opts: plug_opts}) do
  %{status: status, plug: plug, plug_opts: plug_opts}
end
```

Then, when we call a given metrics function, for example `counter/2`, we set  the `:tag_values` option to this function and `:tags` to our complete list of tags:

```elixir
# lib/quantum/telemetry.ex

def metrics do
  [
    counter(
      "phoenix.router_dispatch.stop.count",
      tag_values: &__MODULE__.endpoint_metadata/1,
      tags: [:plug, :plug_opts, :status]
    )
  ]
end
```

Now, when we run our Phoenix server and visit the landing page, we see the following counter metric emitted to StatsD:

```
"phoenix.router_dispatch.stop.count:1|c|#plug:Elixir.QuantumWeb.PageController,plug_opts:index,status:200"
```

Notice that now the metric is tagged with the response status. This will make it easy for us to visualize counts of failed and successful requests in Datadog.

### More Phoenix Telemetry Events

So far, we've taken advantage of just one of several Telemetry events executed by Phoenix source code. There are a number of helpful events we can have our Telemetry pipeline handle. Let's take a brief look at some of these events now.

#### The `[:phoenix, :error_rendered]` Telemetry Event

The `Phoenix.Endpoint.RenderErrors` module executes a Telemetry event after rendering the error view. We can see the call to execute this event in source code [here](https://github.com/phoenixframework/phoenix/blob/00a022fbbf25a9d0845329161b1bc1a192c2d407/lib/phoenix/endpoint/render_errors.ex#L81):

```elixir
# phoenix/lib/phoenix/endpoint/render_errors.ex

defp instrument_render_and_send(conn, kind, reason, stack, opts) do
  start = System.monotonic_time()
  metadata = %{status: status, kind: kind, reason: reason, stacktrace: stack, log: level}

  try do
    render(conn, status, kind, reason, stack, opts)
  after
    duration = System.monotonic_time() - start
    :telemetry.execute([:phoenix, :error_rendered], %{duration: duration}, metadata)
  end
end
```

We can tell our Telemetry pipeline to handle this event as a counter and tag it with the request path and response status in our `Quantum.Telemetry.metrics/0` function like this:

```elixir
# lib/quantum/telemetry.ex

def metrics do
  [
    counter(
      "phoenix.error_rendered.count",
      tag_values: &__MODULE__.error_request_metadata/1,
      tags: [:request_path, :status]
    )
  ]
end

def error_request_metadata(%{conn: %{request_path: request_path}, status: status}) do
  %{status: status, request_path: request_path}
end
```

Now, we'll see the following counter metric incremented in StatsD when a user visits, `/blah`, a path that does not exist:

```
"phoenix.error_rendered.count:1|c|#request_path:blah,status:404"
```

#### `Phoenix.Socket` Telemetry Event

Phoenix also provides some out-of-the-box instrumentation for Socket and Channel interactions.

The `Phoenix.Socket` module executes a Telemetry event whenever the socket is connected to. We can see that event in source code [here](https://github.com/phoenixframework/phoenix/blob/e83b6291cb4ed7cd6572b7af274842910667ade3/lib/phoenix/socket.ex#L450):

```elixir
# phoenix/lib/phoenix/socket.ex
def __connect__(user_socket, map, socket_options) do
  %{
    endpoint: endpoint,
    options: options,
    transport: transport,
    params: params,
    connect_info: connect_info
  } = map

  start = System.monotonic_time()

  case negotiate_serializer(Keyword.fetch!(options, :serializer), vsn) do
    {:ok, serializer} ->
      result = user_connect(user_socket, endpoint, transport, serializer, params, connect_info)

      metadata = %{
        endpoint: endpoint,
        transport: transport,
        params: params,
        connect_info: connect_info,
        vsn: vsn,
        user_socket: user_socket,
        log: Keyword.get(options, :log, :info),
        result: result(result),
        serializer: serializer
      }

      duration = System.monotonic_time() - start
      :telemetry.execute([:phoenix, :socket_connected], %{duration: duration}, metadata)
      result

    :error ->
      :error
  end
end
```

We can see that the event is executed with the duration measurement and a metadata map that includes the connection params and other contextual info. We can tell our Telemetry pipeline to handle this event by adding metrics for the `"phoenix.socket_connected"` event in our `Quantum.Telemetry.metrics/0` list:

For example:

```elixir
# lib/quantum/telemetry.ex

def metrics do
  [
    counter(
      "phoenix.socket_connected.count",
      tags: [:endpoint]
    )
  ]
end
```

Now we will increment a StatsD metric every time the socket is joined.

### `Phoenix.Channel` Telemetry Events

The `Phoenix.Channel.Server` module executes two Telemetry events--one when the channel is joined and one whenever the channel invokes `handle_info/2`.

We can see the `[:phoenix, :channel_joined]` Telemetry event in source code [here](https://github.com/phoenixframework/phoenix/blob/8a4aa4eed0de69f94ab09eca157c87d9bd204168/lib/phoenix/channel/server.ex#L302):

```elixir
# phoenix/lib/phoenix/channel/server.ex

def handle_info({:join, __MODULE__}, {auth_payload, {pid, _} = from, socket}) do
  %{channel: channel, topic: topic, private: private} = socket

  start = System.monotonic_time()
  {reply, state} = channel_join(channel, topic, auth_payload, socket)
  duration = System.monotonic_time() - start
  metadata = %{params: auth_payload, socket: socket, result: elem(reply, 0)}
  :telemetry.execute([:phoenix, :channel_joined], %{duration: duration}, metadata)
  GenServer.reply(from, reply)
  state
end
```

And we can see the `[:phoenix, channel_handled_in]` event [here](https://github.com/phoenixframework/phoenix/blob/8a4aa4eed0de69f94ab09eca157c87d9bd204168/lib/phoenix/channel/server.ex#L319)

```elixir
# phoenix/lib/phoenix/channel/server.ex

def handle_info(
    %Message{topic: topic, event: event, payload: payload, ref: ref},
    %{topic: topic} = socket
  ) do
  start = System.monotonic_time()

  result = socket.channel.handle_in(event, payload, put_in(socket.ref, ref))
  duration = System.monotonic_time() - start
  metadata = %{ref: ref, event: event, params: payload, socket: socket}

  :telemetry.execute([:phoenix, :channel_handled_in], %{duration: duration}, metadata)

  handle_in(result)
end
```

We can add some metrics reporting for these events by defining metrics in `Quantum.Telemetry` for either of the `"phoenix.channel_joined"` and `"phoenix.channel_handled_in"` events.

Now that we've taken a brief tour of Phoenix Telemetry events, let's hook up some reporting for Ecto events.

## Ecto Telemetry Events

Ecto provides some out-of-the-box instrumentation for queries. Let's take a look at and define metrics for some of these Telemetry events now.

Ecto will execute a Telemetry event, [`[:my_app, :repo, :query]`](https://github.com/elixir-ecto/ecto/blob/2aca7b28eef486188be66592055c7336a80befe9/lib/ecto/repo.ex#L120) for every query sent to the Ecto adapter. It will emit this event with a measurement map and a metadata map.

The measurement map will include:

```
* `:idle_time` - the time the connection spent waiting before being checked out for the query
* `:queue_time` - the time spent waiting to check out a database connection
* `:query_time` - the time spent executing the query
* `:decode_time` - the time spent decoding the data received from the database
* `:total_time` - the sum of the other measurements
```

The metadata map will includes:

```
* `:type` - the type of the Ecto query. For example, for Ecto.SQL
    databases, it would be `:ecto_sql_query`
* `:repo` - the Ecto repository
* `:result` - the query result
* `:params` - the query parameters
* `:query` - the query sent to the database as a string
* `:source` - the source the query was made on (may be nil)
* `:options` - extra options given to the repo operation under
  `:telemetry_options`
```

If we want to establish metrics for Ecto query counts aggregated by table and command, we could establish the following metric in our `Quantum.Telemetry` metrics list:

```elixir
def metrics do
  [
    counter(
      "quantum.repo.query.count",
      tag_values: &__MODULE__.query_metatdata/1,
      tags: [:source, :command]
    )
  ]
end

def query_metatdata(%{source: source, result: {_, %{command: command}}}) do
  %{source: source, command: command}
end
```

This will increment a counter in StatsD for each query to a given table with a given command. For example:

```
"quantum.repo.query:1|c|#source:users,command:select"
```

We can also establish a timing metric with the use of the `summary` metric function:

```elixir
def metrics do
  [
    summary(
      "quantum.repo.query.total_time",
      unit: {:native, :millisecond},
      tag_values: &__MODULE__.query_metadata/1,
      tags: [:source, :command]
    )
  ]
end

def query_metadata(%{source: source, result: {_, %{command: command}}}) do
  %{source: source, command: command}
end
```

This will report timing metrics to StatsD for each query executed with a given command to a given table. For example:

```
"quantum.repo.query.total_time:1.7389999999999999|ms|#source:users,command:select"
```

## More Metrics

This post has mainly focused on the `counter/2` and `summary/2` `Telemetry.Metrics` functions, corresponding to the "count" and "timing" StatsD metric type respectively. `Telemetry.Metrics` implements five metrics functions, each of which map to a specific metric type. To learn how to define and report on these various metric types, check out the docs [here](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html#module-metrics) and [here](https://hexdocs.pm/telemetry_metrics_statsd/TelemetryMetricsStatsd.html)

## Conclusion

Instrumenting our Phoenix app by taking advantage of the Telemetry events that are executed for us by Phoenix and Ecto allowed us to achieve a high degree of observability without writing a lot of custom code.

We simply defined our `Telemetry.Metrics` module, configured it to start up the `TelemetryMetricsStatsd` reporter and defined the list of existing Telemetry events to observe as metrics. Now we're reporting a valuable set of information-rich metrics to StatsD, formatted for Datadog, without manually executing a single Telemetry event or defining any of our own event handlers.

## Next Up

There's one more flavor of out-of-the-box metrics reporting we'll explore in this series. In our [next post](https://elixirschool.com/blog/instrumenting-phoenix-with-telemetry-part-four/), we'll use the `telemetry_poller` Erlang library to emit Erlang VM measurements as Telemetry events and we'll use `Telemetry.Metrics` and `TelemetryMetricsStatsd` to observe and report those events as metrics.
