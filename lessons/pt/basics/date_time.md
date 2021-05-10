%{
  version: "1.1.1",
  title: "Data e Tempo",
  excerpt: """
  Trabalhando com tempo em Elixir.
  """
}
---

## Time

O Elixir tem alguns módulos que trabalham com tempo.
Ainda que precise ser notado que essa funcionalidade é limitada para trabalhar com fuso horário UTC.

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

Você pode aprender mais sobre sigil na [lição sobre sigils](../sigils).
É fácil acessar partes desta struct:

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

`day_of_week/1` calcula em que dia da semana será a data provida.
Nesse caso é um sábado.
`leap_year?/1` verifica se é um ano bissexto.
Outras funções podem ser encontradas na [documentação](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

Há dois tipos de structs que contém tanto a data e o tempo em apenas um lugar no Elixir.
O primeiro dos dois é o `NaiveDateTime`.
A desvantagem é a falta de suporte para fuso horário:

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
Não possui as limitações mencionadas no `NaiveDateTime`: possui data e hora e suporta fusos horários.
Mas esteja ciente dos fusos horários. A documentação oficial fala:

> Muitas funções neste módulo requerem um fuso horário do banco de dados. Por padrão, é utilizado o fuso horário do banco de dados que é retornado pela função `Calendar.get_time_zone_database/0`, cujo padrão é `Calendar.UTCOnlyTimeZoneDatabase`, que lida apenas com as datas "Etc/UTC" e retorna `{:error, :utc_only_time_zone_database}` para qualquer outro fuso horário.


Também, note que você pode criar um instância de DateTime a partir de um NaiveDateTime, apenas fornecendo o fuso horário:

``` elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## Trabalhando com timezones

Como observamos no capítulo anterior, por padrão, o Elixir não possui dados de fuso horário.
Para resolver esse problema, precisamos instalar e configurar o pacote [tzdata](https://github.com/lau/tzdata).
Após a instalação, você deve configurar globalmente o Elixir para usar o Tzdata com o fuso horário do banco de dados:

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

Agora, vamos tentar criar um horário no fuso horário de Paris e convertê-lo para o horário de Nova York:

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

Como você pode ver, a hora mudou de 12:00 em Paris para às 6:00 em Nova York, o que é correto - a diferença no fuso horário entre as duas cidades é de 6 horas.

É isso! Se você quer trabalhar com outras funções avançadas, verifique na documentação de [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html) e  [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html)
Você pode considerar o [Timex](https://github.com/bitwalker/timex) e [Calendar](https://github.com/lau/calendar) que são bibliotecas poderosas para trabalhar com tempo no Elixir.
