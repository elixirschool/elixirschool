%{
  version: "1.0.1",
  title: "Interoperabilidad Erlang",
  excerpt: """
  Uno de los beneficios añadidos de Elixir al estar construido sobre Erlang VM (BEAM) es la gran cantidad de bibliotecas existentes que están disponibles para nosotros.
  La interoperabilidad nos permite aprovechar esas bibliotecas y la librería estándar de Erlang desde nuestro código Elixir.
  En esta lección vamos a ver como acceder a la funcionalidad en la librería estándar junto con los paquetes de Erlang de terceros.
  """
}
---

## Librería Estándar

La extensa biblioteca estándar de Erlang se puede acceder desde cualquier código de Elixir en nuestra aplicación.
Los módulos Erlang están representados por átomos en minúsculas como `:os` y `:timer`.

Vamos a usar `:timer.tc` para medir el tiempo de ejecución de una función dada:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

Para una lista completa de los módulos disponibles, visite el [Manual de Referencia Erlang](http://erlang.org/doc/apps/stdlib/).

## Paquetes Erlang

En una lección anterior hemos cubierto Mix y la administración de nuestras dependencias.
Incluyendo las bibliotecas de Erlang funciona de la misma manera.
En caso de que la biblioteca Erlang no haya sido agregada en [Hex] (https://hex.pm) puedes hacer referencia al repositorio git en su lugar:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Ahora podemos acceder a nuestra librería Erlang

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Diferencias Notables

Ahora que sabemos cómo usar Erlang debemos cubrir algunas de las trampas que vienen con la interoperabilidad de Erlang.

### Átomos

Los átomos de Erlang se parecen mucho a sus homólogos Elixir sin los dos puntos (`:`). Están representados por cadenas en minúsculas y caracteres de subrayado:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Cadenas

En Elixir cuando hablamos de cadenas nos referimos a los binarios codificación en UTF-8. En Erlang, las cadenas siguen utilizando comillas dobles, pero se refieren a listas de caracteres:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
1> is_list("Example").
true
1> is_binary("Example").
false
1> is_binary(<<"Example">>).
true
```

Es importante tener en cuenta que muchas bibliotecas Erlang más antiguas podrían no soportar binarios, por lo que necesitamos convertir cadenas Elixir a lista de caracteres. Afortunadamente esto es fácil de lograr con la función `to_charlist/1`:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### Variables

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

¡Eso es! Aprovechando Erlang desde dentro de nuestras aplicaciones Elixir es fácil y efectivamente duplica el número de bibliotecas disponibles para nosotros.
