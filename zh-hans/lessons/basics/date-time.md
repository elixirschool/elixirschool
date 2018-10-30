---
version: 1.0.0
title: Date and Time
---

Working with time in Elixir.

{% include toc.html %}

## Time

Elixir has some modules which work with time. Though it needs to be noted that this functionality is limited to working with UTC timezone.

Let's start with getting the current time:

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Note that we have a sigil which can be used to create a `Time` struct as well:

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

You can learn more about sigils in the [lesson about sigils](../sigils). It is easy to access parts of this struct:

```elixir
iex> t = ~T[19:39:31.056226]
~T[19:39:31.056226]
iex> t.hour
19
iex> t.minute
39
iex> t.day
** (KeyError) key :day not found in: ~T[19:39:31.056226]
```

But there is a catch: as you may have noticed, this struct only contains time within a day, no day/month/year data is present.

## Date

Contary to `Time`, `Date` struct has info about the current date, without any info about current time.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

But it has some useful functions to work with dates:

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` calculates which day of week would be the given date. In this case it's saturday. `leap_year?/1` checks whether this is a leap year. Other functions can be found in [doc](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

There are two kinds of structs which contain both date and time at once in Elixir.
First of two is `NaiveDateTime`. Its disadvantage is lack of timezone support:

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

But it has both the current time and date, so you can play with adding time, for example:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

The second one, as you may have guessed from title of this section, is `DateTime`.
It does not have the limitations noted previously: it has both time and date, and supports timezones. But note about timezones from the official doc:

```
You will notice this module only contains conversion functions as well as functions that work on UTC. This is because a proper DateTime implementation requires a time zone database which currently is not provided as part of Elixir.
```

Also, note that you can create a DateTime instance from the NaiveDateTime, just by providing the timezone:

```
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

This is it! If you want to work with other advanced functions you may want to consider looking futher into docs for [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html). You should also consider [Timex](https://github.com/bitwalker/timex) and [Calendar](https://github.com/lau/calendar) which are powerful libraries to work with time in Elixir.
