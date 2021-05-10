---
version: 1.1.1
title: Reťazce
---

Reťazce, Charlisty, Grafémy a Codepointy

{% include toc.html %}

## Reťazce

Reťazce v Elixire nie sú nič iné, než sekvencie bajtov. Pozrime sa na príklad:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

Spojením reťazca s bajtom `0` IEx zobrazí reťazec ako binárny zoznam, pretože už viac nie je platný reťazec. Tento trik nám môže pomôcť pri prezeraní bajtov akéhokoľvek reťazca.

>POZNÁMKA: Použitím syntaxe << >> hovoríme kompilátoru, že elementy vo vnútri sú bajty.

## Charlisty

Doslova: zoznamy znakov.
Reťazce sú v Elixire interne reprezentované sekvenciami bajtov, nie poľami znakov ako v iných jazykoch. Elixir má však aj aj typ char list (zoznam znakov). Kým reťazce sú uzavreté v dvojitých úvodzovkách, charlisty sú uzavreté v jednoduchých úvodzovkách.

Aký je medzi nimi rozdiel? Každá hodnota v charliste je Unicode hodnotou daného znaku, zatiaľ čo reťazec je kódovaný pomocou UTF-8. Napríklad:

```elixir
iex(5)> 'hełło'
[104, 101, 322, 322, 111]
iex(6)> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

Pri programovaní v Elixire zvyčajne používame reťazce, nie charlisty. Podpora charlistov je v Elixire hlavne kvôli niektorým Erlangovým modulom, ktoré ju vyžadujú.

Viac informácii nájdete v [oficiálnej príručke](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## Grafémy a Codepointy

Codepointy sú unicode znaky reprezentované jedným alebo viacerými bajtami, v závislosti od UTF-8 kódovania. Znaky mimo rozsahu US ASCII sú vždy reprezentované minimálne dvoma bajtmi. Napríklad znaky abecedy s diakritikou (`á`, `ñ`, `è`, ...) bývajú kódované dvoma bajtami, znaky ázijských jazykov (napr. čínske znaky) dokonca troma až štyrmi bajtmi. Graféma pozostáva z viacerých codepointov, ktoré sú však vo výsledku vykreslené ako jediný znak.

Modul String poskytuje dve metódy, ktorými ich vieme získať: `graphemes/1` a `codepoints/1`. Ukážme si použitie:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Funkcie pre prácu s reťazcami

Ukážme si niektoré z najdôležitejších fukcií z modulu String. Ich kompletný zoznam aj s príkladmi použitia nájdete v oficiálnej dokumentácii modulu [`String`](https://hexdocs.pm/elixir/String.html).

### `length/1`

Vráti počet grafém v reťazci.

```elixir
iex> String.length "Čučoriedka"
10
```

### `replace/3`

Vráti nový reťazec, ktorý vznike nahradením sekvencie (vzoru) v pôvodnom reťazci inou sekvenciou.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

Vráti nový reťazec, ktorý vznikne n-násobným zopakovaním pôvodného reťazca.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

Vráti zoznam reťazcov, ktorý vznikne rozdelením pôvodného reťazca podľa danej sekvencie.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Cvičenia

Prejdime si jednoduché cvičenia, aby sme ukázali, že sú nám reťazce jasné!

### Anagramy

Reťazce A a B považujeme za anagramy, ak existuje spôsob, ako poprehadzovaním znakov v A dostaneme B (a naopak). Napríklad:

+ A = super
+ B = perus

Takže, ako v Elixire zistíme, či sú dva reťazce anagramami? Najjednoduchším riešením je jednoducho abecedne zoradiť grafémy každého reťazca a následne oba utriedené zoznamy porovnať. Vyskúšajme to:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Najprv sa pozrime na funkciu `anagrams?/2`. Hneď v hlavičke kontrolujeme, či sú prijaté hodnoty argumentov binary (sekvencie bajtov) - takto v Elixire zisťujeme, či je hodnota reťazec.

V tele funkcie voláme pre každý z argumentov funkciu `sort_string?/1`, ktorá reťazec konvertuje na malé písmená (lowercase), potom z neho spraví zoznam grafém pomocou `String.graphemes/1` a ten utriedi podľa abecedy pomocou `Enum.sort/1`. Oba takto získané zoznamy nakoniec porovnáme. Jednoduché, však?

Pozrime sa na výstup v iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

Ako môžeme vidieť, posledné volanie funkcie `anagrams?` vrátilo FunctionClauseError. Tento nám hovorí, že v našom module neexistuje funkcia, ktorá by príjmala dva ne-binárne (ne-reťazcové) argumenty. A to je správne, pretože sme chceli pracovať len s dvoma reťazcami, ničím iným.
