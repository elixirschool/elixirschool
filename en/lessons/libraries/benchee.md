---
version: 1.0.1
title: Benchee
redirect_from:
  - /lessons/libraries/benchee/
---

We can't just guess about which functions are fast and which are slow - we need actual measurements when we're curious. That's where benchmarking comes in. In this lesson, we'll learn about how easy it is to measure the speed of our code.

{% include toc.html %}

# About Benchee 

While there is a [function in Erlang](http://erlang.org/doc/man/timer.html#tc-1) that can be used for very basic measurement of a function's execution time, it's not as nice to use as some of the available tools and it doesn't give you multiple measurments to get good statistics from, so we're going to use [Benchee](https://github.com/PragTob/benchee). Benchee provides us with a range of statistics with easy comparisons between scenarios, a great feature that allows us to test different inputs to the functions we're benchmarking, and several different formatters that we can use to display our results, as well as the ability to write your own formatter if desired.

# Usage 

To add Benchee to your project, add it as a dependency to your `mix.exs` file:
```elixir
defp deps do
  [{:benchee, "~> 0.9", only: :dev}]
end
```
Then we call:

```shell
$ mix deps.get
...
$ mix compile
```

The first command will download and install Benchee. You may be asked to install Hex along with it. The second compiles the Benchee application. Now we're ready to write our first benchmark!

**An important note before we begin:** When benchmarking, it is very important to not use `iex` since that behaves differently and is often much slower than how your code is most likely being used in production. So, let's create a file that we're calling `benchmark.exs`, and in that file we'll add the following code:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})
```

Now to run our benchmark, we call:

```shell
$ mix run benchmark.exs
```

And we should see something like the following output in your console:

```shell 
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: none specified
Estimated total run time: 14.00 s


Benchmarking flat_map...
Benchmarking map.flatten...

Name                  ips        average  deviation         median
flat_map           1.03 K        0.97 ms    ±33.00%        0.85 ms
map.flatten        0.56 K        1.80 ms    ±31.26%        1.60 ms

Comparison:
flat_map           1.03 K
map.flatten        0.56 K - 1.85x slower
```

Of course your system information and results may be different depending on the specifications of the machine you are running your benchmarks on, but this general information should all be there.

At first glance, the `Comparison` section shows us that our `map.flatten` version is 1.85x slower than `flat_map` - very helpful to know! But let's look at the other statistics that we get:

* **ips** - this stands for "iterations per second," which tells us how often the given function can be executed in one second. For this metric, a higher number is better.
* **average** - this is the average execution time of the given function. For this metric, a lower number is better.
* **deviation** - this is the standard deviation, which tells us how much the results for each iteration varies in the results. Here it is given as a percentage of the average.
* **median** - when all measured times are sorted, this is the middle value (or average of the two middle values when the number of samples is even). Because of environmental inconsistencies this will be more stable than the `average`, and somewhat more likely to reflect the normal performance of your code in production. For this metric, a lower number is better.

There are also other available statistics, but these four are frequently the most helpful and commonly used for benchmarking, which is why they are displayed in the default formatter. To learn more about the other available metrics, check out the documentation on [hexdocs](https://hexdocs.pm/benchee/Benchee.Statistics.html#statistics/1).

# Configuration

One of the best parts of Benchee is all the available configuration options. We'll go over the basics first since they don't require code examples, and then we'll show how to use one of the best features of Benchee - inputs.

## Basics
Benchee takes a wealth of configuration options. In the most common `Benchee.run/2` interface, these are passed as the second argument in the form of an optional keyword list:

```elixir
Benchee.run(%{"example function" => fn -> "hi!" end}, [
  warmup: 4,
  time: 10,
  inputs: nil,
  parallel: 1,
  formatters: [&Benchee.Formatters.Console.output/1],
  print: [ 
    benchmarking: true,
    configuration: true,
    fast_warning: true
  ],
  console: [
    comparison: true,
    unit_scaling: :best
  ]
])
```

The available options are the following (also documented in [hexdocs](https://hexdocs.pm/benchee/Benchee.Configuration.html#init/1)).

* **warmup** - the time in seconds for which a benchmarking scenario should be run without measuring times before real measurements start. This simulates a "warm" running system. Defaults to 2.
* **time** - the time in seconds for how long each individual benchmarking scenario should be run and measured. Defaults to 5.
* **inputs** - a map with strings representing the input name as the keys and the actual input as the values. Defaults to `nil`. We'll cover this in detail in the next section.
* **parallel** - the number of processes to use to benchmark your functions. So, if you set `parallel: 4`, then 4 processes will be spawned that all execute the same function for the given `time`. When these finish, then 4 new processes will be spawned for the next function. This gives you more data in the same time, but also puts a load on the system interfering with benchmark results. This can be useful to simulate a system under load which is sometimes helpful, but should be used with some caution as this can affect results in unpredictable ways. Defaults to 1 (which means no parallel execution). 
* **formatters** - a list of formatter functions you'd like to run to output the benchmarking results of the suite when using `Benchee.run/2`. Functions need to accept one argument (which is the benchmarking suite with all data) and then use that to produce output. Defaults to the builtin console formatter calling `Benchee.Formatters.Console.output/1`. We'll cover this more in a later section.
* **print** - a map or keyword list with the following options as atoms for the keys and values of either `true` or `false`. This lets us control if the output identified by the atom will be printed during the standard benchmarking process. All options are enabled by default (true). Options are:
  * **benchmarking** - print when Benchee starts benchmarking a new job.
  * **configuration** - a summary of configured benchmarking options including estimated total run time is printed before benchmarking starts.
  * **fast_warning** - warnings are displayed if functions are executed too fast, potentially leading to inaccurate measures.
* **console** - a map or keyword list with the following options as atoms for the keys and variable values. The available values are listed under each option:
  * **comparison** - if the comparison of the different benchmarking jobs (x times slower than) is shown. Defaults to `true`, but can also be set to `false`.
  * **unit_scaling** - the strategy for choosing a unit for durations and counts. When scaling a value, Benchee finds the "best fit" unit (the largest unit for which the result is at least 1). For example, `1_200_000` scales to 1.2 M, while `800_000` scales to 800 K. The unit scaling strategy determines how Benchee chooses the best fit unit for an entire list of values, when the individual values in the list may have different best fit units. There are four strategies, all given as atoms, defaulting to `:best`:
    * **best** - the most frequent best fit unit will be used. A tie will result in the larger unit being selected.
    * **largest** - the largest best fit unit will be used
    * **smallest** - the smallest best fit unit will be used
    * **none** - no unit scaling will occur. Durations will be displayed in microseconds, and ips counts will be displayed without units.

## Inputs

It's very important to benchmark your functions with data that reflects what that function might actually operate on in the real world. Frequently a function can behave very differently on small sets of data versus large sets of data! This is where Benchee's `inputs` configuration option comes in. This allows you to test the same function but with as many different inputs as you like, and then you can see the results of the benchmark with each of those functions.

So, let's look at our original example again:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})
```

In that example we're only using a single list of the integers from 1 to 10,000. Let's update that to use a couple different inputs so we can see what happens with smaller and larger lists. So, open that file, and we're going to change it to look like this:

```elixir
map_fun = fn i -> [i, i * i] end

inputs = %{
  "small list" => Enum.to_list(1..100),
  "medium list" => Enum.to_list(1..10_000),
  "large list" => Enum.to_list(1..1_000_000)
}

Benchee.run(
  %{
    "flat_map" => fn list -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn list -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  inputs: inputs
)
```

You'll notice two differences. First, we now have an `inputs` map that contains the information for our inputs to our functions. We're passing that inputs map as a configuration option to `Benchee.run/2`.

And since our functions need to take an argument now, we need to update our benchmark functions to accept an argument, so instead of:
```elixir
fn -> Enum.flat_map(list, map_fun) end
```

we now have:
```elixir
fn list -> Enum.flat_map(list, map_fun) end
```

Let's run this again using:

```shell
$ mix run benchmark.exs
```

Now you should see output in your console like this:

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: large list, medium list, small list
Estimated total run time: 2.10 min

Benchmarking with input large list:
Benchmarking flat_map...
Benchmarking map.flatten...

Benchmarking with input medium list:
Benchmarking flat_map...
Benchmarking map.flatten...

Benchmarking with input small list:
Benchmarking flat_map...
Benchmarking map.flatten...


##### With input large list #####
Name                  ips        average  deviation         median
flat_map             6.29      158.93 ms    ±19.87%      160.19 ms
map.flatten          4.80      208.20 ms    ±23.89%      200.11 ms

Comparison:
flat_map             6.29
map.flatten          4.80 - 1.31x slower

##### With input medium list #####
Name                  ips        average  deviation         median
flat_map           1.34 K        0.75 ms    ±28.14%        0.65 ms
map.flatten        0.87 K        1.15 ms    ±57.91%        1.04 ms

Comparison:
flat_map           1.34 K
map.flatten        0.87 K - 1.55x slower

##### With input small list #####
Name                  ips        average  deviation         median
flat_map         122.71 K        8.15 μs   ±378.78%        7.00 μs
map.flatten       86.39 K       11.58 μs   ±680.56%       10.00 μs

Comparison:
flat_map         122.71 K
map.flatten       86.39 K - 1.42x slower
```

We can now see information for our benchmarks, grouped by input. This simple
example doesn't provide any mind blowing insights, but you'd be very surprised
how much performance varies based on input size!

# Formatters

The console output that we've seen is a helpful beginning for measuring the
runtimes of your functions, but it's not your only option! In this section we'll
look briefly at the three other available formatters, and also touch on what
you'd need to do to write your own formatter if you like.

## Other formatters

Benchee has a console formatter built in, which is what we've seen already, but
there are three other officially supported formatters - `benchee_csv`,
`benchee_json` and `benchee_html`. Each of them does exactly what you would
expect, which is writing the results to the named file formats so you can work
with your results further in whichever format you like.

Each of these formatters is a separate package, so to use them you need to add
them as dependencies to your `mix.exs` file like so:

```elixir
defp deps do
  [
    {:benchee_csv, "~> 0.6", only: :dev},
    {:benchee_json, "~> 0.3", only: :dev},
    {:benchee_html, "~> 0.3", only: :dev}
  ]
end
```

While `benchee_json` and `benchee_csv` are very simple, `benchee_html` is actually _very_ full featured! It can help you produce nice graphs and charts from your results easily, and you can even export them as PNG images. All three formatters are well-documented on their respective GitHub pages, so we won't cover the details of them here.

## Custom formatters

If the four offered formatters aren't enough for you, you can also write your own formatter. Writing a formatter is pretty easy. You need to write a function that accepts a `%Benchee.Suite{}` struct, and from that you can pull whatever information you like. Information about what exactly is in this struct can be found on [GitHub](https://github.com/PragTob/benchee/blob/master/lib/benchee/suite.ex) or [HexDocs](https://hexdocs.pm/benchee/Benchee.Suite.html). The codebase is very well-documented and easy to read if you'd like to see what sorts of information could be available for writing custom formatters.

For now, I'll show a quick example of what a custom formatter might look like below as an example of how easy it is. Let's say we just want an extremely minimal formatter that just prints the average run time for each scenario - this is what that might look like:

```elixir
defmodule Custom.Formatter do
  def output(suite) do
    suite
    |> format
    |> IO.write()

    suite
  end

  defp format(suite) do
    Enum.map_join(suite.scenarios, "\n", fn scenario ->
      "Average for #{scenario.job_name}: #{scenario.run_time_statistics.average}"
    end)
  end
end
```

And then we could run our benchmark like this:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  formatters: [&Custom.Formatter.output/1]
)
```

And when we run now with our custom formatter, we would see:

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: none specified
Estimated total run time: 14.00 s


Benchmarking flat_map...
Benchmarking map.flatten...
Average for flat_map: 851.8840109326956
Average for map.flatten: 1659.3854339873628
```
