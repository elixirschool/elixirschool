---
version: 0.9.0
title: Composizione
---

Per esperienza sappiamo che è disordinato avere tutte le nostre funzioni nello stesso file o ambito. In questa lezione affronteremo come raggruppare le funzioni e definire una mappa specializzata conosciuta come struttura (_struct_) per organizzare il nostro codice in modo più efficiente.

{% include toc.html %}

## Moduli

I moduli sono il modo migliore per organizzare le funzioni all'interno di un namespace. Oltre a raggruppare le funzioni, i moduli permettono di definire funzioni con nomi e funzioni private, affrontate nella lezione precedente.

Diamo uno sguardo ad un semplice esempio:

``` elixir
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

+ `moduledoc` — Documenta il modulo corrente.
+ `doc` — Documentazione per le funzioni e le macro.
+ `behaviour` — Usa un OTP o un comportamento definito dall'utente.

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
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

Possiamo aggiornare la nostra struttura come faremmo con una mappa:

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

Soprattutto, possiamo combinare le strutture con le mappe:

```elixir
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

## Composizione

Ora che sappiamo come creare i moduli e le strutture, vediao come includere funzionalità esistenti al loro interno tramite la composizione. Elixir fornisce una varietà di modi differenti per interagire con altri moduli. Vediamo cosa abbiamo a disposizione.

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

Nonostante sia usato meno frequentemente, `require/2` è comunque importante. Richiedere un modulo garantisce che venga compilato e caricato. Questo è particolarmente utile quando dobbiamo accedere alle macro di un modulo:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Se proviamo a chiamare una macro che non è stata ancora caricata, Elixir solleverà un errore.

### `use`

Usa il modulo nel contesto corrente. Questo è particolarmente utile quando un modulo ha bisogno di eseguire qualche configurazione. Chiamando `use` invochiamo la funzione (_hook_) `__using__` all'interno del modulo, fornendo al modulo la possibilità di modificare il contesto esistente:

```elixir
defmodule MyModule do
  defmacro __using__(opts) do
    quote do
      import MyModule.Foo
      import MyModule.Bar
      import MyModule.Baz

      alias MyModule.Repo
    end
  end
end
```
