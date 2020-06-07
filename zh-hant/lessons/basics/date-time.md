---
version: 1.1.0
title: 日期與時間
---

在 Elixir 中處理時間。

{% include toc.html %}

## Time

Elixir 有一些處理時間變化的模組。
現在從獲取目前時間開始：

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

注意，我們有一個可以用來建立一個 `Time` 結構體的符咒(sigil)：

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

可以在 [關於符咒的課程](../sigils) 中了解有關符咒的更多資訊。
存取這部分的結構體是很容易的：

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

但有一個問題：你可能已經注意到，這個結構體只包含一日內的時間，而沒有 日/月/年 資料可呈現。

## Date

與 `Time` 相反，`Date` 結構體只有目前日期的，而沒有目前時間的任何資訊。

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

不過它提供了些有用的函數來處理日期：

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` 計算給定日期是星期幾。
在這個範例中，它是星期六。
`leap_year?/1` 則檢查是否是閏年。
而其他功能可以在 [文件](https://hexdocs.pm/elixir/Date.html) 中找到。

## NaiveDateTime

在 Elixir 中有兩種結構體同時包含日期和時間。
兩種中的第一種是 `NaiveDateTime`。
缺點是缺少時區支援：

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```
 
不過它同時提供目前的時間和日期，所以可以玩時間相加，例如：

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

第二種，正如你可能從本節的標題中猜到的那樣，是 `DateTime`。
它沒有像 `NaiveDateTime` 提到的限制：它既有時間又有日期，並支援時區。
但請注意官方文件中的時區說明：

> 在本模組中的許多函數都需要一個時區資料庫。預設情況下，它使用 `Calendar.get_time_zone_database/0` 回傳的預設時區資料庫，資料庫預設為 `Calendar.UTCOnlyTimeZoneDatabase`，且只處理 Etc / UTC 日期時間，對其他時區則回傳 `{:error, :utc_only_time_zone_database}`。

另請注意，可以通過提供時區從 NaiveDateTime 建立 DateTime 實例：

```
iex> DateTime.
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## 處理時區

如上一章所說，預設情況下，Elixir 無任何時區資料。
要解決此問題，需要安裝並設定 [tzdata](https://github.com/lau/tzdata) 套件。
安裝之後，要在全域配置 Elixir 以便將 Tzdata 用作時區資料庫：

```
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

現在，試著在巴黎時區建立時間並將其轉換為紐約當地時間：

```
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

如你所見，時間從巴黎當地時間 12:00 改為 6:00，這是正確的 - 兩個城市之間的時差為 6 小時。

就是這個！如果使用其他進階函數，可能需要考慮進一步查看 [Time](https://hexdocs.pm/elixir/Time.html)、[Date](https://hexdocs.pm/elixir/Date.html)、[DateTime](https://hexdocs.pm/elixir/DateTime.html) 與 [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) 的文件。
同時還應該考慮 [Timex](https://github.com/bitwalker/timex) 和 [Calendar](https://github.com/lau/calendar) 這些強大並可以在 Elixir 中處理時間的函式庫。