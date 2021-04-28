---
version: 1.1.1
title: Date et Heure
---

Travailler avec le temps en Elixir.

{% include toc.html %}

## Time

Elixir a plusieurs modules qui ont trait au temps.
Commençons par récupérer l'heure actuelle :

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Notez que nous avons un _sigil_ qui peut également être utilisé pour créer une structure `Time` :

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

Vous pouvez en apprendre plus sur les _sigils_ dans la [leçon sur les sigils](../sigils).
Il est facile d'accéder aux différentes parties de la `struct` :

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

Cependant il y a un hic : comme vous l'avez peut-être remarqué, cette `struct` contient uniquement l'heure à l'intérieur d'une journée, elle ne contient aucune donnée sur le jour, le mois ou l'année.

## Date

Contrairement à `Time`, la structure `Date` a les informations sur la date courante sans aucune information par rapport à l'heure courante.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

Et il a quelques fonctions utiles pour travailler avec les dates :

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` calcule à quel jour de la semaine correspond une date donnée.
Dans l'exemple ci-dessus, c'est samedi.
`leap_year?/1` vérifie si l'année associée à la date est bissextile.
Les autres fonctions peuvent être trouvées dans la [documentation en ligne d'Elixir](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

Il y a deux sortes de structures qui contiennent en même temps date et heure en Elixir.
La première est `NaiveDateTime`.
Son inconvénient est qu'elle n'offre pas le support des fuseaux horaires.

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

Cependant, elle contient à la fois l'heure courante et la date, vous pouvez ainsi vous amusez à ajouter l'heure, par exemple :

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

La seconde, comme vous l'avez peut-être deviné d'après le titre de cette section, est `DateTime`.
Elle n'a pas les limitations relevées pour `NaiveDateTime`: elle possède à la fois heure et date, et supporte les fuseaux horaires.
Néanmoins, soyez avertis à propos des fuseaux horaires. La documentation officielle déclare :

> De nombreuses fonctions dans ce module requiert une base de données de fuseau horaire. Faute de quoi, elles utilisent le fuseau horaire par défaut retourné par `Calendar.get_time_zone_database/0`, dont la valeur par défaut est `Calendar.UTCOnlyTimeZoneDatabase` qui gère seulement le format date/heure "Etc/UTC" et retourne `{:error, :utc_only_time_zone_database}` pour tout autre fuseau horaire.

Notez également que vous pouvez créez une instance de `DateTime` à partir d'une instance de `NaiveDateTime`, en fournissant simplement le fuseau horaire :

```elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## Working with timezones

Comme noté dans la section précédente, de base Elixir n'a aucune donnée relative aux fuseaux horaires. 
Pour répondre à cette problématique, nous devons installer et configurer la librairie [tzdata](https://github.com/lau/tzdata).
Après l'avoir installé, vous devez configurer Elixir globalement pour utiliser _Tzdata_ comme base de données de fuseaux horaires :

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

Essayons maintenant de créer une date avec heure pour le fuseau horaire de Paris et de la convertir en une date avec heure dans le fuseau horaire de New York :

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

Comme vous pouvez le voir, l'heure est passée de 12:00 pour le fuseau horaire parisien à 6:00, ce qui est correct - il y a bien une différence de 6 heures entre les deux villes.

Ca y est ! Si vous voulez travailler avec des fonctions plus avancées, vous voudrez peut-être regarder de manière plus approfondie la documentation pour [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html) et [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html)
Vous pourriez également considérer [Timex](https://github.com/bitwalker/timex) et [Calendar](https://github.com/lau/calendar) qui sont de puissantes bibliothèques pour travailler avec le temps en Elixir.
