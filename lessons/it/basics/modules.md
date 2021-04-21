%{
  version: "1.4.1",
  title: "Moduli",
  excerpt: """
  Per esperienza sappiamo che è disordinato avere tutte le nostre funzioni nello stesso file o ambito. In questa lezione affronteremo come raggruppare le funzioni e definire una mappa specializzata conosciuta come struttura (_struct_) per organizzare il nostro codice in modo più efficiente.
  """
}
---

## Moduli

I moduli sono il modo migliore per organizzare le funzioni all'interno di un namespace. Oltre a raggruppare le funzioni, i moduli permettono di definire funzioni con nomi e funzioni private, affrontate nella [lezione sulle funzioni](../functions).

Diamo uno sguardo ad un semplice esempio:

```elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

È possibile innestare moduli in Elixir, permettendo di estendere le funzionalità di un namespace:

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### Attributi dei Moduli

Gli attributi dei moduli in Elixir sono principalmente usati come costanti. Ecco un semplice esempio:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

È importante notare che esistono attributi riservati in Elixir. I tre più comuni sono:

- `moduledoc` — Documenta il modulo corrente.
- `doc` — Documentazione per le funzioni e le macro.
- `behaviour` — Usa un OTP o un comportamento definito dall'utente.

## Strutture

Le strutture (_structs_) sono un tipo speciale di mappe con un insieme predefinito di chiavi e valori di default. Deve essere definito all'interno di un modulo, dalla quale prende il suo nome. È comune per una struttura essere l'unica cosa definita all'interno di un modulo.

Per definire una struttura usiamo `defstruct` assieme ad una lista di keywords e valori di default:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Creaiamo qualche struttura:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Possiamo aggiornare la nostra struttura come faremmo con una mappa:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Soprattutto, possiamo combinare le strutture con le mappe:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

A partire da Elixir 1.8, le strutture includono una nuova funzionalità di introspezione personalizzata.
Per capire meglio cosa significhi e come usarlo, ispezioniamo il risultato di `sean`:

```elixir
iex> inspect(sean)
"%Example.User<name: \"Sean\", roles: [...], ...>"
```

Tutti i parametri della struttura sono presenti che in questo caso va bene, ma se volessimo un parametro protetto che non dovrebbe essere incluso?
La nuova funzionalità `@derive` ci consente di realizzare proprio questo!
Aggiorniamo la definizione della struttura `Example.User` in modo che `roles` non venga più incluso nell'output:

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]}
  defstruct name: nil, roles: []
end
```

_Nota_: potremo pure usare `@derive {Inspect, except: [:roles]}`, sono equivalenti.

Con il modulo aggiornato, ora vediamo cosa succede in `iex`:

```elixir
iex> sean = %Example.User<name: "Sean", roles: [...], ...>
%Example.User<name: "Sean", ...>
iex> inspect(sean)
"%Example.User<name: \"Sean\", ...>"
```

Il parametri `roles` è escluso dall'output!

## Composizione

Ora che sappiamo come creare i moduli e le strutture, vediao come includere funzionalità esistenti al loro interno tramite la composizione.
Elixir fornisce una varietà di modi differenti per interagire con altri moduli.

### `alias`

Permette di rinominare il nome di un modulo, è usato frequentemente in Elixir:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Senza alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Se c'è un conflitto tra due alias o vuoi semplicemente rinominare con un nome del tutto differente, possiamo usare l'opzione `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

È anche possibile rinominare più moduli alla volta:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Se vogliamo importare funzioni e macro invece di rinominare il modulo, possiamo usare `import/`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Granularità

Per impostazione predefinita sono importate tutte le funzioni e le macro, ma possiamo filtrarle usando le opzioni `:only` e `:except`.

Per importare funzioni e macro specifiche, dobbiamo fornire la coppia nome/arity a `:only` e `:except`. Cominciamo importando solo la funzione `last/1` :

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Se importiamo tutto tranne `last/1` a proviamo a chiamare le stesse funzioni come nell'esempio precedente:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

In aggiunta alla coppia nome/arity esistono due atomi speciali, `:functions` e `:macros`, che importano rispettivamente solo le funzioni e le macro:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Possiamo usare `require` per comunicare ad Elixir che useremo macro da moduli esterni.
`require` differisce leggermente da `import` perchè permette l'uso di macro, ma non di funzioni dal modulo specificato:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Se proviamo a chiamare una macro che non è stata ancora caricata, Elixir solleverà un errore.

### `use`

La macro `use` permette ad un altro modulo di modificare la definizione del modulo corrente.
Quando `use` viene chiamato, viene invocata la callback `__using__/1`, definita nel module precedente.
Per capire meglio come questo funzioni, diamo un'occhiata ad un semplice esempio:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Abbiamo creato un modulo `Hello` che definisce il callback `__using__/1` nel quale la funzione `hello/1` viene definita.
Ora creiamo un nuovo modulo per provare il nostro codice:

```elixir
defmodule Example do
  use Hello
end
```

Se proviamo il nostro codice in IEx, vedremo che la funzione `hello/1` è disponibile nel module `Example`:

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

Possiamo vedere che `use` ha invocato il callbackk `__using__/1` in `Hello` che a sua volta ha aggiunto il codice risultante nel nostro modulo.
Ora che abbiamo dimostrato un esempio basilare, aggiorniamo il nostro codice e vediamo le opzioni che `__using__/1` supporta.

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

Ora aggiorniamo il module `Example` per includere l'opzione `greeting`:

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

Se proviamo il codice in IEx vediamo che il saluto è cambiato:

```elixir
iex> Example.hello("Sean")
"Hola, Sean"
```

Questi sono semplici esempi che dimostrano l'uso di `use` ma è uno strumento incredibilmente potente in Elixir. Mentre continui ad imparare Elixir, tienilo d'occhio, un esempio che sei sicuro di vedere è `use ExUnit.Case, async: true`.

**Nota**: `quote`, `alias`, `use`, `require` sono macro usate in [metaprogrammazione](../../advanced/metaprogramming).
