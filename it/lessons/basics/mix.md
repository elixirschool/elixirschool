---
version: 1.1.0
title: Mix
---

Prima di approfondire ulteriormente Elixir, dobbiamo prima imparare a conoscere Mix.
Se hai familiarità con Ruby, Mix è Bundler, RubyGems e Rake in un solo strumento.
È un elemento cruciale di qualsiasi progetto Elixir e in questa lezione esploreremo solo una parte delle sue eccezionali funzionalità.
Per vedere tutte le cose che mix può fare, esegui il comando `mix help`.

Finora abbiamo lavorato esclusivamente con `iex` che però ha alcune limitazioni.
Per costruire qualcosa di significativo dobbiamo dividere il nostro codice su più files in modo da poterli gestire meglio, Mix ci permette di farlo con i progetti.

{% include toc.html %}

## Nuovi Progetti

Quando siamo pronti a creare un nuovo progetto in Elixir, Mix rende l'operazione semplice con il comando `mix new`.
Questo genererà la struttura delle cartelle per il nostro progetto assieme ai file predefiniti.
È facile, quindi cominciamo:

```bash
$ mix new example
```

Dall'output possiamo vedere che Mix ha creato la nostra directory assieme ad un certo numero di files predefiniti:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

In questa lezione focalizzeremo la nostra attenzione su `mix.exs`.
Qui possiamo configurare la nostra applicazione, le dipendenze, l'ambiente e la versione.
Apri il file nel tuo editor preferito, dovresti vedere qualcosa di simile a questo (commenti rimossi per chiarezza):

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

La prima sezione che osserveremo è `project`.
Qui definiamo il nome della nostra applicazione (`app`), specifichiamo la nostra versione (`version`), la versione di Elixir (`elixir`), infine le nostre dipendenze (`deps`).

La sezione `application` è usata durante la generazione del file per la nostra applicazione di cui parleremo più avanti.

## Modalità Interattiva

Potrebbe essere necessario usare `iex` all'interno del constesto della nostra applicazione.
Fortunatamente per noi, Mix rende questa operazione semplice. Con la nostra applicazione compilata, possiamo iniziare una nuova sessione di `iex`:

```bash
$ cd example
$ iex -S mix
```

Lanciando `iex` in questo modo, verrà caricata la nostra applicazione e le sue dipendenze all'interno della sessione.

## Compilazione

Mix è abbastanza intelligente e compilerà i tuoi cambiamenti quando necessario, tuttavia potrebbe ancora essere necessario compilare esplicitamente il tuo progetto.
In questa sezione affronteremo come compilare il nostro progetto ed in cosa consiste la compilazione.

Per compilare un progetto con Mix, dobbiamo solo lanciare il comando `mix compile` all'interno della cartella principale:
**Nota: i comandi di Mix per un progetto sono disponibili solo se eseguiti nella cartella principale del progetto, altrimenti sono disponibili solo i comandi globali di Mix.**


```bash
$ mix compile
```

Non c'è molto nel nostro progetto per cui il risultato non sarà entusiasmante, tuttavia l'operazione dovrebbe finalizzarsi con successo:

```bash
Compiled lib/example.ex
Generated example app
```

Quando compiliamo un progetto, Mix crea una cartella `_build` con il nostro lavoro.
Se guardiamo all'interno di `_build` noteremo la nostra applicazione compilata: `example.app`.

## Gestione delle Dipendenze

Il nostro progetto non ha ancora alcuna dipendenza ma le avrà a breve, quindi procediamo definendo le dipendenze e scaricandole.

Per aggiungere una nuova dipendenza dobbiamo innanzi tutto aggiungerla al nostro `mix.exs` all'interno della sezione `deps`.
La nostra lista di dipendenze è composta da tuple con due valori obbligatori ed uno opzionale: il nome del pacchetto come atom, una stringa che rappresenta la versione, ed eventuali opzioni.

Per questo esempio, diamo uno sguardo ad un progetto con le dipendenze, come [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

Come avrai probabilmente intuito dalle dipendenze mostrate sopra, la dipendenza `cowboy` è necessaria solo durante lo sviluppo ed il test.

Una volta definite le nostre dipendenze manca solo un ultimo passaggio, scaricarle. Questo è molto simile a `bundle install`:

```bash
$ mix deps.get
```

Fatto! Abbiamo definito e scaricato le dipendenze per il nostro progetto. Ora siamo pronti ad aggiungere altre dipendenze quando sarà necessario.

## Ambienti

Mix, come Bundler, supporta ambienti differenti.
Inizialmente è configurato per avere tre ambienti predefiniti:

- `:dev` — Ambiente di default.
- `:test` — Usato da `mix test`. Verrà approfondito nella prossima lezione.
- `:prod` — Usato quando dobbiamo mandare la nostra applicazione in produzione.

L'ambiente corrente può essere raggiunto usando `Mix.env`.
Come previsto, l'ambiente può essere cambiato tramite la variabile d'ambiente `MIX_ENV`:

```bash
$ MIX_ENV=prod mix compile
```
