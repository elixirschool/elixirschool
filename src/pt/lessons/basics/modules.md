---
version: 0.9.0
title: Composição
---

Sabemos por experiência o quanto é incontrolável ter todas as nossas funções no mesmo arquivo e escopo. Nesta lição vamos cobrir como agrupar funções e definir um mapa especializado conhecido como struct, a fim de organizar o nosso código eficientemente.

{% include toc.html %}

## Modulos

Os módulos são a melhor maneira de organizar as funções em um namespace. Além de agrupar funções, eles permitem definir funções nomeadas e privadas que cobrimos nas lições passadas.

Vejamos um exemplo básico:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

É possível aninhar modulos em Elixir, permitindo-lhe promover um namespace para a sua funcionalidade:

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

### Atributos de módulo

Atributos de módulo são mais comumente usados como constantes no Elixir. Vamos dar uma olhada em um exemplo simples:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

É importante notar que existem atributos reservados no Elixir. Os três mais comuns são:

+ `moduledoc` — Documenta o módulo atual.
+ `doc` — Documentação para funções e macros.
+ `behaviour` — Usa um OTP ou comportamento definido.

## Structs

Structs são mapas especiais com um conjunto definido de chaves e valores padrões. Ele deve ser definido dentro de um módulo, no qual leva o nome dele. É comum para um struct ser a única coisa definido dentro de um módulo.

Para definir um struct nós usamos `defstruct` juntamente com uma lista de palavra-chave de campos e valores padrões:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Vamos criar algumas estruturas:

```elixir
iex> %Example.User{}
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

Podemos atualizar nosso struct apenas como se fosse um mapa:

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

Mais importante, você pode associar estruturas contra mapas:

```elixir
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

## Composição

Agora que sabemos como criar módulos e structs, vamos aprender a incluir uma funcionalidade existente neles através da composição. Elixir nos fornece uma variedade de maneiras diferentes para interagir com outros módulos, vamos ver o que temos à nossa disposição.

### `alias`

Permite-nos criar pseudônimos, usado frequentemente em código Elixir:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Sem alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Se houver um conflito com dois aliases ou você deseja criar um pseudônimo para um nome completamente diferente, podemos usar a opção `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

É possível criar pseudônimos para multiplos módulos de uma vez só:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Se queremos importar funções e macros em vez de criar pseudônimos de um módulo, podemos usar `import/`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtrando

Por padrão todas as funções e macros são importadas, porém nós podemos filtrar-los usando as opções `:only` e `:except`.

Para importar funções e macros específicos nós temos que fornecer os  pares de nome para `:only` e `:except`. Vamos começar por importar apenas a função `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Se nós importarmos tudo, exceto `last/1` e tentar as mesmas funções como antes:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Além do nome existem dois átomos especiais, `:functions` e `:macros`, que importam apenas funções e macros, espectivamente:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Embora usadas com menos frequência, `require/2` não deixa de ser importante. Exigindo que um módulo seja compilado e carregado. Isso é mais útil quando precisamos acessar macros de um módulo:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Se tentar chamar um macro que ainda não está carregado, Elixir vai gerar um erro.

### `use`

Usa o módulo no contexto atual. Isto é particularmente útil quando um modulo que precisa executar alguma configuração. Ao chamar `use` nós invocamos o `__using__` dentro do modulo, proporcionando o módulo uma oportunidade para modificar nosso contexto existente:

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
