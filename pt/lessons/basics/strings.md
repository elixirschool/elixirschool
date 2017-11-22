---
version: 0.9.1
title: Strings
---

Strings, listas de caracteres, Graphemes e Codepoints.

{% include toc.html %}

## Strings

Strings em Elixir são nada mais que uma sequência de bytes. Vamos ver um exemplo:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
```

>NOTA: Ao usar a sintaxe com << >> estamos dizendo ao compilador que os elementos dentro desses símbolos são bytes.

## Listas de Caracteres

Internamente, as strings em Elixir são representadas como uma sequência de bytes ao invés de um array de caracteres. Elixir também tem um tipo char list (lista de caracteres). Strings em Elixir são delimitadas por aspas duplas, enquanto listas de caracteres são delimitadas por aspas simples.

Qual a diferença? Cada valor de uma lista de caracteres é o valor ASCII do caractere. Vamos ver isso mais a fundo:

```elixir
iex> char_list = 'hello'
'hello'

iex> [hd|tl] = char_list
'hello'

iex> {hd, tl}
{104, 'ello'}

iex> Enum.reduce(char_list, "", fn char, acc -> acc <> to_string(char) <> "," end)
"104,101,108,108,111,"
```

Ao programar em Elixir, geralmente usamos Strings ao invés de listas de caracteres. O suporte a listas de caracteres é incluso principalmente por ser obrigatório para alguns módulos Erlang.

## Graphemes e Codepoints

Codepoints são apenas caracteres Unicode simples que são representados por um ou mais bytes. Por exemplo, caracteres com o til ou acentos: `á, ñ, è`. Graphemes consistem de múltiplos codepoints que são renderizados como um único caractere.

O módulo String já fornece dois funções para obtê-los, `graphemes/1` e `codepoints/1`. Vamos ver um exemplo:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Funções de String

Vamos rever duas das funções mais importantes e úteis do módulo String. Essa lição cobrirá apenas uma parte das funções disponíveis. Para ver a lista completa de funções visite a documentação oficial de [`String`](https://hexdocs.pm/elixir/String.html).

### `length/1`

Retorna o número de Graphemes na string.

```elixir
iex> String.length "Hello"
5
```

### `replace/3`

Retorna uma nova string substituindo um padrão atual por uma nova string de substituição.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

Retorna uma nova string repetida n vezes.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

Retorna uma lista de strings divididas por um padrão.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Exercícios

Vamos ver alguns exercícios simples para demonstrar que estamos prontos para trabalhar com Strings!

### Anagramas

A e B são considerados anagramas se há alguma forma de rearranjar A ou B para torná-las iguais. Por exemplo:

+ A = super
+ B = perus

Se nós rearranjarmos os caracteres da string A, podemos obter a string B, e vice-versa.

Então, como podemos verificar se duas strings são Anagramas em Elixir? A solução mais fácil é apenas ordenar os graphemes de cada string em ordem alfabética e então verificar se as duas listas são iguais. Vamos tentar:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Primeiro vamos olhar para `anagrams?/2`. Estamos verificando se os parâmetros que recebemos são binários ou não. Essa é a forma de verificar se uma parâmetro é uma String em Elixir.

Depois disso, estamos chamando a função que ordena as strings em ordem alfabética, primeiro deixando a string em letras minúsculas e então usando `String.graphemes`, que retorna a lista com os Graphemes da string. Bastante simples, não acha?

Vamos verificar a saída dessa função no iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2
    iex:2: Anagram.anagrams?(3, 5)
```

Como você pode ver, a última chamada a `anagrams?` causou um FunctionClauseError. Esse erro nos diz que não há nenhuma função no nosso módulo de acordo com o padrão de receber dois argumentos não binários, e isso é exatamente o que nós queremos, receber apenas duas strings e nada mais.
