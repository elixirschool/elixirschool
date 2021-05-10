%{
  version: "1.1.1",
  title: "日付と時間",
  excerpt: """
  Elixirで時間を扱ってみましょう。
  """
}
---

## Time

Elixirは時間を扱うためのいくつかのモジュールを持っています。
現在時刻の取得から始めてみましょう:

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

`Time` 構造体を作るためにシギルも使えます:

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

シギルについては [シギルのレッスン](../sigils) で詳細を学ぶことができます。
この構造体の各値にアクセスするのは簡単です:

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

しかし、ここには落とし穴があります。気が付いたかもしれませんが、この構造体は1日の時間のみを含んでいて、日/月/年のデータはありません。

## Date

`Time` に対して、 `Date` 構造体は現在の日付に関する情報を持ち、現在の時間に関する情報は含みません。

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

それから、これは日にちと連携する便利な関数をいくつか持っています:

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` は与えられた日付がどの曜日にあたるのかを計算します。
この場合は土曜日です。
`leap_year?/1` は閏年かどうかをチェックします。
その他の関数は [doc](https://hexdocs.pm/elixir/Date.html) で探すことができます。

## NaiveDateTime

Elixirには日付と時間を同時に含む構造体が2種類あります。
最初に紹介するのは `NaiveDateTime` です。
この構造体のデメリットはタイムゾーンのサポートが無いという点です:

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

しかし、これは現在の時間と日付を両方持っているので、次の例のように時間を足すことも可能です:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

2つ目は、このセクションのタイトルから想像がつくように、 `DateTime` です。
`NaiveDateTime` で記載したような制限はありません。そのため、これは時間と日付を両方持ち、タイムゾーンもサポートしています。
しかしタイムゾーンについては注意してください。公式ドキュメントではこのように記載されています:

> このモジュールの多くの機能には、タイムゾーンデータベースが必要です。デフォルトでは `Calendar.get_time_zone_database/0` によって返されるデフォルトのタイムゾーンデータベースを使います。デフォルトでは `Calendar.UTCOnlyTimeZoneDatabase` で、 "Etc/UTC"のみを処理し、他のタイムゾーンでは `{:error, :utc_only_time_zone_database}` を返します。

また、タイムゾーンを提供するだけで、NaiveDateTimeからDateTimeのインスタンスを作ることができます:

```elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## タイムゾーンの利用
前の章で述べたように、Elixir本体にはタイムゾーンデータがありません。
この問題を解決するには、[tzdata](https://github.com/lau/tzdata) パッケージをインストールして設定する必要があります。
それをインストールした後、Tzdataをタイムゾーンデータベースとして使用するように、Elixirにグローバル設定をする必要があります。

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

パリのタイムゾーンで時間を作成して、それをニューヨーク時間に変換してみましょう。

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

ご覧のとおり、時刻はパリの12:00から6:00に変更されました。これは正しいです。2つの都市の時差は6時間です。

これがそうです！さらに高度な他の機能を使いたい場合は、 [Time](https://hexdocs.pm/elixir/Time.html) 、 [Date](https://hexdocs.pm/elixir/Date.html) 、 [DateTime](https://hexdocs.pm/elixir/DateTime.html)、 [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) のドキュメントをさらに確認することを考慮するといいでしょう。
Elixirで時間を扱うパワフルなライブラリである [Timex](https://github.com/bitwalker/timex) と [Calendar](https://github.com/lau/calendar) についても考慮するべきです。
