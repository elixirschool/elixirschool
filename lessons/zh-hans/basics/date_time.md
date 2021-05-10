---
version: 1.1.0
title: 日期和时间
---

Elixir 中有关时间和日期的处理

{% include toc.html %}

## Time

Elixir 内置了几个处理时间的模块。 首先，我们可以获取当前的 UTC 时间：

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

我们也可以通过魔符 `~T` 来创建时间 `Time` ：

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

[魔符](../sigils) 一课中有更多关于魔符的介绍。

下面的例子展示了从一个 `Time` 结构体中获取时分秒等部分的方法：

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

你也许已经注意到了，`Time` 结构中只有在一天内的时间信息，没有具体的某天，某月，某日的信息。

## Date

与 `Time` 相对的是 `Date` 结构体，它只有日期的信息，而没有时间的信息。

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

`Date` 模块有一些实用的日期处理函数：

```elixir
iex> {:ok, date} = Date.new(2020, 12, 12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` 计算某天是一个星期中的第几天。上面的例子中的日期是星期六。 `leap_year?/1` 检查某天的年份是不是一个闰年。更多有关日期的函数请参考[文档](https://hexdocs.pm/elixir/Date.html)。

## NaiveDateTime

Elixir 中有两中结构体既包含时间信息，又包含日期信息。我们首先来看 `NaiveDateTime`。 它的一个不足是缺少时区的信息。

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

但是因为它同时有时间和日期，所以你可以对它进行时间的运算，下面的例子展示了对一个 `NaiveDateTime` 结构加 30 秒的操作：

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

你可能已经猜到了，Elixir 内置的第二个既有时间，又有日期的模块是 `DateTime`，而且它还有时区的信息。它没有 `NaiveDateTime` 的那些限制。需要注意的是，有关时区，官方文档做的特别的说明：

```
本模块只包括了一些转换函数和处理 UTC 的函数。这是因为要完整实现 DateTime 需要一个时区数据库，但是目前 Elixir 还未提供此数据库。
```

> Many functions in this module require a time zone database. By default, it uses the default time zone database returned by `Calendar.get_time_zone_database/0`, which defaults to `Calendar.UTCOnlyTimeZoneDatabase` which only handles "Etc/UTC" datetimes and returns `{:error, :utc_only_time_zone_database}` for any other time zone.

另外，你也可以通过一个 `NaiveDateTime` 的值来创建一个 `DateTime`，只需要通过 `from_naive/2` 加上时区信息即可：

```
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## 处理时区

上文提到 Elixir 默认并不包括任何时区数据。我们可以通过安装 [tzdata](https://github.com/lau/tzdata) 来解决这个问题。

安装好 tzdata 之后，你需要一个全局配置让 Elixir 去使用 Tzdata 作为时区数据库：

```
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

下面我们试着创建一个巴黎时间，并把它转为北京时间：

```
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, china_datetime} = DateTime.shift_zone(paris_datetime, "Asia/Shanghai")
{:ok, #DateTime<2019-01-01 19:00:00+08:00 CST Asia/Shanghai>}
iex> china_datetime
#DateTime<2019-01-01 19:00:00+08:00 CST Asia/Shanghai>
```

这样，我们就把巴黎时间的 12:00 转成了北京时间的 19:00。

如果你想了解更多有关时间，日期的更高级的用法，请参考这些文档： [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html)。你也可以考虑 [Timex](https://github.com/bitwalker/timex) 和 [Calendar](https://github.com/lau/calendar) 。它们都是很强大的处理时间的库。
