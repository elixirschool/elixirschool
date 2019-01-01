---
version: 1.0.0
title: 日付と時間
---

Elixirで時間を使ってみましょう。

{% include toc.html %}

## Time

Elixirは時間と連携するためのいくつかのモジュールを持っています。
ただし、この機能はUTCタイムゾーンとの連携に限定されている点に気をつける必要があります。

現在時刻の取得から始めてみましょう:

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

`Time`構造体を作るためにシギルを使用することもできる点に留意してください:

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

`Time`に対して、`Date`構造体は現在の日付に関する情報を持ち、現在の時間に関する情報は含みません。

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

しかし、これは日にちと連携する便利な関数をいくつか持っています:

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1`は与えられた日付がどの曜日にあたるのかを計算します。
この場合は土曜日です。
`leap_year?/1`は閏年かどうかをチェックします。
その他の関数は [doc](https://hexdocs.pm/elixir/Date.html) で探すことができます。

## NaiveDateTime

Elixirには日付と時間を同時に含む構造体が2種類あります。
そのうち1つは`NaiveDateTime`です。
この構造体のデメリットはタイムゾーンのサポートが無いという点です:

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

しかし、これは現在の時間と日付を両方持っているので、次の例のように時間を加算して遊ぶことができます:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

2つ目は、このセクションのタイトルから想像がつくように、`DateTime`です。
この構造体には前述したような制限はありません。そのため、これは時間と日付を両方持ち、タイムゾーンもサポートしています。
しかし公式ドキュメントにあるように、タイムゾーンについては注意してください:

```
このモジュールには変換関数とUTCで動作する関数だけが含まれていることに気付くでしょう。
これは、適切なDateTimeの実装には、現時点でElixirの機能として提供されていないタイムゾーンデータベースを必要とするためです。
```

また、タイムゾーンを提供するだけで、NaiveDateTimeからDateTimeのインスタンスを作ることができるという点について留意してください:

```
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

これがそうです！さらに高度な他の機能を使いたい場合は、 [Time](https://hexdocs.pm/elixir/Time.html) 、 [Date](https://hexdocs.pm/elixir/Date.html) 、 [DateTime](https://hexdocs.pm/elixir/DateTime.html) のドキュメントをさらに確認することを考慮するといいでしょう。
Elixirで時間を扱うパワフルなライブラリである [Timex](https://github.com/bitwalker/timex) と [Calendar](https://github.com/lau/calendar) についても考慮するべきです。
