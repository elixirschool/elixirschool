%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2020-05-13],
  tags: ["phoenix", "telemetry", "instrumenting"],
  title: "Instrumenting Phoenix with Telemetry Part IV: Erlang VM Measurements with `telemetry_poller`",
  excerpt: """
  In this series, we're instrumenting a Phoenix app and sending metrics to StatsD with the help of Elixir and Erlang's Telemetry offerings.
  In Part III we'll incorporate Erlang's `telemetry_poller` library into our Phoenix app so that we can observe and report on Erlang VM Telemetry events.
  """
}

---

## Table Of Contents

In this series, we're instrumenting a Phoenix app and sending metrics to StatsD with the help of Elixir and Erlang's Telemetry offerings.

* [Part I: Telemetry Under The Hood](https://elixirschool.com/blog/instrumenting-phoenix-with-telemetry-part-one/)
* [Part II: Handling Telemetry Events with `TelemetryMetrics` + `TelemetryMetricsStatsd`](https://elixirschool.com/blog/instrumenting_phoenix_with_telemetry_part_two/)
* [Part III: Observing Phoenix + Ecto Telemetry Events](https://elixirschool.com/blog/instrumenting_phoenix_with_telemetry_part_three/)
* Part IV: Erlang VM Measurements with `telemetry_poller`, `TelemetryMetrics` + `TelemetryMetricsStatsd`

## Intro

In [the previous post](https://elixirschool.com/blog/instrumenting_phoenix_with_telemetry_part_three/) we used `Telemetry.Metrics` to define metrics for a number of out-of-the-box Phoenix and Ecto Telemetry events and used `TelemetryMetricsStatsd` to handle and report those events to StatsD.

In this post, we'll incorporate Erlang's [`telemetry_poller` library](https://github.com/beam-telemetry/telemetry_poller) into our Phoenix app so that we can observe and report on Erlang VM Telemetry events.

## Getting Started

You can follow along with this tutorial by cloning down the repo [here](https://github.com/elixirschool/telemetry-code-along/tree/part-4-start).
* Checking out the starting state of our code on the branch [part-4-start](https://github.com/elixirschool/telemetry-code-along/tree/part-4-start)
* Find the solution code on the branch [part-4-solution](https://github.com/elixirschool/telemetry-code-along/tree/part-4-solution)

## Overview

In order to report on Erlang VM measurements as metrics, we will:

* Install the `telemetry_poller` dependency
* Define metrics for `telemetry_poller` Telemetry events using `Telemetry.Metrics`
* That's it!


## Step 1: Installing `telemetry_poller`

First, we'll include the `telemetry_poller` dependency in our app and run `mix deps.get`

```elixir
# mix.exs
def deps do
  {:telemetry_poller, "~> 0.4"}
end
```

## Step 2: Defining Metrics for `telemetry_poller` Events

### `telemetry_poller` Telemetry Events

When our app starts up, the `telemetry_poller` app will also start running. This app will poll the Erlang VM to take the following measurements and execute these measurements as Telemetry events:

* Memory - Measurement of the memory used by the Erlang VM
* Total run queue lengths - Measurement of the queue of tasks to be scheduled by the Erlang scheduler. This event will be executed with a measurement map describing:
  * `total` - a sum of all run queue lengths
  * `cpu` - a sum of CPU schedulers' run queue lengths
  * `io` - length of dirty IO run queue. It's always 0 if running on Erlang versions prior to 20.

* System count - Measurement of number of processes currently existing at the local node, the number of atoms currently existing at the local node and the number of ports currently existing at the local node
* Process info - A measurement with information about a given process, for example a worker in your application

Let's define metrics for some of these events in our `Quantum.Telemetry` module.

### Defining Our Metrics

The [`Telemetry.Metrics.last_value/2`](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html#last_value/2) function defines a metric that holds the value of the selected measurement from the most recent event. The `TelemetryMetricsStatsd` reporter will send such a metric to StatsD as a "gauge" metric. Let's define a set of gauge metrics for some of the Telemetry events mentioned above:

```elixir
# lib/quantum/telemetry.ex

defp metrics do
  [
    # VM Metrics - gauge
    last_value("vm.memory.total", unit: :byte),
    last_value("vm.total_run_queue_lengths.total"),
    last_value("vm.total_run_queue_lengths.cpu"),
    last_value("vm.system_counts.process_count")
  ]
end
```

Now, when `telemetry_poller` executes the corresponding events, we will see the following metrics to StatsD sent to StatsD:

```
gauges: {
  'vm.memory.total': 49670008,
  'vm.total_run_queue_lengths.total': 0,
  'vm.total_run_queue_lengths.cpu': 0,
  'vm.system_counts.process_count': 366
}
```

And that's it! Before we wrap up, let's take a look under the hood of the `telemetry_poller` library.

## `telemetry_poller` Under The Hood

Taking a look at some source code, we can see exactly how `telemetry_poller` is executing these events.

### The `memory/0` Function

The [`memory/0`](https://github.com/beam-telemetry/telemetry_poller/blob/master/src/telemetry_poller_builtin.erl#L22) function grabs memory measurements with a call to `erlang:memory/0` and passes those measurements to the call to `telemetry:execute/3` as the measurements map:

```erlang
% telemetry_poller/src/telemetry_poller_builtin.erl

memory() ->
    Measurements = erlang:memory(),
    telemetry:execute([vm, memory], maps:from_list(Measurements), #{}).
```

Let's break this down further. We can examine the measurements returned from the call to [`erlang:memory()`](http://erlang.org/doc/man/erlang.html#memory-0) by trying it out ourselves in `iex`:

```elixir
iex(1)> :erlang.memory()
[
  total: 28544704,
  processes: 5268240,
  processes_used: 5267272,
  system: 23276464,
  atom: 339465,
  atom_used: 317752,
  binary: 58656,
  code: 5688655,
  ets: 515456
]
```

We can see that is contains a key of `:total`, pointing to a value of the total amount of memory allocated to the Erlang VM.

Thus, a Telemetry event is executed with the name `[vm, memory]` and a set of measurements including this total. When we invoke our `Telemetry.Metrics.last_value/2` function, we are telling our reporter, `TelemetryStatsD`, to attach a handler for this event and to respond to it by constructing a gauge metric with the value of the `:total` key included in the provided measurements:

```elixir
# lib/quantum/telemetry.ex

defp metrics do
  [
    last_value("vm.memory.total", unit: :byte)
  ]
end
```

### The `total_run_queue_lengths/0` Function

The [`total_run_queue_lengths/0`](https://github.com/beam-telemetry/telemetry_poller/blob/master/src/telemetry_poller_builtin.erl#L27) function measures the total VM run queue length, as well as the total CPU schedulers' run queue length and passes those measurements to a call to `telemetry:execute/3`:

```erlang
% telemetry_poller/src/telemetry_poller_builtin.erl

total_run_queue_lengths() ->
    Total = cpu_stats(total),
    CPU = cpu_stats(cpu),
    telemetry:execute([vm, total_run_queue_lengths], #{
        total => Total,
        cpu => CPU,
        io => Total - CPU},
        #{}).
```

To observe this event, we are specifying that our Telemetry pipeline attach a handler for the `[vm, total_run_queue_lengths]` event and constructing two gauge metrics for every such event that is executed--one with the value of the `total` measurement and one with the value of the `cpu` measurement:

```elixir
# lib/quantum/telemetry.ex

defp metrics do
  [
    last_value("vm.total_run_queue_lengths.total"),
    last_value("vm.total_run_queue_lengths.cpu")
  ]
end
```

### The `system_counts/0` Function

The [`system_counts/0`](https://github.com/beam-telemetry/telemetry_poller/blob/master/src/telemetry_poller_builtin.erl#L42) function takes measurements including the total process count and executes a Telemetry event with these measurements via a call to `telemetry:execute/3`:

```erlang
system_counts() ->
    ProcessCount = erlang:system_info(process_count),
    PortCount = erlang:system_info(port_count),
    telemetry:execute([vm, system_counts], #{
        process_count => ProcessCount,
        port_count => PortCount
    }).
```

To observe this event, we are specifying that our Telemetry pipeline attach a handler for the `[vm, system_counts]` event and construct a gauge metric with the value of the `process_count` measurement for every such event:

```elixir
# lib/quantum/telemetry.ex

defp metrics do
  [
    last_value("vm.system_counts.process_count")
  ]
end
```


## Polling for Custom Measurements

You can also use the `telemetry_poller` library to emit measurements describing custom processes or workers running in your app, or to emit custom measurements. See the docs [here](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html#module-vm-metrics) for more info.

## Conclusion

Once again we've seen that Erlang and Elixir's family of Telemetry libraries make it easy for us to achieve fairly comprehensive instrumentation with very little hand-rolled code. By adding the `telemetry_poller` library to our dependencies, we're ensuring our application will execute a set of Telemetry events describing Erlang VM measurements at regular intervals. We're observing these events, formatting them and sending them to StatsD with the help of `Telemetry.Metrics` and `TelemetryMetricsStatsd`, allowing us to paint an even fuller picture of the state of our Phoenix app at any given time.
