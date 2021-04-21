%{
  version: "1.0.1",
  title: "Interoperabilita s Erlangom",
  excerpt: """
  Jednou z výhod toho, že Elixir je postavený na základoch z Erlang VM (BEAM) je množstvo existujúcich knižníc, ktoré máme k dispozícii. Interoperabilita nám umožňuje používať tieto knižnice a štandardnú knižnicu Erlangu v našom Elixir kóde. V tejto lekcii sa pozrieme na to ako pristupovať k funkcionalite štandardnej knižnice a zároveň aj ku knižniciam tretích strán z Erlangu.
  """
}
---

## Štandardná Knižnica

Rozsiahla štandardná knižnica Erlangu je dostupná z akéhokoľvek Elixir kódu v našej aplikácii. Moduly Erlangu sú reprezentované atómami s malými písmenami ako napríklad `:os` alebo `:timer`.

Skúsme použiť `:timer.tc`, aby sme odmerali ako dlho trvalo vykonanie danej funkcie:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time}ms")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8ms
Result: 1000000
```

Pre kompletný zoznam dostupných modulov je k dispozícii [Príručka Erlangu](http://erlang.org/doc/apps/stdlib/).

## Balíčky Erlangu

V predchádzajúcej lekcii sme zistili ako funguje Mix a správa závislostí projektu. Pridávanie Erlang knižníc funguje rovnakým spôsobom. V prípade, že Erlang knižnica nebola pridaná na [Hex](https://hex.pm) môžeme ako odkaz na ňu použiť git repozitár:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Teraz môžeme pristupovať k našej Erlang knižnici:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Významné Rozdiely

Now that we know how to use Erlang we should cover some of the gotchas that come with Erlang interoperability.
Teraz, keď vieme ako používať Erlang, mali by sme sa oboznámiť s výnimkami, ktoré prináša interoperabilita Erlangu.

### Atómy

Atómy v Erlangu vyzerajú ako ich kolegovia v Elixire, ale bez dvojbodky (`:`). Sú reprezentované malými písmenami a môžu obsahovať podtržníky:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Reťazce

Keď v Elixire hovoríme o reťazcoch myslíme tým na binaries kódované do UTF-8. V Erlangu reťazce tiež používajú dvojité úvodzovky, ale predstavujú char listy:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

Je dôležité poznamenať, že veľa starších Erlang knižníc nemusí podporovať binaries tak vtedy musíme prekonvertovať Elixir reťazce na char listy. To dosiahneme jednoducho použitím funkcie `to_charlist/1`:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2
    (stdlib) string.erl:380: :string.strip_left("Hello World", 32)
    (stdlib) string.erl:378: :string.strip/3
    (stdlib) string.erl:316: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### Premenné

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

To je všetko! Používanie Erlangu v našich Elixir aplikáciach je jednoduché a efektívne zdvojnásobuje počet nám dostupných knižníc.