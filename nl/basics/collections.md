---
layout: page
title: Verzamelingen
category: basics
order: 2
lang: nl
---

Lijsten, tuples, trefwoorden, maps en functionele combinatoren.

## Inhoud

- [Lijsten](#lists)
  - [Lijsten samenvoegen](#list-concatenation)
  - [Lijsten van elkaar aftrekken](#list-subtraction)
  - [Head / Tail](#head--tail)
- [Tuples](#tuples)
- [Keyword lijsten](#keyword-lists)
- [Maps](#maps)

## Lijsten

Lijsten zijn simpele verzamelingen van waardes. Lijsten kunnen meerdere types bevatten; ze mogen niet-unieke waardes bevatten:

```elixir
iex> [3.41, :taart, "Appel"]
[3.41, :taart, "Appel"]
```

Elixir implementeert de lijst als gekoppelde lijsten. Dit betekent dat het benaderen van de lijstlengte een `O(n)` operatie is. Daarom is het doorgaans sneller om iets aan het begin van de lijst toe te voegen (prepend) dan aan het einde van de lijst (append).

```elixir
iex> lijst = [3.41, :taart, "Appel"]
[3.41, :taart, "Appel"]
iex> ["π"] ++ lijst
["π", 3.41, :taart, "Appel"]
iex> lijst ++ ["Kers"]
[3.41, :taart, "Appel", "Kers"]
```


### Lijsten samenvoegen

Lijsten kunnen samengevoegd worden door de `++/2` operator te gebruiken:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Lijsten van elkaar aftrekken

Lijsten van elkaar aftrekken wordt ondersteund door de `--/2` operator. Het is veilig om een missende waarde af te trekken:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

**Noot:** Het gebruikt [strikte vergelijking](../basics/#comparison) om overeenkomende waardes te vinden.

### Head / Tail

Bij het gebruiken van lijsten is het gebruikelijk om te werken met de kop (head) en staart (tail) van een lijst. De kop is het eerste element van de lijst en de overblijvende elementen vormen de staart. Elixir biedt twee nuttige methodes, `hd` en `tl`, om met deze delen te werken:

```elixir
iex> hd [3.41, :taart, "Appel"]
3.41
iex> tl [3.41, :taart, "Appel"]
[:taart, "Appel"]
```

Naast de eerder genoemde functies kun je ook de pipe operator `|` gebruiken; we zullen dit patroon (in het vervolg `pattern` genoemd) nog in latere lessen terugzien:

```elixir
iex> [h|t] = [3.41, :taart, "Appel"]
[3.41, :taart, "Appel"]
iex> h
3.41
iex> t
[:taart, "Appel"]
```

## Tuples

Tuples zijn vergelijkbaar met lijsten maar zijn aaneengesloten opgeslagen in het geheugen. Dit zorgt ervoor dat ze snel benaderbaar zijn, maar wijziging is kostbaar; de nieuwe tuple moet dan in zijn geheel gekopieerd worden naar het geheugen. Tuples worden gedefinieerd met accolades:

```elixir
iex> {3.41, :taart, "Appel"}
{3.41, :taart, "Appel"}
```

Tuples worden doorgaans gebruikt als middel om extra informatie van functies terug te geven. Het nut hiervan zal duidelijker worden wanneer we dieper ingaan op pattern matching:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lijsten

Keyword (trefwoord) lijsten en maps zijn de associatieve verzamelingen van Elixir. Een keyword lijst is een speciale lijst van tuples wiens eerste element een atom is. Ze delen performance (prestaties) met lijsten:

```elixir
iex> [foo: "bar", hallo: "wereld"]
[foo: "bar", hallo: "wereld"]
iex> [{:foo, "bar"}, {:hallo, "wereld"}]
[foo: "bar", hallo: "wereld"]
```

De drie kenmerken van keyword lijsten benadrukken hun belang:

+ Keys zijn atoms.
+ Keys zijn gerangschikt.
+ Keys zijn niet uniek.

Om deze redenen worden keyword lijsten het meest gebruikt om opties door te geven aan functies.

## Maps

Maps zijn de go-to voor het opslaan van key-value paren in Elixir. Maps staan keys toe van elk type en ze volgen geen rangschikking, in tegenstelling tot keyword lijsten. Je kan een map definiëren met de `%{}` syntax:

```elixir
iex> map = %{:foo => "bar", "hallo" => :wereld}
%{:foo => "bar", "hallo" => :wereld}
iex> map[:foo]
"bar"
iex> map["hallo"]
:wereld
```

Sinds Elixir 1.2 zijn variabelen toegestaan als map keys:

```elixir
iex> key = "hallo"
"hallo"
iex> %{key => "wereld"}
%{"hallo" => "wereld"}
```

Wanneer een key, die al bestaat, wordt toegevoegd aan een map, wordt de voormalige waarde vervangen:

```elixir
iex> %{:foo => "bar", :foo => "hallo wereld"}
%{foo: "hallo wereld"}
```

De output hierboven laat zien dat er een speciale syntax is voor maps die alleen atom keys bevatten:

```elixir
iex> %{foo: "bar", hallo: "wereld"}
%{foo: "bar", hallo: "wereld"}

iex> %{foo: "bar", hallo: "wereld"} == %{:foo => "bar", :hallo => "wereld"}
true
```
