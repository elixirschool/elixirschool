---
version: 1.1.0
title: Fecha y Hora
---

Trabajando con tiempos en Elixir.

{% include toc.html %}

## Hora (`Time`)

Elixir tiene algunos módulos que trabajan con tiempo.
Empecemos por obtener la hora actual:

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Observa que también tenemos un sigilo que puede ser usado para crear una estructura `Time`:

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

Puedes aprender más acerca de los sigilos en la [lección acerca de los sigilos](../sigils/).
Es fácil acceder a partes de esta estructura:

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

Pero hay un problemita: como te habrás dado cuenta, esta estructura sólo contine la hora del día, no hay datos acerca del día, mes o año.

## Fecha (`Date`)

Al contrario de `Time`, la estructura `Date` tiene información acerca de la fecha actual, sin información acerca de la hora.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

Pero tiene algunas funciones útiles para trabajar con fechas:

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` calcula que día de la semana fue una fecha dada. En este caso es sábado.
`leap_year?/1` verifica si es un año bisiesto.
Otras funciones pueden ser encontradas en la [documentación](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

En Elixir existen dos tipos de estructuras que contienen tanto la hora como la fecha al mismo tiempo.
La primera es `NaiveDateTime`.
Su desventaja es la falta de soporte para la zona horaria: 

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

Pero tiene tanto la hora como la fecha actuales, así que puedes jugar añadiéndole tiempo, por ejemplo:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

La segunda, como habrás adivinado por el título de la sección, es `DateTime`.
No tiene las limitaciones que observamos previamente en `NaiveDateTime`: tiene tanto la fecha como la hora y soporta zonas horarias.
Pero utiliza con cuidado las zonas horarias. La documentación dice:

> Varias funciones en este módulo requieren una base de datos de zonas horarias. Por defecto, utiliza la base de datos por defecto que regresa `Calendar.get_time_zone_database/0`, que a su vez está predeterminada a `Calendar.UTCOnlyTimeZoneDatabase` que solo trabaja con fechas y horas en "Etc/UTC" y regresa el error `{:error, :utc_only_time_zone_database}` para cualquier otra zona horaria.

Además, nota que puedes crear una instacia `DateTime` a partir de una instancia `NaiveDateTime`, sólo con proveer la zona horaria:

```elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## Trabajando con zonas horarias

Como vimos en el capítulo anterior, Elixir no tiene información de zonas horarias por defecto.
Para resolver esa situación, necesitamos instalar el paquete [tzdata](https://github.com/lau/tzdata).
Tras instalarlo, debes configurar Elixir de manera global para utilizar Tzdata como la base de datos de zonas horarias:

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

Ahora intentemos instanciar un tiempo con la zona horaria de París y convertirlo al tiempo en Nueva York:

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

Como podrás ver, el tiempo cambió de las 12:00 en París, a las 6:00, lo que es correcto - la diferencia entre esas dos ciudades es de 6 horas.

¡Eso es todo! Si quieres trabajar con otras funciones avanzadas deberías considerar revisar la documentación de [Time](https://hexdocs.pm/elixir/Time.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html) y [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html).
También deberías considerar [Timex](https://github.com/bitwalker/timex) y [Calendar](https://github.com/lau/calendar) que son poderosas bibliotecas para trabajar con tiempo en Elixir.
