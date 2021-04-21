%{
  version: "1.0.2",
  title: "Vlastné Mix Tasky",
  excerpt: """
  Vytváranie vlastných Mix taskov pre vaše Elixir projekty.
  """
}
---

## Úvod

Občas sa stane, že do svojho projektu potrebujete pridať špeciálnu funkcionalitu pridaním Mix taskov. Predtým, než si ukážeme, ako takéto vlastné Mix tasky vytvárať, pozrime sa na tie, ktoré už existujú:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Ako môžeme vidieť z výstupu príkazu vyššie, framework Phoenix má vlastný Mix task určený na generovanie nového projektu. Čo keby sme mohli vytvoriť niečo podobné aj pre náš projekt? Dobrá správa! Elixir je na to pripravený, tak si poďme ukázať ako na to.

## Nový projekt

Vytvorme si veľmi jednoduchú Mix aplikáciu.

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
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

V súbore **lib/hello.ex**, ktorý nám Mix vygeneroval, vytvorme jednoduchú funkciu ktorá nám vypíše reťazec "Hello, World!"

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Vlastný Mix Task

Teraz si vytvorme vlastný Mix task. Vytvorme nový adresár a súbor **hello/lib/mix/tasks/hello.ex**. Do tohto súboru vložíme nasledujúci kód:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 function"
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Všimnite si, že názov modulu začína na `Mix.Task` a nasleduje meno, ktorým chceme náš task spúšťať z príkazového riadku (teda v tomto prípade `Hello`). Nasleduje uvedenie modulu `Mix.Task`, ktorým do nášho modulu vnesieme rovnomenný behaviour (niečo ako interface v objektových jazykoch). Ďalej implementujeme povinnú funkciu run, ktorá bude nateraz ignorovať svoje argumenty. V tejto funkcii už len zavoláme našu funkciu `say` z modulu `Hello`.


## Mix Tasky v akcii

Poďme si náš nový task vyskúšať. V príkazovom riadku zadajme `mix hello` a mali by sme vidieť nasledovné:

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
mix hello             # Simply calls the Hello.say/0 function.
...
```
