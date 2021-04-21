%{
  version: "1.0.1",
  title: "Protocols",
  excerpt: """
  Nesta lição nós iremos aprender um pouco sobre Protocols, o que eles são e como usamos ele em Elixir.
  """
}
---

## O que são Protocols
Então, o que eles são?
Protocolos são um meio de alcançar polimorfismo no Elixir.
Uma dor de Erlang é estender uma API existente para tipos recentemente definidos.
Para evitar isso no Elixir, a função é despachada dinamicamente com base no tipo do valor.
O Elixir vem com um número de protocolos incorporados, por exemplo, o protocolo `String.Chars` é responsável pela função` to_string / 1` que vimos ser usada anteriormente.
Vamos dar uma analizar `to_string/1` com um exemplo rápido:

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

Como você pode ver, chamamos a função em vários tipos e isso demonstrou que funciona com todos eles.
E se chamarmos `to_string/1` em tuplas (ou qualquer tipo que não tenha implementado `String.Chars`)?
Vejamos o exemplo:

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

Como você pode ver, temos um erro de protocol, pois não há nenhuma implementação para tuplas.
Na próxima seção vamos implementar o protocolo `String.Chars` para tuplas.

## Implementando um protocol

Vimos que `to_string/1` ainda não foi implementado para tuplas, então vamos adicioná-lo.
Para criar uma implementação, usaremos `defimpl` com o nosso protocolo e forneceremos a opção `:for` e o nosso tipo.
Vamos dar uma olhada em como ele pode parecer:

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

Se copiarmos isso para o IEx, seremos capazes de chamar `to_string/1` em uma tupla sem obter um erro:

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

Sabemos como implementar um protocolo, mas como podemos definir um novo?
Para o nosso exemplo, implementaremos `to_atom/1`.
Vamos ver como fazer isso com `defprotocol`:

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

Aqui definimos o nosso protocolo e a função esperado, `to_atom/1`, juntamente com implementações para alguns tipos.
Agora que temos o nosso protocolo, vamos colocá-lo para usar em IEx:

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

É irrelevante se embora embaixo dos panos structs sejam Maps, mas não compartilhem implementações de protocolo com Maps. Eles não são enumeráveis, não podem ser acessados.

Como podemos ver, os protocolos são uma maneira poderosa de alcançar o polimorfismo.