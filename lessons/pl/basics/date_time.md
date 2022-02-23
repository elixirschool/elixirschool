%{
  version: "1.2.0",
  title: "Data i czas",
  excerpt: """
  Obsługa czasu w Elixirze.
  """
}
---

## Time

Elixir ma kilka modułów związanych z reprezentacją i obsługą danych na temat czasu.
Zacznijmy od sprawdzenia aktualnego czasu:

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Zwróć uwagę na to, że jako wynik wywołanej funkcji otrzymaliśmy sigil — możemy go również użyć do stworzenia struktury `Time`:

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

O sigilach możesz przeczytać więcej w [lekcji na ten temat](/pl/lessons/basics/sigils).
W łatwy sposób możemy pobrać części składowe tej struktury:

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

I tu jest haczyk: co być może nie umknęło Twojej uwadze, struktura `Time` zawiera wyłącznie informacje o czasie, natomiast dane na temat dnia, miesiąca ani roku nie są w niej obecne.

## Date

W przeciwieństwie do `Time`, struktura `Date` zawiera informacje o dacie, jednak nie przechowuje danych na temat czasu.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

Moduł ten zawiera kilka użytecznych funkcji do pracy z datami:

```elixir
iex> {:ok, date} = Date.new(2020, 12, 12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` zwraca numer dnia tygodnia.
W powyższym przykładzie jest to sobota.
`leap_year?/1` sprawdza, czy dany rok jest przestępny.
Więcej funkcji możesz znaleźć w [dokumentacji](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

W Elixirze są dwa rodzaje struktur zawierających zarówno informację o dacie, jak i o czasie.
Pierwszym z nich jest `NaiveDateTime`.
Jego wadą jest brak danych o strefie czasowej:

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

Zawiera jednak i czas, i datę, więc możesz na przykład dodawać czas:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

Drugi moduł, jak możesz wnioskować z tytułu tej sekcji, to `DateTime`.
Nie ma on ograniczeń występujących w `NaiveDateTime` — zawiera czas i datę, a także obsługuje strefy czasowe.
Na strefy czasowe należy jednak uważać. Oficjalna dokumentacja stwierdza:

> Wiele funkcji w tym module wymaga bazy danych o strefach czasowych. Domyślnie używana jest baza zwracana przez funkcję `Calendar.get_time_zone_database/0`, domyślnie zwracającą `Calendar.UTCOnlyTimeZoneDatabase`, która obsługuje jedynie strefę "Etc/UTC" i zwraca `{:error, :utc_only_time_zone_database}` dla wszystkich innych stref czasowych.

Zauważyć należy również, że można utworzyć instancję DateTime z NaiveDateTime, przekazując do odpowiedniej funkcji informację o strefie czasowej:

```elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## Strefy czasowe

Jak zauważyliśmy w poprzedniej sekcji, domyślnie Elixir nie zawiera żadnych informacji o strefach czasowych.
Aby rozwiązać ten problem, możemy zainstalować i skonfigurować pakiet [tzdata](https://github.com/lau/tzdata).
Po zainstalowaniu go, należy globalnie skonfigurować Elixir tak, by używał Tzdata jako bazy danych o strefach czasowych:

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

Spróbujmy więc teraz stworzyć czas, używając strefy paryskiej, a następnie przekonwertować go na czas nowojorski:

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

Jak możesz zauważyć, godzina zmieniła się z 12:00 czasu paryskiego na 6:00 czasu nowojorskiego, co jest w pełni poprawne — różnica czasu między Nowym Jorkiem a Paryżem wynosi właśnie 6 godzin.

I to by było na tyle! Jeśli chcesz dowiedzieć się o zaawansowanych funkcjach związanych z czasem i datami, rozważ przeczytanie dokumentacji [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html) i [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html).
Warto zajrzeć również do bibliotek [Timex](https://github.com/bitwalker/timex) i [Calendar](https://github.com/lau/calendar), które są potęznymi narzędziami do pracy z czasem w Elixirze.
