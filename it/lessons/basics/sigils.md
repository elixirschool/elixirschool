---
layout: page
title: Sigils
category: basics
order: 10
lang: it
---

Lavorare e creare sigils.

## Table of Contents.

- [Introduzione ai Sigils](#introduzione-ai-sigils)
  - [Liste di Caratteri](#liste-di-caratteri)
  - [Espressioni Regolari](#espressioni-regolari)
  - [Stringhe](#stringhe)
  - [Liste di Parole](#liste-di-parole)
- [Creare Sigils](#creare-sigils)

## Introduzione ai Sigils

Elixir offre una sintassi alternativa per rappresentare e lavorare con dati letterali (_literals_). Un sigil inizia con un tilde `~` seguito da un carattere. Elixir mette a disposizione alcuni sigils predefiniti, tuttavia è possibile crearne di personalizzati quando abbiamo bisogno di estendere il linguaggio.

Una lista dei sigils disponibili include:

  - `~C` Crea una lista di caratteri **senza** caratteri di escape o iterpolazioni
  - `~c` Crea una lista di carratteri **con** caratteri di escape e interpolazioni
  - `~R` Crea un'espressione regolare **senza** caratteri di escape o iterpolazioni
  - `~r` Crea un'espressione regolare **con** caratteri di escape e interpolazioni
  - `~S` Crea stringhe **senza** caratteri di escape o iterpolazioni
  - `~s` Crea stringhe **con** caratteri di escape e interpolazioni
  - `~W` Crea una lista **senza** caratteri di escape o iterpolazioni
  - `~w` Crea una lista **con** caratteri di escape e interpolazioni

Una lista di separatori disponibili include:

  - `<...>` Una coppia di parentesi angolari
  - `{...}` Una coppia di parentesi graffe
  - `[...]` Una coppia di parentesi quadre
  - `(...)` Una coppia di parentesi tonde
  - `|...|` Una coppia di pipes
  - `/.../` Una coppia di slashes
  - `"..."` Una coppia di apici doppi
  - `'...'` Una coppia di apici singoli

### Liste di Caratteri

I sigils `~c` e `~C` creano rispettivamente una lista di caratteri. Per esempio:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = #{2 + 7}'
```

Possiamo notare che la `~c` minuscola applica l'interpolazione, invece la `~C` maiuscola non lo fa. Vedremo che questa sequenza maiuscola / minuscola è un tema comune all'interno dei sigils presenti.

### Espressioni Regolari

I sigils `~r` e `~R` sono usati per rappresentare espressioni regolari (_regex_). Li creiamo direttamente o per usarli con le funzioni offerte dal modulo `Regex`. Per esempio:

```elixir
iex> re = ~r/elixir/
~/elixir

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Possiamo notare che nel primo controllo di uguaglianza, l'espressione regolare non è verificata con la stringa `"Elxir"`. Questo perchè contiene la prima lettera maiuscola. Considerato che Elixir supporta la compatibilità con le espressioni regolari di Perl (_PCRE_), possiamo appendere `i` alla fine del nostro sigil per disattivare la differenza tra maiuscole e minuscole.

```elixir
iex> re = ~r/elixir/i
~/elixir

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Inoltre, Elixir offre il modulo [Regex](http://elixir-lang.org/docs/stable/elixir/Regex.html) che è stato costruito sulla libreria delle espressioni regolari di Erlang. Proviamo ad implementare `Regex.split/2` usando un sigil per le espressioni regolari:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Come possiamo vedere, la stringa `"100_000_000"` è stata divisa sul carattere underscore grazie al nostro sigil `~r/_`. La funzione `Regex.split` restituisce una lista.

### Stringhe

I sigils `~s` e `~S` sono usati per creare dati di tipo stringa. Per esempio:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Ma qual è la differenza? La differenza è simile ai sigil per le liste di caratteri che abbiamo visto in precedenza. La risposta è nell'uso dell'interpolazione e dei caratteri di escape:

```elixir
iex> ~s/welcome to elixir #{String.downcase "school"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "school"}/
"welcome to elixir \#{String.downcase \"school\"}"
```

### Liste di Parole

Il sigil per la lista di parole può tornare molto comodo di volta in volta. Può far risparmiare tempo, battute e presumibilmente riduce la complessità all'interno del codice nel progetto. Osserviamo questo semplice esempio:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Possiamo vedere che il testo all'interno dei delimitatori è separato usando gli spazi e posto in una lista. Tuttavia, non c'è differenza tra questi due esempi. Di nuovo, la differenza consiste nell'interpolazione e nelle sequenze di escape. Consideriamo l'esempio seguente:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

## Creare Sigils

Uno degli obiettivi di Elixir è quello di essere un linguaggio di programmazione espandibile. Quindi non dovrebbe sorprendere il fatto di poter creare i propri sigils. In questo esempio, creeremo un sigil per convertire una stringa in maiuscolo. Considerato che in Elixir è già presente una funzione per fare questo (`String.upcase/1`), costruiremo il nostro sigil attorno a quella funzione.

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

Innanzi tutto definiamo un modulo chiamato `MySigils` e, al suo interno, abbiamo creato una funzione chiamata `sigil_u`. Dal momento che non esiste un sigil `~u` predefinito, useremo quello. Il suffisso `_u` indica che vogliamo usare `u` come carattere dopo la tilde. La definizione della funzione deve accettare due argomenti: un input ed una lista.
