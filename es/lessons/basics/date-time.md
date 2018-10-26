---
version: 1.0.0
title: Date and Time
---

Trabajando con Elixir.

{% include toc.html %}

## Tiempo

Elixir tiene varios módulos para trabajar con tiempos. Aunque vale la pena resaltar que su funcionalidad está limitada para trabajar con zonas horarias UTC.

Comencemos por obtener el tiempo actual:

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Hay que resaltar que también tenemos un sigilo que puede ser utilizado para crear una estructura `Time`:

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

Puedes aprender más sobre los sigilos en la [lección sobre sigilos](../sigils). Es fácil acceder a las partes que comprenden esta estructura:

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

Pero hay una situación a considerar: como pudiste ya haber notado, esta estructura solo contiene el tiempo dentro de un día, no hay información sobre el día/mes/año presente.

## Fecha

Contrario a `Time`, la estructura `Date` tiene información sobre la fecha actual, sin información sobre el tiempo actual.

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

`day_of_week/1` calcula en qué día de la semana estaría la fecha dada. En este caso, es en sábado. `leap_year?/1` verifica que este sea un año bisiesto. Puede encontrar otras funciones en la [documentación](https://hexdocs.pm/elixir/Date.html).

## Fecha y Tiempos Primitivos

Existen dos tipos de estructuras que contienen tanto la fecha como el tiempo en sí mismo en Elixir.
El primero de los dos es `NaiveDateTime`. Su desventaja es que no sirve para trabajar con zonas horarias:

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

Pero sí tiene de una sola vez la fecha y el tiempo, por lo que te sirve para jugar añadiendo tiempos, por ejemplo:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## Fecha y Tiempo

El segundo módulo para trabajar con fechas y tiempos, es `DateTime`.
Este no tiene las limitaciones del anterior: tiene tanto el tiempo como la fecha, y permite el uso de zonas horarias. Pero hay una situación con las zonas horarias que nos comenta la documentación:

```
Podrás notar que este módulo contiene solo funciones de conversión, así como funciones que trabajan con UTC. Esto es así puesto que una implementación apropiada de DateTime requeriría una base de datos de zonas horarias que actualmente, Elixir no proveé.
```

También, hay que resaltar que es posible crear instancias DateTime a partir de NaiveDateTime, solo indicando la zona horaria:

```
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

¡Y eso es todo! Si quieres trabajar con otras funciones más avanzadas podrías estar interesado en revisar más a fondo la documentación de [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https:hexdocs.pm/elixir/DateTime.html). También deberías considerar [Timex](https://github.com/bitwalker/timex) y [Calendar](https://github.com/lau/calendar) que son poderosas librerías para trabajar con el tiempo en Elixir.
