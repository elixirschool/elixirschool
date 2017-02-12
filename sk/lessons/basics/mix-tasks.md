---
version: 0.9.0
layout: page
title: Mix tasky 
category: basics
order: 15
lang: sk
---

Vytváranie vlastných Mix taskov (skriptov) pre vaše Elixirové projekty

{% include toc.html %}

## Úvod

Občas sa stáva, že do svojho projektu potrebujete pridať vlastné špeciálne Mix tasky. Predtým, než si ukážeme, ako takéto vlastné tasky vytvárať, pozrime sa na tie, ktoré sú od začiatku k dispozícii v každom Elixirovom projekte:

## Založenie nového projektu

Task `new` nám vygeneruje základnú kostru Elixirového projektu:

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Teraz si otvorme novo vygenerovaný súbor **lib/hello.ex** a pridajme doňho novú funkciu, ktorá vypíše reťazec "Hello, World!"

```elixir
defmodule Hello do

  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts "Hello, World!"
  end
end
```

## Vlastný Mix task

Vytvorme si teraz vlastný Mix task. V adresári **hello/lib/mix/tasks/hello.ex** vytvoríme súbor **hello.ex** a doňho vložíme nasledujúci kód:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Spustí funkciu Hello.say/0."
  def run(_) do
    Hello.say # calling our Hello.say() function from earlier
  end
end
```

Všimnite si, že názov modulu začína na `Mix.Task` a nasleduje meno, ktorým chceme náš task spúšťať z príkazového riadku (teda v tomto prípade `Hello`). Nasleduje uvedenie modulu `Mix.Task`, ktorým do nášho modulu vnesieme rovnomenný behaviour (niečo ako interface v objektových jazykoch). Ďalej implementujeme povinnú funkciu `run` (každý Elixir task ju musí obsahovať - vykoná sa pri jeho spustení), ktorá bude nateraz ignorovať svoje argumenty. V tejto funkcii už len zavoláme našu funkciu `say` z modulu `Hello`.


## Mix tasky v akcii

Nadišiel čas náš nový task vyskúšať. Na príkazovom riadku zadajme `mix hello` a mali by sme vidieť nasledovné:

```shell
$ mix hello
Hello, World!
```

Mix je celkom prívetivý a tolerantný - vie, že ľudia robia občas chyby a preklepy, takže používa techniku nazývanú *fuzzy string matching* aby navrhol možné opravy:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Možno ste si všimli, že sme v definícii nášho tasku použili nový modulový atribút `@shortdoc`. Tento sa výborne hodí na popis špeciálnych taskov nášho projektu. Keď používateľ zadá do príkazového riadku v adresári nášho projektu `mix help`, uvidí aj popis nášho tasku `hello`:

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Spustí funkciu Hello.say/0.
...
```
