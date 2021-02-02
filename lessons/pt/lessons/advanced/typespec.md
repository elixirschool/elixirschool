%{
  version: "1.0.3",
  title: "Especificações e tipos",
  excerpt: """
  Nessa lição vamos aprender sobre a sintaxe de `@spec` e `@type`. O primeiro é mais uma sintaxe complementar para escrever documentação que pode ser analisada por ferramentas. A segunda nos ajuda a escrever código de fácil leitura e entendimento.
  """
}
---

## Introdução

Não é incomum querer descrever a interface de sua função. Claro, você pode utilizar a anotação [@doc](../../basics/documentation), mas isso é somente informação para outros desenvolvedores. Isso não será checado em tempo de compilação. Para isso, Elixir tem uma anotação chamada `@spec` para descrever especificação de função que vai ser analisada pelo compilador.

Em alguns casos, a especificação é grande e complicada. Se você quiser reduzir a complexidade, você deverá introduzir um tipo de definição personalizada. Elixir tem a anotação `@type` para isso. Em contra partida, Elixir é uma linguagem dinâmica. Isso significa que toda informação a respeito do tipo será ignorado pelo compilador, mas pode ser utilizada por outras ferramentas.

## Especificação

Se você tem experiência com Java, você poderá pensar em especificação como uma `interface`. A especificação define quais os tipos de parâmetros da função e o valor de retorno.

Para definir tipos de entrada e saída, usamos a diretiva `@spec` localizada antes da definição da função e tomando como um `params` nome da função, lista de tipos de parâmetros, e depois `::` tipo de valor de retorno.

Vamos ver um exemplo:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

Depois de tudo ok, quando chamamos, o resultado válido vai ser retornado, mas a função `Enum.sum` retorna `number` não `integer` como era esperado em `@spec`. Isso pode ser uma fonte de bugs! Existem ferramentas como Dialyzer para análises estáticas de código que nos ajudam a localizar esses tipos de bugs. Vamos falar sobre eles em outra lição.

## Tipos personalizados

Escrever especificações é bom, mas algumas vezes nossas funções trabalham com mais estruturas de dados complexos do que simplesmente números ou coleções. Nesses casos de definição em `@spec` isso poderá ser difícil de entender e/ou alterar para outros desenvolvedores. Algumas funções precisam ter um número grande de parâmetros ou retornar dados complexos. Uma longa lista de parâmetros é um de muitos problemas em potencial em um código. Em linguagens orientadas a objeto como Ruby ou Java, podemos facilmente definir classes que nos ajudam a resolver esse problema. Elixir não tem classes, mas por conta disso é fácil extender o que define nossos tipos.

Elixir contém alguns tipos básicos como `integer` ou `pid`. Você pode encontrar uma lista completa de tipos disponíveis na [documentação](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).

### Definindo tipos personalizados

Vamos modificar nossa função `sum_times` e inserir alguns parâmetros extras:

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Inserimos uma estrutura no módulo `Examples` que contém dois campos, `first` e `last`. Essa é uma versão simples de estrutura do módulo `Range`. Falaremos sobre `structs` quando iniciarmos as discussões sobre [módulos](../../basics/modules/#structs). Vamos imaginar que precisamos especificar a estrutura `Examples` em vários lugares. Seria chato escrever especificações longas, complexas e isso seria uma fonte de bugs. Uma solução para esse problema é `@type`.

Elixir tem três diretivas para tipos:

  - `@type` – tipo é público e a estrutura interna do tipo é pública.
  - `@typep` – tipo é privado e pode ser utilizado somente no módulo onde é definido.
  - `@opaque` – tipo é público, mas estrutura interna é privada.

Vamos definir nosso tipo:

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

Já definimos o tipo `t(first, last)`, que é uma representação da estrutura `%Examples{first: first, last: last}`. Nesse ponto, vemos tipos que podem receber parâmetros, mas definimos o tipo `t` e nesse momento, ele é uma representação da estrutura `%Examples{first: integer, last: integer}`.

Qual a diferença? A primeira representa a estrutura `Examples` e as duas chaves poderiam receber qualquer tipo. A segunda representa a estrutura que as chaves recebem são do tipo `integers`. Que significa um código como este:

```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

É igual ao código:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### Documentação de tipos

O último elemento que vamos falar é sobre como documentar nossos tipos. Como vimos na [documentação](../../basics/documentation), temos as anotações `@doc` e `@moduledoc` para criar documentação para funções e módulos. Para documentar nossos tipos, usamos `@typedoc`:

```elixir
defmodule Examples do
  @typedoc """
      Tipo que representa a estrutura Examples com :first como integer e :last como integer.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

A diretiva `@typedoc` é similar a `@doc` e `@moduledoc`.
