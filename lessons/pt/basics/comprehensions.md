---
version: 1.1.0
title: Comprehensions
---

Comprehensions são um 'syntactic sugar' (uma forma mais simples de escrever) para realizar loops em Enumerables em Elixir. Nesta lição veremos como podemos fazer iterações e gerar os resultados utilizando comprehensions.

{% include toc.html %}

## Básico

Em alguns casos comprehensions podem ser usadas para produzir código mais conciso para fazer iterações com `Enum` e `Stream`. Vamos começar olhando para uma comprehension simples e então observar suas várias partes:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

A primeira coisa que observamos é o uso de `for` e um generator (gerador). O que é um generator? Generators são as expressões `x <- [1, 2, 3, 4]` encontradas em comprehensions. Eles são responsáveis por gerar o próximo valor.

Para nossa sorte, comprehensions não são limitadas a listas; na verdade elas funcionam com qualquer enumerable:

```elixir
# Keyword Lists
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Como muitas outras coisas em Elixir, generators se apoiam no pattern matching para comparar a entrada definida na variável à esquerda. Caso um match não seja encontrado, o valor é ignorado.

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

É possível utilizar múltiplos generators, bem como loops aninhados:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Para ilustrar melhor cada iteração do loop, vamos usar `IO.puts` para mostrar os dois valores gerados:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

Comprehensions são _syntactic sugar_ e devem ser utilizadas apenas quando for apropriado.

## Filtros

Você pode pensar em filtros como um tipo de _guard_ para comprehensions. Quando um valor filtrado retorna `false` ou `nil` ele é excluído da lista final. Vamos iterar por um intervalo e olhar apenas os números pares. Nós vamos usar a função `is_even/1` do módulo Integer para checar se um valor é par ou não.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Assim como os generators, nós podemos usar múltiplos filtros. Vamos expandir nosso intervalo e então filtrar apenas para valores que sejam pares e também divisíveis por 3.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Usando `:into`

E se nós quisermos produzir algo que não seja uma lista? Passando a opção `:into` nós podemos fazer exatamente isso! Como uma regra geral, `:into` aceita qualquer estrutura que implemente o protocolo `Collectable`.

Usando `:into`, vamos criar um mapa de uma lista de palavras-chave.

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Como bitstrings implementam collectables nós podemos usar comprehensions e `:into` para criar strings:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

É isso! Comprehensions são um modo fácil de iterar por coleções de maneira concisa.
