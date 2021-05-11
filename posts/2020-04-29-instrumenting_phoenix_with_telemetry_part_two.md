%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2020-04-29],
  tags: ["phoenix", "telemetry", "instrumenting"],
  title: "Instrumenting Phoenix with Telemetry Part II: Telemetry Metrics + Reporters",
  excerpt: """
  In this series, we're instrumenting a Phoenix app and sending metrics to StatsD with the help of Elixir and Erlang's Telemetry offerings.
  In Part II we'll use Elixir's `Telemetry.Metrics` and `TelemetryMetricsStatsd` libraries to define and send metrics to StatsD for a given Telemetry event.
  """
}

---

## Table Of Contents

In this series, we're instrumenting a Phoenix app and sending metrics to StatsD with the help of Elixir and Erlang's Telemetry offerings.

* [Part I: Telemetry Under The Hood](https://elixirschool.com/blog/instrumenting-phoenix-with-telemetry-part-one/)
* Part II: Handling Telemetry Events with `TelemetryMetrics` + `TelemetryMetricsStatsd`
* [Part III: Observing Phoenix + Ecto Telemetry Events](https://elixirschool.com/blog/instrumenting_phoenix_with_telemetry_part_three/)
* [Part IV: Erlang VM Measurements with `telemetry_poller`, `TelemetryMetrics` + `TelemetryMetricsStatsd`](https://elixirschool.com/blog/instrumenting-phoenix-with-telemetry-part-four/)

## Intro

In [Part I](https://elixirschool.com/blog/instrumenting-phoenix-with-telemetry-part-one/) of this series, we learned why observability is important and introduced Erlang's Telemetry library. We used it to hand-roll some instrumentation for our Phoenix app, but it left us with some additional problems to solve. In this post, we'll use Elixir's `Telemetry.Metrics` and `TelemetryMetricsStatsd` libraries to define and send metrics to StatsD for a given Telemetry event.

## Recap

In [our previous post](https://elixirschool.com/blog/instrumenting-phoenix-with-telemetry-part-one/), we added some Telemetry instrumentation to our Phoenix app, [Quantum](https://github.com/elixirschool/telemetry-code-along/tree/part-1-solution). You can review the final code from our previous article [here](https://github.com/elixirschool/telemetry-code-along/tree/part-1-solution). To recap, we established a Telemetry event, `[:phoenix, :request]`, that we attached to a handler module, `Quantum.Telemetry.Metrics`. We executed this event from just one controller action--the `new` action of the `UserController`.

From that controller action, we execute the Telemetry event with a measurement map that includes the duration of the web request along with the request `conn`:

```elixir
# lib/quantum_web/controllers/user_controller.ex
def new(conn, _params) do
  start = System.monotonic_time()
  changeset = Accounts.change_user(%User{})
  :telemetry.execute([:phoenix, :request], %{duration: System.monotonic_time() - start}, conn)
  render(conn, "new.html", changeset: changeset)
end
```

We handle this event in our handler module, `Quantum.Telemetry.Metric`, with the `handle_event/4` callback function. In this function we use the event data, including the duration and information in the `conn` to, send a set of metrics to StatsD with the help of the `Statix` Elixir StatsD client library:

```elixir
# lib/quantum/telemetry/metrics.ex
defmodule Quantum.Telemetry.Metrics do
  require Logger
  alias Quantum.Telemetry.StatsdReporter

  def handle_event([:phoenix, :request], %{duration: dur}, metadata, _config) do
    StatsdReporter.increment("phoenix.request.success", 1)
    StatsdReporter.timing("phoenix.request.success", dur)
  end
end
```

## What's Wrong With This?

Telemetry made it easy for us to emit an event and operate on it, but our current usage of the Telemetry library leaves a lot to be desired.

One drawback of our current approach is that it leaves us on the hook for Telemetry event handling and metrics reporting. We had to define our own custom event handling module, manually attach that module to the given Telemetry event and define the handler's callback function.

In order for that callback function to report metrics to StatsD for a given event, we had to create our own custom module that uses the `Statix` library _and_ write code that formats the metric to send to StatsD for a given Telemetry event. The mental overhead of translating Telemetry event data into the appropriate StatsD metric is costly, and that effort will have to be undertaken for every new Telemetry event we execute and handle.

## We Need Help

Wouldn't it be great if we _didn't_ have to define our own handler modules or metric reporting logic? If only there was some way to simply list the Telemetry events we care about and have them automatically reported to StatsD as the correctly formatted metric...

This is exactly where the `Telemetry.Metrics` and `TelemetryMetricsStatsd` libraries come in!

## Introducing `Telemetry.Metrics` and `TelemetryMetricsStatsd`

The [`Telemetry.Metrics` library](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html) provides a common interface for defining metrics based on Telemetry events. It allows us declare the set of Telemetry events that we want to handle and specify which metrics to construct for these events. It also allows us to specify an out-of-the-box reporter with which to handle and report our events to third-parties.

This means we _don't_ have to define our own handler modules and functions and we _don't_ have to write any code responsible for reporting metrics for events to common third-party tools like StatsD. We'll report our metrics to StatsD with the `TelemetryMetricsStatsd` reporting library, but Elixir's Telemetry family of libraries also includes a reporter for Prometheus, or you can roll your own.

In the previous post, we added code to execute the following Telemetry event from the `new` action of our `UserController`:

```elixir
:telemetry.execute([:phoenix, :request], %{duration: System.monotonic_time() - start}, conn)
```

Now, instead of handling this event with our custom handler and `Statix` reporter, will use `Telemetry.Metrics` and the `TelemetryMetricsStatsd` reporter to do all of the work for us!

## How It Works

Before we start writing code, let's walk through how `Telemetry.Metrics` and the `TelemetryMetricsStatsd` reporter work together with Erlang's Telemetry library to handle Telemetry events.

The `Telemetry.Metrics` library is responsible for specifying which Telemetry events we want to handle as metrics. It defines the list of events we care about and specifies which events should be sent to StatsD as which type of metric (for example, counter, timing, gauge etc.). It gives this list of events-as-metrics to the Telemetry reporting client, `TelemetryMetricsStatsd`.

The `TelemetryMetricsStatsd` library is responsible for taking that list of events and attaching its own event handler module, `TelemetryMetricsStatsd.EventHandler` to each event via a call to `:telemetry.attach/4`. Recall from our first post that `:telemetry/attach/4` stores events and their associated handlers in an ETS table.

Later, when a Telemetry event is executed via a call to `:telemetry.execute/3`, Telemetry looks up the event handler, `TelemetryMetricsStatsd.EventHandler`, for the given event in the ETS table and invokes it. The event handler module will format the event, metadata and any associated tags as the appropriate StatsD metric and send the resulting metric to StatsD over UDP.

Most of this happens under the hood. We are only on the hook for defining a `Telemetry.Metrics` module and listing the Telemetry events we want to handle as which type of metric. That's it!

## Getting Started

You can follow along with this tutorial by cloning down the repo [here](https://github.com/elixirschool/telemetry-code-along/tree/part-2-start).
* Checking out the starting state of our code on the branch [part-2-start](https://github.com/elixirschool/telemetry-code-along/tree/part-2-start)
* Find the solution code on the branch [part-2-solution](https://github.com/elixirschool/telemetry-code-along/tree/part-2-solution)

## Overview

In order to get this Telemetry pipeline up and running, we don't have to write too much code.

We will:

1. Define a supervisor module that imports `Telemetry.Metrics`
2. Define a set of metrics for the Telemetry events we want to observe using the `Telemetry.Metrics` metrics definition functions
3. Tell the supervisor to run the `TelemetryMetricsStatsd` GenServer with the list of metrics we defined in the previous step

Let's do it!

## Setting Up `Telemetry.Metrics`

First, we'll add the `Telemetry.Metrics` library and the `TelemetryMetricsStatsd` reporter library to our application's dependencies and run `mix deps.get`:

```elixir
# mix.exs
defp deps do
  [
    {:telemetry_metrics, "~> 0.4"},
    {:telemetry_metrics_statsd, "~> 0.3.0"}
  ]
end
```

Now we're ready to define a module that imports `Telemetry.Metrics`.

## Step 1: Defining a Metrics Module

We'll define a module that imports the `Telemetry.Metrics` library and acts as a Supervisor. Our Supervisor will start up the child GenServer provided by the `TelemetryMetricsStatsd` reporter. It will start that GenServer along with an argument of the list of Telemetry events to listen for, structured as metrics, via the `:metrics` option.

We'll place our metrics module in `lib/quantum/telemetry.ex`

```elixir
defmodule Quantum.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {TelemetryMetricsStatsd, metrics: metrics()}
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

We'll come back to the metrics list in a bit. First, let's teach our application to start this Supervisor when the app starts up but adding it to our application's supervision tree in the `Quantum.Application.start/2` function:

```elixir
# lib/quantum/application.ex
def start(_type, _args) do
  children = [
    Quantum.Repo,
    QuantumWeb.Endpoint,
    Quantum.Telemetry
  ]

  opts = [strategy: :one_for_one, name: Quantum.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Now we're ready to specify which Telemetry events to handle as metrics.

## Step 2: Specifying Events As Metrics

Our `Telemetry.Metrics` module, `Quantum.Telemetry`, is responsible for telling the `TelemetryMetricsStatsd` GenServer which Telemetry events to respond to and how to treat each event as a specific type of metric.

We want to handle the `[:phoenix, :request]` event described above. First, let's consider what type of metrics we want to report for this event. Let's say we want to increment a counter for each such event, thereby keeping track of the number of requests our app receives to the endpoint. Let's also send a timing metric to report the duration of a given web request.

Now that we have a basic idea of what kind of metrics we want to construct and send to StatsD for our event, let's take a look at how `Telemetry.Metrics` allows us to define these metrics.

### Defining Our Metrics

The `Telemetry.Metrics` module provides a set of [five metrics functions](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html#module-metrics). These functions are responsible for formatting Telemetry event data as a given metric.

We'll use the `Telemetry.Metrics.counter/2` and the `Telemetry.Metrics.summary/2` functions to define our metrics for the given event.

In our `Quantum.Telemetry` module, which imports `Telemetry.Metrics`, we'll add the following to the `metrics` function:

```elixir
# lib/quantum/telemetry.ex
defp metrics do
  [
    summary(
      "phoenix.request.duration",
      unit: {:native, :millisecond},
      tags: [:request_path]
    ),

    counter(
      "phoenix.request.count",
      tags: [:request_path]
    )
  ]
end
```

Each metric function takes in two arguments:

* The event name
* A list of options

And returns a struct that describes the given metric type. For example, the `counter/2` function returns a [`%Telemetry.Metrics.Counter{}` struct](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.Counter.html#content) that looks like this:

```elixir
%Telemetry.Metrics.Counter{
  description: Telemetry.Metrics.description(),
  event_name: :telemetry.event_name(),
  measurement: Telemetry.Metrics.measurement(),
  name: Telemetry.Metrics.normalized_metric_name(),
  reporter_options: Telemetry.Metrics.reporter_options(),
  tag_values: (:telemetry.event_metadata() -> :telemetry.event_metadata()),
  tags: Telemetry.Metrics.tags(),
  unit: Telemetry.Metrics.unit()
}
```

Now that we've defined our metrics list, we're ready for the next step.

## Step 3: Start The `TelemetryMetricsStatsd` GenServer with the Metrics List

The list of metrics structs gets passed to the `TelemetryMetricsStatsd` GenServer when it gets started up:

```elixir
defmodule Quantum.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {TelemetryMetricsStatsd, metrics: metrics()} # here!
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics do
    [
      summary(
        "phoenix.request.duration",
        unit: {:native, :millisecond},
        tags: [:request_path]
      ),

      counter(
        "phoenix.request.count",
        tags: [:request_path]
      )
    ]
  end
end
```

This kicks off the following process:

* When the `TelemetryMetricsStatsd` starts, it stores events in ETS along with their handler _and_ a config map including this list of metric structs
* Later, when `TelemetryMetricsStatsd` is responding to executed events, it looks up the event in ETS and uses the metrics structs stored in that config map to format the appropriate metrics for sending to StatsD

### Seeing It In Action

Note that in our call to `counter/2` and `summary/2`, we're using the `:tag` option to specify which tags will be applied to the metric when it gets sent to StatsD. The `TelemetryMetricsStatsD` reporter will, when it receives our `[:phoenix, :request]` event, grab any values for the tag keys that are present in the event metadata and use them to construct the metric.

So, when we execute our Telemetry with the `conn` passed in as the metadata argument:

```elixir
# lib/quantum_web/controllers/user_controller.ex
def new(conn, _params) do
  :telemetry.execute([:phoenix, :request], %{duration: System.monotonic_time() - start}, conn)
end
```

The `TelemetryMetricsStatsD` will format a counter and summary metric tagged with the value of the `:request_path` key found in the `conn`.

So, if we run our app and send some web requests, we'll see the following metrics reported to StatsD:

```
{
  counters: {
    'phoenix.request.count.-register-new': 2,
  },
  timers: {
    'phoenix.request.count.-register-new': [ 0, 0 ],
  },
  timer_data: {
    'phoenix.request.duration.-register-new': {
      count_90: 2,
      mean_90: 0,
      upper_90: 0,
      sum_90: 0,
      sum_squares_90: 0,
      std: 0,
      upper: 0,
      lower: 0,
      count: 2,
      count_ps: 0.2,
      sum: 0,
      sum_squares: 0,
      mean: 0,
      median: 0
    }
  }
}
```

## Under The Hood

The `Quantum.Telemetry` module is, believe it or not, the _only_ code we have to write in order to send these metrics to StatsD for the `"phoenix.router_dispatch.stop"` event. The Telemetry libraries take care of everything else for us under the hood.

Let's take a closer look at how it all works.

1. The `Telemetry.Metrics` supervisor that we defined in `Quantum.Telemetry` defines a list of metrics that we want to emit to StatsD for a given Telemetry event
2. When the supervisor starts, it starts the `TelemetryMetricsStatsd` GenServer and gives it this list
3. When the `TelemetryMetricsStatsd` GenServer starts, it calls `:telemetry.attach/4` for each listed event, storing it in an ETS table along with the handler callback and a config map that includes the metrics definitions. The handler callback it gives to `:telemetry.attach/4` is its own `TelemetryMetricsStatsd.EventHandler.handle_event/4` function.
4. Later, when a Telemetry event is executed via a call to `:telemetry.execute/3`, Telemetry looks up the handler callback and config (including metrics definitions) for the given event in ETS
5. The `:telemetry.execute/3` function then calls this handler callback, `TelemetryMetricsStatsd.EventHandler.handle_event/4`, with the event name, event measurement map, event metadata and metrics config
6. The `TelemetryMetricsStatsd.EventHandler.handle_event/4` function formats the appropriate metric using all of this information and sends it to StatsD over UDP

Phew!

Let's take a deeper dive into this process by taking a look at some source code.


### `TelemetryMetricsStatsd` Attaches Events to Handlers and Config Data

When our supervisor starts the `TelemetryMetricsStatsd` GenServer, the GenServer's `init/1` function calls on [`TelemetryMetricsStatsd.EventHandler.attach/7`](https://github.com/beam-telemetry/telemetry_metrics_statsd/blob/master/lib/telemetry_metrics_statsd/event_handler.ex#L24) with a set of arguments that includes the metrics list we provided. This in turn executes a call to `:telemetry.attach/4`:

```elixir
# telemetry_metrics_statsd/lib/telemetry_metrics_statsd/event_handler.ex

def attach(metrics, reporter, mtu, prefix, formatter, global_tags) do
  metrics_by_event = Enum.group_by(metrics, & &1.event_name)

  for {event_name, metrics} <- metrics_by_event do
    handler_id = handler_id(event_name, reporter)

    :ok =
      :telemetry.attach(handler_id, event_name, &__MODULE__.handle_event/4, %{
        reporter: reporter,
        metrics: metrics,
        mtu: mtu,
        prefix: prefix,
        formatter: formatter,
        global_tags: global_tags
      })
  end
end
```

The call to `:telemetry.attach/4` will create an ETS entry that stores the event name along with the handler callback function,`&TelemetryMetricsStatsd.EventHandler.handle_event/4`, and a config map that contains the metrics definitions for the event.

### `TelemetryMetricsStatsd.EventHandler` Handles Executed Events

Later, the `[:phoenix, :request]` event is executed in our `UserController`:

```elixir
# lib/quantum_web/controllers/user_controller.ex
def new(conn, _params) do
  :telemetry.execute([:phoenix, :request], %{duration: System.monotonic_time() - start}, conn)
end
```

The `:telemetry.execute/3` function looks up the event in ETS. It fetches the handler callback function, along with the config that was stored for that event, including the list of metric definitions.

Telemetry will then call the callback function, `TelemetryMetricsStatsd.EventHandler.handle_event/4`, with the provided measurement map and metadata, along with stored config it looked up for the event in ETS.

`TelemetryMetricsStatsd.EventHandler.handle_event/4` will format the metric according to the metrics definitions stored in ETS for the event and send the resulting metric to StatsD.

Here we can see that the [`TelemetryMetricsStatsd.EventHandler.handle_event/4`](https://github.com/beam-telemetry/telemetry_metrics_statsd/blob/master/lib/telemetry_metrics_statsd/event_handler.ex#L46) iterates over the metric definitions for the event and constructs the appropriate metric from the event data using the given measurement and metadata maps along with the metric struct from the list of metrics stored in the config. It then publishes the metric to StatsD over UDP via the call to `publish_metrics/2`

```elixir
# telemetry_metrics_statsd/lib/telemetry_metrics_statsd/event_handler.ex

def handle_event(_event, measurements, metadata, %{
      reporter: reporter,
      metrics: metrics,
      mtu: mtu,
      prefix: prefix,
      formatter: formatter_mod,
      global_tags: global_tags
    }) do
  packets =
    # iterate over the stored metric definitions
    for metric <- metrics do
      # get the measurement for the metric type from the measurements map
      case fetch_measurement(metric, measurements) do
        {:ok, value} ->
          # collect metric tags specified in the metric struct
          tag_values =
            global_tags
            |> Map.new()
            |> Map.merge(metric.tag_values.(metadata))
          tags = Enum.map(metric.tags, &{&1, Map.fetch!(tag_values, &1)})
          # format the metric given the metric type, value and tags
          Formatter.format(formatter_mod, metric, prefix, value, tags)

        :error ->
          :nopublish
      end
    end
    |> Enum.filter(fn l -> l != :nopublish end)

  case packets do
    [] ->
      :ok

    packets ->
      # publish metrics to StatsD
      publish_metrics(reporter, Packet.build_packets(packets, mtu, "\n"))
  end
end
```

## Conclusion

The `Telemetry.Metrics` and `TelemetryMetricsStatsd` libraries make it even easier for us to handle Telemetry events and report metrics based on those events. All we have to do is define a Supervisor that uses `Telemetry.Metrics` and tell that Supervisor to start the `TelemetryMetricsStatsd` GenServer with a list of metric definitions.

That's it! The `TelemetryMetricsStatsd` library will take care of calling `:telemetry.attach/3` to store events in ETS along with a handler callback function and the metrics list for that event. Later, when a Telemetry event is executed, Telemetry will lookup the event and its associated handler function and metrics list and invoke the handler function with this data. The handler function, `TelemetryMetricsStatsd.EventHandler.handle_event/4`, will iterate over the list of metric structs that was stored for the event in ETS and construct the appropriate StatsD metric given the metric type and tags, the event measurement map and metadata. All for free!


## Next Up

In this post, we saw how `Telemetry.Metrics` and `TelemetryMetricsStatsd` abstracted away the need to define custom handlers and callback functions, attach those handlers to events and implement our own metric reporting logic. But our Telemetry pipeline still needs a little work.

We're still on the hook for emitting _all_ of our own Telemetry events.

In order to really be able to observe the state of our production Phoenix app, we need to be reporting on much more than just one endpoint's request duration and count. We want to be able to handle information-rich events describing web requests across the app, database queries, the behavior and state of the Erlang VM, the behavior and state of any workers in our app, and more.

Instrumenting all of that by hand, by executing custom Telemetry events wherever we need, them will be tedious and time-consuming. On top of that, it will be a challenge to standardize event naming conventions, measurements and metadata across the app.

In [next week's post](https://elixirschool.com/blog/instrumenting_phoenix_with_telemetry_part_three/), we'll examine Phoenix and Ecto's out-of-the-box Telemetry events and use `Telemetry.Metrics` to observe a wide-range of such events, thus eliminating the need for us to execute our own custom events for most of our observability use-cases.
