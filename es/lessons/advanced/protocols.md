---
version: 1.0.1
title: Protocolos
---

En esta lección daremos un vistazo a los Protocolos, qué son y como los podemos utilizar en Elixir.

{% include toc.html %}

## ¿Qué son los Protocolos?
Entonces, ¿qué son?
Los protocolos son un medio para lograr polimorfismo en Elixir.
Uno de los puntos dolorosos de Erlang es extender un API para tipos nuevos.
Para evitar eso, en Elixir la función es despachada dinámicamente basada en el tipo del valor.
Elixir trae varios protocolos, por ejemplo el protocolo `String.Chars` es responsable de la funcion `to_string/1` que hemos utilizado previamente.
Demos un vistazo más cercano a `to_string/1` con un ejemplo rápido:

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

Como puedes ver hemos llamado a la función con múltiples tipos y hemos demostrado que funciona con todos.
¿Qué pasaria si llamamos a `to_string/1` en tuplas (o en cualquier tipo que no haya implementado `String.Chars`)?
Veamos:

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

Como puedes ver obtenemos un error de protocolo ya que no existe la implementación para las tuplas.
En la siguiente sección implementaremos el protocolo `String.Chars` para tuplas.

## Implementando un protocolo

Vimos que `to_string/1` aún no ha sido implementado para tuplas, así que agreguémoslo.
Para crear la implementación utilizaremos `defimpl` con nuestro protocolo y agregaremos la opción `:for` con nuestro tipo.
Veamos como se podría ver:

```elixir
defimpl String.Chars, for: Tuple do
  def to_string(tuple) do
    interior =
      tuple
      |> Tuple.to_list()
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.join(", ")

    "{#{interior}}"
  end
end
```

Si copiamos eso en IEx deberíamos poder llamar a `to_string/1` con una tupla sin tener errores:

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

Con eso ahora sabemos implementar un protocolo, pero ¿cómo definimos uno nuevo?
Para nuestro ejemplo implementaremos `to_atom/1`.
Veamos como se hace con `defprotocol`:

```elixir
defprotocol AsAtom do
  def to_atom(data)
end

defimpl AsAtom, for: Atom do
  def to_atom(atom), do: atom
end

defimpl AsAtom, for: BitString do
  defdelegate to_atom(string), to: String
end

defimpl AsAtom, for: List do
  defdelegate to_atom(list), to: List
end

defimpl AsAtom, for: Map do
  def to_atom(map), do: List.first(Map.keys(map))
end
```

Aquí hemos definido nuestro protocolo y su función esperada `to_atom/1`, además de su implementación para algunos tipos.
Ya que tenemos nuestro protocolo, usémoslo en IEx:

```elixir
iex> import AsAtom
AsAtom
iex> to_atom("string")
:string
iex> to_atom(:an_atom)
:an_atom
iex> to_atom([1, 2])
:"\x01\x02"
iex> to_atom(%{foo: "bar"})
:foo
```

Es importante notar que aunque por debajo los structs son Maps, no comparten las implementaciones de protocolos que los Maps.
Los structs no son enumerables, no pueden ser accedidos.

Como podemos ver, los protocolos son una forma poderosa de lograr polimorfismo.
