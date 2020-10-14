---
version: 1.1.0
title: Datum a Čas
---

Práce s časem v Elixíru.

{% include toc.html %}

## Čas

Elixír má několik modulů, které pracují s časem.
Začněme s tím jaký je momentální čas.

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Na vytvoření času existuje i sigil, ten vytvoří `Time` strukturu:

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

Můžete se o sigils dozvědět více zde [lesson about sigils](../sigils).
Je to jednoduché přistoupit k části této struktury:

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

Ale je zde háček: jak jste jistě zaznamenali, tahle struktura obsahuje pouze čas v rámci dne, data za den/měsíc/rok nejsou přítomna.

## Datum

Podobně jako `Time` je `Date` struktura která má info o současném datumu, bez informací o současném čase.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

A má několik užitečných funkcí na práci s nimi:

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` vypočítá který den v týdnu je pro dané datum.
V tomhle případě Saturday/Sobota.
`leap_year?/1` zkontorluje jestli je tenhle rok přestupný.
Další funkce můžete najít zde [doc](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

V Elixíru jsou dva typy struktur, které obsahují datum a čas v jednom.
První je `NaiveDateTime`.
Její nedostatek je nepodpora časových pásem:

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```
Ale má jak současný čas tak i datum, takže si můžete hrát a přidávat čas, například:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

Druhá, jak jste již s názvu odhadli, je `DateTime`.
Nemá limitace jaké má `NaiveDateTime`: má i čas tak i datum a podporuje časové pásma.
Ale buďte obezřetní. Oficiální dokumentace říká:

> Many functions in this module require a time zone database. By default, it uses the default time zone database returned by `Calendar.get_time_zone_database/0`, which defaults to `Calendar.UTCOnlyTimeZoneDatabase` which only handles "Etc/UTC" datetimes and returns `{:error, :utc_only_time_zone_database}` for any other time zone.

Je taky možné vytvořit DateTime instanci z NaiveDateTime a to pouze poskytnutím časového pásma:

```
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## Práce s časovými pásmy

Jak bylo zmíněno v předchozí kapitole, Elixír nemá ze základu podporu pro časové pásma. 
K vyřešení tohoto problému potřebujeme nainstalovat a nastavit balíček [tzdata](https://github.com/lau/tzdata).
Po jeho instalaci bychom ho měli globálně nastavit v konfiguračním souboru, jako databázi s časovými pásmy:

```
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

Zkusme teď vytvořit čas v Pařížském časovém pásmu a konvertovat jej do New Yorského:

```
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

Jak můžete vidět, čas se změnil z 12:00 Paříského času na 6:00, což je správně - časový rozdíl mezi těmito dvěma městy je 6 hodin.

This is it! If you want to work with other advanced functions you may want to consider looking futher into docs for [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html) and [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html)
You should also consider [Timex](https://github.com/bitwalker/timex) and [Calendar](https://github.com/lau/calendar) which are powerful libraries to work with time in Elixir.
