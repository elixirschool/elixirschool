---
version: 1.0.1
title: Spracovanie Chýb
---

Bežne môžeme vidieť pri funkciách návratovú hodnotu tuple `{:error, reason}`, ale Elixir podporuje aj výnimky a v tejto lekcii si ukážeme ako spracovávať chyby a rôzne mechanizmy ktoré máme k dispozícii.

Vo všeobecnosti je v Elixire konvenciou vytvárať funkciu `example/1`, ktorá vráti `{:ok, result}` alebo `{:error, reason}` a funkcia `example!/1`, ktorá vráti neobalený výsledok alebo vyvolá chybu.

Táto lekcia sa zameriava na spracovanie týchto chýb.

{% include toc.html %}

## Spracovanie Chýb

Predtým, než môžeme spracovávať chyby potrebujeme ich vytvoriť a najjednoduchší spôsob ako to spraviť je pomocou `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Ak chceme špecifikovať typ a správu musíme použiť `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Keď vieme, že môže nastať chyba, môžeme ju zachytiť pomocou `try/rescue` a pattern matchingu:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Je možné zachytiť viacero chýb v jednom bloku rescue:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

Niekedy môže byť nevyhnutné spustiť akciu po našom `try/rescue` bloku bez ohľadu na to či nastala chyba. Na toto máme k dispozícii `try/after` podobne ako v Ruby `begin/rescue/ensure` alebo v Jave `try/catch/finally`:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Bežne sa after používa pri práci so súbormi alebo pripojeniami, ktoré by mali byť zatvorené:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## Nové Chyby

Aj keď Elixir má množstvo zabudovaných typov chýb ako napríklad `RuntimeError`, ale máme možnosť vytvoriť si svoje typy chýb ak potrebujeme niečo veľmi špecifické. Vytváranie nových typov chýb je jednoduché s pomocou makra `defexception/1`, ktoré akceptuje možnosť `:message`, ktorá nastaví štandardnú chybovú správu:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

A teraz si vyskúšajme náš nový typ chyby:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throws

Ďalší mechanizmus pre prácu s chybami v Elixire je `throw` a `catch`. V praxi sa vyskytujú veľmi zriedka v novšom Elixir kóde, ale aj napriek tomu je dôležité vedieť a chápať ako fungujú.

Funkcia `throw/1` nám dáva možnosť ukončiť vykonávanie programu so špecifickou hodnotu, ktorú môžeme zachytiť (`catch`) a použiť:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Ako sme spomenuli, `throw/catch` sú zriedkavé a väčšinou existujú ako dočasné riešenie ak knižnice neposkytujú adekvátne API.

## Exiting

Posledný mechanizmus na spracovanie chýb, ktorý nám Elixir poskytuje je `exit`. Signál Exit sa vyskytne kedykoľvek zanikne proces a sú dôležitou časťou odolnosti voči chybám Elixiru.

Ak chceme explicitne ukončiť aplikáciu môžeme použiť `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) "oh no"
```

Je možné zachytiť exit pomocou `try/catch`, ale to sa deje len vo _veľmi_ zriedkavých prípadoch. Skoro vo všetkých prípadoch je výhodné nechať supervisora, ktorý si poradí so zaniknutím procesu:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
