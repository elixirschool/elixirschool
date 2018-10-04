---
version: 1.1.0
title: Funções
---

Em Elixir e em várias linguagens funcionais, funções são cidadãos de primeira classe. Nós aprenderemos sobre os tipos de funções em Elixir, qual a diferença, e como utilizá-las.

{% include toc.html %}

## Funções anônimas

Tal como o nome indica, uma função anônima não tem nome. Como vimos na lição `Enum`, elas são frequentemente passadas para outras funções. Para definir uma função anônima em Elixir nós precisamos das palavras-chave `fn` e `end`. Dentro destes, podemos definir qualquer número de parâmetros e corpos separados por `->`.

Vejamos um exemplo básico:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### A & taquigrafia

Utilizar funções anônimas é uma prática comum em Elixir, há uma taquigrafia para fazê-lo:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Como você provavelmente já adivinhou, na versão abreviada nossos parâmetros estão disponíveis como `&1`, `&2`, `&3`, e assim por diante.

## Pattern matching

Pattern matching não é limitado a apenas variáveis em Elixir, isto pode ser aplicado a assinaturas de funções como veremos nesta seção.

Elixir utiliza pattern matching para verificar todas as possíveis opções de match e identificar o primeiro conjunto de parâmetros associados para executar seu respectivo corpo.

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## Funções nomeadas

Nós podemos definir funções com nomes para referir a elas no futuro, estas funções nomeadas são definidas com a palavra-chave `def` dentro de um módulo. Nós iremos aprender mais sobre Módulos nas próximas lições, por agora nós iremos focar apenas nas funções nomeadas.

Funções definidas dentro de um módulo são disponíveis para uso de outros módulos, isso é particularmente útil na construção de blocos em Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```
Se o corpo da nossa função apenas tem uma linha, nós podemos reduzi-lo ainda mais com `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Armado com nosso conhecimento sobre pattern matching, vamos explorar recursão usando funções nomeadas:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Nomear Funções e a Aridade

Mencionamos anteriormente que as funções são nomeadas pela combinação do nome e aridade (quantidade dos argumentos) das funções. Isto significa que você pode fazer coisas como essa:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

Nós listamos os nomes das funções nos comentários acima. A primeira implementação não recebe argumentos, é conhecida como `hello/0`; a segunda função recebe um argumento, portanto será conhecido como `hello/1` e assim por diante. E, ao contrário de sobrecargar funções como em outras linguagens de programação, estas são pensadas como funções _diferentes_ entre uma e outra. (Pattern matching, ou combinação de padrões, descrita agora há pouco, apenas se aplica quando várias definições são fornecidas com a _mesma_ quantidade de argumentos.)

### Funções privadas

Quando não quisermos que outros módulos acessem uma função específica, nós podemos torná-la uma função privada, que só podem ser chamadas dentro de seus módulos. Nós podemos defini-las em Elixir com `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Guards

Nós cobrimos brevemente guards nas lições de [Estruturas Condicionais](../control-structures), agora veremos como podemos aplicá-los em funções nomeadas. Uma vez que Elixir tem correspondência em uma função, qualquer guard existente irá ser testado.

No exemplo a seguir nós temos duas funções com a mesma assinatura, contamos com guards para determinar qual usar com base no tipo do argumento:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Argumentos padrões

Se nós quisermos um valor padrão para um argumento, nós usamos a sintaxe `argumento \\ valor`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("pt"), do: "Olá, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "pt")
"Olá, Sean"
```

Quando combinamos nosso exemplo de guard com argumento padrão, nos deparamos com um problema. Vamos ver o que pode parecer:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("pt"), do: "Olá, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir não gosta de argumentos padrões em múltiplas funções, pode ser confuso. Para lidar com isto, adicionamos funções com nosso argumento padrão:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("pt"), do: "Olá, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "pt"
"Olá, Sean, Steve"
```
