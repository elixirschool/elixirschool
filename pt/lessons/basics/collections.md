---
version: 1.3.1
title: Coleções
---

Listas, tuplas, listas de palavras-chave e mapas.

{% include toc.html %}

## Listas

As listas são simples coleções de valores que podem incluir múltiplos tipos; listas também podem incluir valores não-exclusivos:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementa listas como listas encadeadas.
Isso significa que acessar o tamanho da lista é uma operação que rodará em tempo linear (`O(n)`).
Por essa razão, é normalmente mais rápido inserir um elemento no início (`prepending`) do que no final (`appending`):

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Prepending (rápido)
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
# Appending (lento)
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Concatenação de listas

A concatenação de listas usa o operador `++/2`.

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Uma pequena nota sobre o formato de nome (`++/2`) usado acima.
Em Elixir (e Erlang, sobre o qual Elixir é construído), o nome de uma função ou operador tem dois componentes: o nome em si (neste caso `++`) e sua _aridade_.
Aridade é uma parte central quando se fala sobre código Elixir (e Erlang).
Indica o número de argumentos que uma dada função aceita (dois, nesse nosso exemplo).
Aridade e o nome são combinados com uma barra. Falaremos mais sobre isto mais tarde; este conhecimento irá ajudá-lo a entender a notação por enquanto.

### Subtração de listas

O suporte para subtração é provido pelo operador `--/2`; é seguro subtrair um valor que não existe:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Esteja atento para valores duplicados.
Para cada elemento na direita, a primeira ocorrência deste é removida da esquerda:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Nota:** subtração de listas usa [comparação estrita](../basics/#comparação) para match de valores. Por exemplo:

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Topo / Cauda

Quando usamos listas é comum trabalhar com o topo e o fim da lista.
O topo é o primeiro elemento da lista e a cauda são os elementos restantes.
Elixir provê duas funções bem úteis, `hd` e `tl`, para trabalhar com essas partes:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Além das funções citadas, pode-se usar [pattern matching](../pattern-matching) e o operador cons (`|`) para dividir a lista em topo e cauda; veremos este padrão em futuras lições:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuplas

As tuplas são similares às listas porém são armazenadas de maneira contígua em memória.
Isto permite acessar seu tamanho de forma rápida porém sua modificação é custosa; a nova tupla deve ser armazenada inteira na memória.
As tuplas são definidas com chaves.

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

É comum usar tuplas como um mecanismo que retorna informação adicional de funções; a utilidade disso ficará mais aparente quando vermos [pattern matching](../pattern-matching/):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Listas de palavras-chave

As listas de palavras-chave e os mapas são coleções associativas no Elixir.
No Elixir, uma lista de palavras-chave é uma lista especial de tuplas de dois elementos cujo o primeiro elemento é um átomo; eles compartilham o desempenho das listas:

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

Em Elixir, mapas normalmente são a escolha para armazenamento chave-valor.
A diferença entre os mapas e as listas de palavras-chave está no fato de que os mapas permitem chaves de qualquer tipo e não seguem uma ordem.
Você pode definir um mapa com a sintaxe `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

A partir do Elixir 1.2, variáveis são permitidas como chaves do mapa:

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

Como podemos ver na saída anterior, há uma sintaxe especial para os mapas que contém apenas átomos como chaves:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Além disso, existe uma sintaxe especial para acessar átomos como chaves:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

Outra propriedade interessante de mapas é que eles têm sua própria sintaxe para atualizar e acessar átomos como chaves:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```

**Nota**: esta sintaxe funciona apenas para atualizar uma chave que já existe no mapa! Se a chave não existir, um `KeyError` será gerado.

Para criar uma nova chave, use [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3)

```elixir
iex> map = %{hello: "world"}
%{hello: "world"}
iex> %{map | foo: "baz"}
** (KeyError) key :foo not found in: %{hello: "world"}
    (stdlib) :maps.update(:foo, "baz", %{hello: "world"})
    (stdlib) erl_eval.erl:259: anonymous fn/2 in :erl_eval.expr/5
    (stdlib) lists.erl:1263: :lists.foldl/3
iex> Map.put(map, :foo, "baz")
%{foo: "baz", hello: "world"}
```
