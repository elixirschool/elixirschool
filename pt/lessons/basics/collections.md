---
layout: page
title: Coleções
category: basics
order: 2
lang: pt
---

Listas, tuplas, listas de palavras-chave, mapas, dicionários e combinadores funcionais.

{% include toc.html %}

## Listas

As listas são simples coleções de valores, elas podem incluir múltiplos tipos; listas podem incluir valores não-exclusivos:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementa listas como listas encadeadas. Isso significa que acessar a profundidade da lista é uma operação `O(n)`. Por essa razão, é normalmente mais rápido inserir um elemento no início do que no final.

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Concatenação de listas

A concatenação de listas usa o operador `++/2`.

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Subtração de listas

O suporte para subtração é provido pelo operador `--/2`; é seguro subtrair um valor que não existe:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

### Topo / Cauda

Quando usamos listas é comum trabalhar com o topo e o fim da lista. O topo é o primeiro elemento da lista e a cauda são os elementos restantes. Elixir provê funções úteis, `hd` e `tl`, para trabalhar com essas partes:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Além das funções citadas, pode-se usar [pattern matching](../pattern-matching) e o operador cons `|` para dividir a lista em topo e cauda; veremos este padrão em futuras lições:

```elixir
iex> [h|t] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> h
3.14
iex> t
[:pie, "Apple"]
```

## Tuplas

As tuplas são similares as listas porém são armazenadas de maneira contígua em memória. Isto permite acessar a sua profundidade de forma rápida porém sua modificação é custosa; a nova tupla deve ser armazenada inteira na memória. As tuplas são definidas com chaves.

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

É comum usar tuplas como um mecanismo que retorna informação adicional de funções; a utilidade disso ficará mais aparente quando vermos pattern matching:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Listas de palavras-chave

As listas de palavras-chave e os mapas são coleções associativas no Elixir; ambas implementam o módulo `Dict`. No Elixir, uma lista de palavras-chave é uma lista especial de tuplas cujo o primeiro elemento é um átomo; eles compartilham o desempenho das listas:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

As três características relevantes das listas de palavras-chave são:

+ As chaves são átomos.
+ As chaves estão ordenadas.
+ As chaves não são únicas.

Por essas razões as listas de palavras-chave são frequentemente usadas para passar opções a funções.

## Mapas

A diferença entre os mapas e as listas de palavras-chave está no fato de que os mapas permitem chaves de qualquer tipo e não segue uma ordem. Você pode definir um mapa com a sintaxe `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Em Elixir 1.2, variáveis são permitidas como chaves do mapa:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Se um elemento duplicado é inserido no mapa, este sobrescreverá o valor anterior;

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Como podemos ver na saída anterior, há uma sintaxe especial para os mapas que contem átomos como chaves:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Outra propriedade interessante de mapas é que eles têm sua própria sintaxe para atualizar e acessar átomos como chaves:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```
