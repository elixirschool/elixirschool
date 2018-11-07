---
version: 1.0.0
title: Data e Tempo
---

Trabalhando com tempo em Elixir.

{% include toc.html %}

## Time

O Elixir tem alguns módulos que trabalham com tempo. Ainda que precise ser notado que essa funcionalidade é limitada para trabalhar com fuso horário UTC.

Vamos começar pegando o tempo atual:

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Note que nós vamos ter um sigil que pode ser usado para criar uma struct `Time` também:

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

Você pode aprender mais sobre sigil na [lição sobre sigils](../sigils). É fácil acessar partes dessa struct:

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

Mas há uma pegadinha: como você pode ter notado, essa struct contém apenas tempo de um dia, dados de dia/mês/ano não estão presentes.

## Date

Ao contrário do `Time`, a struct `Date` tem as informações sobre a data atual sem nenhuma informação sobre o tempo atual.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

Mas ele tem algumas funções úteis para trabalhar com datas:

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` calcula em que dia da semana será a data provida. Nesse caso é um sábado. `leap_year?/1` verifica se é um ano ano bissexto. Outras funções podem ser encontradas na [documentação](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

Há dois tipos de structs que contém tanto a data e o tempo em apenas um lugar no Elixir
O primeiro dos dois é o `NaiveDateTime`. A desvatagem é a falta de suporte para fuso horário:

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

Mas ele tem tanto o tempo atual como a data, então você pode adicionar tempo, por exemplo:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

O segundo, como você pode ter adivinhado a partir do título dessa seção, é `DateTime`.
Ele não tem as limitações citadas anteriormente: ele tem tanto o tempo e data, e suporta fuso horários. Mas note o comentário da documentação oficial sobre fuso horário:

```
You will notice this module only contains conversion functions as well as functions that work on UTC. This is because a proper DateTime implementation requires a time zone database which currently is not provided as part of Elixir.
```

Também, note que você pode criar um instância de DateTime a partir de um NaiveDateTime, apenas fornecendo o fuso horário:

```
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

É isso! Se você quer trabalhar com outras funções avançadas você pode querer considerar olhar mais sobre isso na documentação de [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html). Você pode considerar o [Timex](https://github.com/bitwalker/timex) e [Calendar](https://github.com/lau/calendar) que são bibliotecas poderosas para trabalhar com tempo no Elixir.
