%{
  version: "1.2.0",
  title: "Strings",
  excerpt: """
  Strings, listas de caracteres, Graphemes e Codepoints.
  """
}
---

## Strings

Strings em Elixir são nada mais que uma sequência de bytes. Vamos ver um exemplo:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

Ao concatenar a string com o byte `0`, o IEx mostra a string como um binário já que este não é mais uma string válida. Este truque nos ajuda a identificar a sequência de bytes que compõem qualquer string.

>NOTA: Ao usar a sintaxe com << >> estamos dizendo ao compilador que os elementos dentro desses símbolos são bytes.

## Listas de Caracteres

Internamente, as strings em Elixir são representadas como uma sequência de bytes ao invés de um array de caracteres. Elixir também tem um tipo char list (lista de caracteres). Strings em Elixir são delimitadas por aspas duplas, enquanto listas de caracteres são delimitadas por aspas simples.

Qual a diferença? Cada valor em uma lista de caracteres corresponde ao número Unicode do caracter, enquanto em um binário os valores são codificados em UTF-8. Vamos ver isso mais a fundo:

```elixir
iex> 'hełło'
[104, 101, 322, 322, 111]
iex> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` é o número Unicode de ł, representado em UTF-8 pelos dois bytes `197`, `130`.

Você pode obter o codepoint de um caractere usando `?`

```elixir
iex> ?Z  
90
```

Isso permite usar a notação `?Z` em vez de 'Z' para um símbolo.

Ao programar em Elixir, geralmente usamos strings ao invés de listas de caracteres. O suporte a listas de caracteres é incluso principalmente por ser obrigatório para alguns módulos Erlang.

Para mais informação, veja o [`Guia de Introdução`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html) oficial.

## Graphemes e Codepoints

Codepoints são apenas simples caracteres Unicode representados por um ou mais bytes, dependendo da codificação UTF-8. Caracteres diferentes do padrão US ASCII são sempre codificados por mais de um byte. Por exemplo, caracteres latinos com til ou acentos (`á, ñ, è`) geralmente são codificados com dois bytes. Já caracteres de línguas asiáticas são normalmente codificados com três ou quatro bytes. Graphemes consistem de múltiplos codepoints que são apresentados como um único caractere.

O módulo String já fornece duas funções para gerá-los, `graphemes/1` e `codepoints/1`. Vamos ver um exemplo:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Funções de String

Vamos rever algumas das funções mais importantes e úteis do módulo String. Essa lição cobrirá apenas uma parte das funções disponíveis. Para ver a lista completa de funções visite a documentação oficial de [`String`](https://hexdocs.pm/elixir/String.html).

### length/1

Retorna o número de Graphemes na string.

```elixir
iex> String.length "Hello"
5
```

### replace/3

Retorna uma nova string substituindo o atual padrão na string por uma nova string de substituição.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### duplicate/2

Retorna uma nova string repetida n vezes.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### split/2

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

Primeiro vamos olhar para `anagrams?/2`. Estamos verificando se os parâmetros que recebemos são binários ou não. Essa é a forma de verificar se um parâmetro é uma String em Elixir.

Depois disso, chamamos a função que ordena as strings em ordem alfabética, primeiro deixamos a string com letras minúsculas e então usamos `String.graphemes/1`, que retorna a lista com os graphemes da string. Por fim, utilizamos `Enum.sort/1` para ordenar a lista. Bastante simples, não acha?

Vamos verificar a saída dessa função no iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

Como você pode ver, a última chamada a `anagrams?` causou um `FunctionClauseError`. Esse erro nos diz que não há nenhuma função no nosso módulo que recebe dois argumentos não binários, e isso é exatamente o que nós queremos, receber apenas duas strings e nada mais.
