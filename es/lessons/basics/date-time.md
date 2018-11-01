---
version: 1.0.0
title: Fecha y Hora
---

Trabajando con tiempos en Elixir.

{% include toc.html %}

## Hora(`Time`)

Elixir tiene algunos módilos que trabajan con tiempo. Aunque es necesario nottar que esta funcionalidad está limitada a trabajar con la zona horaria UTC.

Empecemos obteniendo la hora actual:


```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Observa que también tenemos un sigil que puede ser usado para crear un estructura `Time`:

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

Puedes aprender más acerca de los sigils en la [lección acerca de los sigils](../sisgils/). Es fácil acceder a partes de esta estructura:

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

Pero hay problemita: como te habrás dado cuenta, esta estructura sólo contine la hora del día, no hay datos acerca del día, mes o año.

## Fecha(`Date`)

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

`day_of_week/1` calcula que día de la semana cayó una fecha dada. En este caso es sábado. `leap_year?/1` verifica si es un año bisiesto. Otras funciones pueden ser encontradas en la [documentación](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

En Elixir existen dos tipos de estructuras que contienen tanto la hora como la fecha al mismo tiempo.
La primera es `NaiveDateTime`. Su desventaja es la falta de soporte para la zona horaria: 

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

Pero tiene tanto la hora como el la fecha actuales, así que puedes jugar añadiéndole tiempo, por ejemplo:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

La segunda, coomo habrás adivinado por el título de la sección es `DateTime`.
No tiene las limitaciones observadas previamente: tiene tanto la fecha como la hora y soporta zonas horarias. Pero veamos lo que dice la documentación oficial acerca de las zonas horarias:

```
Te darás cuenta que este módulo sólo contiene funciones de conversión así como funciones que trabajan con UTC. Esto se debe a que una implementación correcta de Datetime requiere una base de datos de zonas horarias que no se provee como parte de Elixir.
```

Además, nota que puedes crear una instacia `DateTime` de una instancia `NaiveDateTime` sólo con proveer la zona horaria:

```
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

¡Eso es todo! Si quieres trabajar con otras funciones avanzadas quizás quieras ver la documentación para [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html). También deberías considerar [Timex](https://github.com/bitwalker/timex) y[Calendar](https://github.com/lau/calendar), poderosas librerías para trabajar con tiempo en Elixir.
