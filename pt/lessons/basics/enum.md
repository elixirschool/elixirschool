---
layout: page
title: Enum
category: basics
order: 3
lang: pt
---

Um conjunto de algoritmos para fazer enumeração em coleções.

{% include toc.html %}

## Enum

O módulo `Enum` inclui mais de cem funções para trabalhar com as coleções que aprendemos na última lição.

Essa lição somente mostrará um subconjunto das funções disponíveis, para ver a lista completa de funções visite a documentação oficial [`Enum`](http://elixir-lang.org/docs/stable/elixir/Enum.html); para enumeração preguiçosa use o módulo[`Stream`](http://elixir-lang.org/docs/stable/elixir/Stream.html).

### all?

Quando usando `all?`, e muitas das funções de `Enum`, provemos uma função para aplicar nos elementos da nossa coleção. No caso do `all?`, a coleção inteira deve ser avaliada como `true`, em outros casos `false` será retornado:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Diferente da anterior, `any?` retornará `true` se ao menos um elemento for `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk

Se você necessita quebrar sua coleção em pequenos grupos, `chunk` é a função que você provavelmente está buscando:

```elixir
iex> Enum.chunk([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Há algumas opções para `chunk` porém não vamos entrar nelas, revise [`chunk/2`](http://elixir-lang.org/docs/stable/elixir/Enum.html#chunk/2) na documentação oficial para aprender mais.

### chunk_by

Se necessita agrupar uma coleção baseado em algo diferente do tamanho, podemos usar a função `chunk_by`:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
```

### map_every

Algumas vezes quebrar uma coleção não é o suficiente para fazer exatamente o que você precisa. Se este é o caso, `map_every/3` pode ser muito útil para tratar apenas itens específicos se sua coleção possui uma ordenação que possa ser necessária ou útil:

```elixir
iex> Enum.map_every([1, 2, 3, 4], 2, fn x -> x * 2 end)
[2, 2, 6, 4]
```

### each

Pode ser necessário iterar sobre uma coleção sem produzir um novo valor, para este caso podemos usar `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
```

__Nota__: A função `each` retorna um átomo `:ok`.

### map

Para aplicar uma função a cada elemento e produzir uma nova coleção use a função `map`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` retorna o valor mínimo de uma coleção:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` faz o mesmo, porém permite especificar um valor padrão para `Enum` através de uma função anônima: 

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` retorna o valor máximo de uma coleção:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` faz o mesmo e se comporta da mesma maneira que `min/2`, permitindo passar uma função anônima para especificar um valor padrão para `Enum`:

```elixir
iex> Enum.max([], fn -> :bar end)
:bar
```

### reduce

Com `reduce` podemos transformar nossa coleção em um único valor, para fazer isto aplicamos um acumulador opcional (`10` por exemplo) que será passado a nossa função; se não prover um acumulador, o primeiro valor será usado:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
```

### sort

Ordenar nossas coleções é fácil com uma das funções de ordenação. A primeira opção disponível utiliza o critério de ordenação de termos do Elixir para determinar a ordem da ordenação:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

A outra opção nos permite prover uma função de ordenação:

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{count: 4}, %{count: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

Podemos usar `uniq_by/2` para eliminar itens duplicados em nossas coleções:

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```

Esta função era previamente conhecida como `uniq/1`, que está obsoleta a partir do Elixir 1.4, mas ainda está disponível (com alertas).
