%{
  version: "1.0.2",
  title: "Interoperabilidade com Erlang",
  excerpt: """
  Um dos benefícios adicionais em se construir em cima da Erlang VM (BEAM) é a abundância de bibliotecas existentes disponíveis para nós. A interoperabilidade nos permite usar essas bibliotecas e a biblioteca padrão Erlang a partir do nosso código Elixir. Nesta lição veremos como acessar funcionalidades da biblioteca padrão juntamente com pacotes Erlang de terceiros.
  """
}
---

## Biblioteca padrão

A extensa biblioteca padrão Erlang pode ser acessada de qualquer código Elixir em nossa aplicação. Módulos Erlang são representados por *átomos* em caixa baixa como `:os` e `:timer`.

Vamos usar `:timer.tc` para medir o tempo de execução de uma determinada função:

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

Para uma lista completa de módulos disponíveis, consulte o [Manual de referência Erlang](http://erlang.org/doc/apps/stdlib/).

## Pacotes Erlang

Em uma lição anterior nós cobrimos Mix e como gerenciar nossas dependências. Incluir bibliotecas Erlang funciona da mesma maneira. Caso a biblioteca Erlang não tenha sido publicada no [Hex](https://hex.pm), você pode alternativamente utilizar seu repositório git:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Agora podemos acessar nossa biblioteca Erlang:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Diferenças notáveis

Agora que sabemos como usar Erlang, devemos cobrir alguns contrapontos que vêm com a interoperabilidade com Erlang.

### Átomos

Átomos Erlang são similares aos de Elixir, só que sem os dois pontos (`:`). Eles são representados por *strings* e *underscores* em caixa baixa:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Strings

Em Elixir, quando falamos *strings*, nós queremos dizer binários codificados em UTF-8. Em Erlang, *strings* continuam usando aspas mas representam listas de caracteres:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

É importante notar que muitas bibliotecas Erlang antigas podem não suportar binários, então precisamos converter *strings* Elixir em lista de caracteres. Felizmente, isso é fácil de se fazer com a função `to_charlist/1`:

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

### Variáveis

Em Erlang, variáveis começam com caixa alta e a reassociação de variáveis não é permitida.

Elixir:

```elixir
iex> x = 10
10

iex> x = 20
20

iex> x1 = x + 10
30
```

Erlang:

```erlang
1> X = 10.
10

2> X = 20.
** exception error: no match of right hand side value 20

2> X1 = X + 10.
20
```

É isso! Utilizar Erlang a partir da nossa aplicação Elixir é fácil e efetivamente dobra o número de bibliotecas disponíveis para nós.
