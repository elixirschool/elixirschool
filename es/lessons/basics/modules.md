---
version: 0.9.1
title: Composición
---

Sabemos por experiencia que es incontrolable tener todas nuestras funciones en el mismo archivo y alcance. En esta sección cubriremos cómo agrupar funciones y definir un mapa especializado conocido como estructura (struct), con el propósito de organizar nuestro código de manera eficiente.

{% include toc.html %}

## Modulos

Los módulos son la mejor manera de organizar funciones en un namespace. En adición a las funciones agrupativas, los módulos nos permiten definir funciones nombradas y privadas, las cuales cubrimos en la lección pasada.

Démosle un vistazo a un ejemplo básico:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Es posible anidar módulos en Elixir, permitiéndonos ser explícitos nombrando nuestra funcionalidad.


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

### Atributos de un Módulo

Los atributos de un módulo son comúnmente usados como constantes en Elixir.
Démosle un vistazo al siguiente ejemplo:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Es importante destacar que hay atributos reservados en Elixir. Los tres más comunes son:


+ `moduledoc` — Documenta el módulo actual.
+ `doc` — Documentación para funciones y macros.
+ `behaviour` — Usa OTP o comportamiento definido por el usuario.

## Estructuras

Las estructuras son mapas especiales con un conjunto definido de claves y valores por defecto. Deben ser definidas dentro de un módulo, y tomarán su nombre. Es común que una estructura sea definida únicamente dentro de un módulo.

Para definir una estructura utilizamos `defstruct` junto con una lista de claves y valores por defecto:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Ahora, creemos estructuras:

```elixir
iex> %Example.User{}
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

Podemos actualizar una estructura justo como lo hacemos con un mapa:

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

Algo muy importante es que podemos hacer coincidencia entre estructuras y mapas:

```elixir
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

## Composición

Ahora que sabemos cómo crear módulos y estructuras, aprendamos cómo incluir funcionalidad existente dentro de ellos con composición.
Elixir nos provee una variedad de diferentes formas para interactuar con otros módulos, démosle un vistazo a lo que tenemos disponible:

### `alias`

Nos permite darle un alias a los módulos, que son usados frecuentemente en Elixir.

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Without alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Si hay un conflicto entre dos alias o quieres que los alias tomen un nombre diferente, podemos utilizar la opción `:as`

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Es posible dar múltiples alias a un módulo a la vez:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Si queremos importar las funciones y macros de un módulo, más que sólo darle un alias, podemos utilizar `import/`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

### Filtrado

Por defecto, todas las funciones y macros son importadas, pero podemos filtarlas utilizando las opciones `:only` y `:except`
Empecemos por importar únicamente la función `last/1`

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Si importamos todo excepto `last/1` e intentamos utilizar la misma función:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

En adición a los pares nombre/aridad, hay dos átomos especiales, `:functions` y `:macros`, las cuales importan únicamente funciones y macros, respectivamente:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Aunque `require/2` no es usado frecuentemente, es bastante importante. Haciendo `require` de un módulo asegura que está compilado y cargado. Esto es muy útil cuando necesitamos acceso a las macros de un módulo:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff()
end
```

Si intentamos hacer un llamado a una macro que no está cargada aún, Elixir lanzará un error.

### `use`

Utiliza el módulo en el contexto actual. Esto es particularmente utilizado cuando un módulo necesita realizar alguna configuración. Llamando `use`, invocamos el hook `__using__` dentro del módulo, dándole al módulo una oportunidad para modificar nuestro contexto actual.

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
