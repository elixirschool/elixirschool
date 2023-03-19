%{
  version: "1.2.0",
  title: "Date and Time",
  excerpt: """
  Working with time in Elixir.
  """
}
---

## Time

Elixir has some modules which work with time.
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

You can learn more about sigils in the [lesson about sigils](/en/lessons/basics/sigils).
It is easy to access parts of this struct:

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

But there is a catch: as you may have noticed, this struct only contains the time within a day, no day/month/year data is present.

## Date

Contrary to `Time`, a `Date` struct has info about the date, without any info about the time.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

And it has some useful functions to work with dates:

```elixir
iex> {:ok, date} = Date.new(2020, 12, 12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` calculates which day of the week a given date is on.
In this case it's Saturday.
`leap_year?/1` checks whether this is a leap year.
Other functions can be found in [doc](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

There are two kinds of structs which contain both date and time at once in Elixir.
The first is `NaiveDateTime`.
Its disadvantage is lack of timezone support:

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2022-01-21 19:55:10.008965]
```

But it has both the time and date, so you can play with adding time, for example:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

The second, as you may have guessed from the title of this section, is `DateTime`.
It does not have the limitations noted in `NaiveDateTime`: it has both time and date, and supports timezones.
But be aware about timezones. The official docs state:

> Many functions in this module require a time zone database. By default, it uses the default time zone database returned by `Calendar.get_time_zone_database/0`, which defaults to `Calendar.UTCOnlyTimeZoneDatabase` which only handles "Etc/UTC" datetimes and returns `{:error, :utc_only_time_zone_database}` for any other time zone.

Also, note that you can create a DateTime instance from the NaiveDateTime, just by providing the timezone:

```elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## Working with timezones

As we have noted in the previous section, by default Elixir does not have any timezone data.
To solve this issue, we need to install and set up the [tzdata](https://github.com/lau/tzdata) package.
After installing it, you should globally configure Elixir to use Tzdata as timezone database:

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

Let's now try creating time in Paris timezone and convert it to New York time:

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

As you can see, time changed from 12:00 Paris time to 6:00, which is correct - time difference between the two cities is 6 hours.

This is it! If you want to work with other advanced functions you may want to consider looking further into docs for [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html) and [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html)
You should also consider [Timex](https://github.com/bitwalker/timex) and [Calendar](https://github.com/lau/calendar) which are powerful libraries to work with time in Elixir.
