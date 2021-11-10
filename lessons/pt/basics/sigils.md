%{
  version: "1.0.2",
  title: "Sigils",
  excerpt: """
  Trabalhando e criando sigils.
  """
}
---

## Overview sobre Sigils

Elixir fornece uma sintaxe alternativa para representar e trabalhar com literais.
Um sigil (símbolo especial) vai começar com um til `~` seguido por um caractere.
O núcleo do Elixir fornece-nos alguns sigils, no entanto, é possível criar o nosso próprio quando precisamos estender a linguagem.

Uma lista de sigils disponíveis incluem:

  - `~C` Gera uma lista de caracteres **sem** escape ou interpolação
  - `~c` Gera uma lista de caracteres **com** escape e interpolação
  - `~R` Gera uma expressão regular **sem** escape ou interpolação
  - `~r` Gera uma expressão regular **com** escape e interpolação
  - `~S` Gera strings **sem** escape ou interpolação
  - `~s` Gera string **com** escape e interpolação
  - `~W` Gera uma lista **sem** escape ou interpolação
  - `~w` Gera uma lista **com** escape e interpolação
  - `~N` Gera uma `NaiveDateTime` struct

Uma lista de delimitadores inclui:

  - `<...>` Um par de brackets
  - `{...}` Um par de chaves
  - `[...]` Um par de colchetes
  - `(...)` Um par de parênteses
  - `|...|` Um par de pipes
  - `/.../` Um par de barras
  - `"..."` Um par de aspas duplas
  - `'...'` Um par de aspas simples

### Lista de Caracteres

O `~c` e `~C` sigils geram listas de caracteres respectivamente.
Por exemplo:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Podemos ver em letra minúscula `~c` interpolando o cálculo, enquanto um sigil de letra maiúscula `~C` não.
Veremos que esta sequência maiúscula / minúscula é um tema comum em toda a construção de sigils.

### Expressões Regulares

O `~r` e `~R` sigils são usados para representar Expressões Regulares.
Nós criamos ambos dentro de funções `Regex`.
Por exemplo:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Podemos ver que no primeiro teste de igualdade, `Elixir` não coincide com a expressão regular.
Isso acontece porque ele está utilizando letra maiúscula.
Pelo fato de Elixir suportar expressões regulares compatíveis com Perl (PCRE), podemos acrescentar `i` ao final do nosso sigil para ligar maiúsculas e minúsculas.

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Além disso, Elixir fornece a API [Regex](https://hexdocs.pm/elixir/Regex.html), que é construída em cima da biblioteca de expressão regular do Erlang.
Vamos implementar `Regex.split/2` usando um sigil regex.

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Como podemos ver, a string `"100_000_000"` é dividida nas barras sublinhadas graças ao nosso `~r/_/` sigil.
A função `Regex.split` retorna uma lista.

### String

O `~s` e `~S` sigils são usados para gerar dados de String.
Por exemplo:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Mas qual é a diferença? A diferença é semelhante ao sigil da lista de palavras em que estamos procurando.
A resposta é interpolação e o uso de sequências de escape.
Se pegarmos outro exemplo:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Lista de Palavras

A lista de palavras do tipo sigil pode ser muito útil.
Pode lhe economizar tempo, digitação e possivelmente, reduzir a complexidade dentro da base de código.
Veja este exemplo simples:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Podemos ver que o que é digitado entre os delimitadores é separado por espaços em branco em uma lista.
No entanto, não existe qualquer diferença entre estes dois exemplos.
Novamente, a diferença vem com as seguintes sequências de interpolação e escape.
Veja o seguinte exemplo:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

Uma [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) pode ser bem útil para criar rapidamente uma struct que representa um `DateTime` **sem** um timezone.

Geralmente, nós devemos evitar criar uma `NaiveDateTime` struct diretamente.
No entanto, é muito útil para pattern matching.
Por exemplo:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

## Criando Sigils

Um dos objetivos do Elixir é ser uma linguagem de programação extensível.
Não é surpresa então que você possa facilmente criar o seu próprio sigil customizado.
Neste exemplo, vamos criar um sigil para converter uma cadeia para letras maiúsculas.
Como já existe uma função para isso no núcleo do Elixir (`String.upcase/1`), vamos embrulhar o nosso sigil em torno desta função.

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

Primeiro definimos um módulo chamado `MySigils` e dentro deste módulo, criamos uma função chamada `sigil_u`. 
Como não existe nenhum sigil `~u` no espaço de sigil existente, vamos usá-lo.
O `_u` indica que desejamos usar `u` como caractere depois do til.
A definição da função deve receber dois argumentos, uma entrada e uma lista.
