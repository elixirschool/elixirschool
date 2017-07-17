---
version: 0.9.0
title: Estruturas de Controle
---

Nesta lição iremos conhecer algumas estruturas de controle disponíveis em Elixir.

{% include toc.html %}

## `if` e `unless`

Existem chances de que você já tenha encontrado `if/2` antes, e caso você tenha utilizado Ruby você é familiarizado com `unless/2`. Em Elixir eles trabalham praticamente da mesma forma porém são definidos como macros, não construtores da linguagem; Você pode encontrar a implementação deles em [Kernel module](https://hexdocs.pm/elixir/Kernel.html).

Pode-se notar que em Elixir, os únicos valores falsos são `nil` e o booleano `false`.

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```
Usar `unless/2` é bem parecido o uso do `if/2` porém trabalhando de forma negativa:
```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

Caso seja necessário combinar multiplos padrões nós poderemos utilizar `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```
A variável `_` é uma importante inclusão na declaração do `case`. Sem isso a falha em procura de combinação iria causar um erro:

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

Considere `_` como o `else` que irá igualar com "todo o resto".
Já que `case` depende de combinação de padrões, todas as mesmas regras e retrições são aplicadas. Se você pretende procurar padrões em variáveis que já existem, você irá precisar utilizar o operador pin `^`:

```elixir
iex> pie = 3.14
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```
Outra característica interessante do `case` é o seu suporte para cláusulas de guarda:

_Este exemplo vem diretamente do [Guia Introdutório](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) oficical do Elixir._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```
Verifique a documentação oficial sobre [Expressões permitidas em clausulas guard](http://elixir-lang.org/getting-started/case-cond-and-if.html#expressions-in-guard-clauses).


## `cond`

Quando necessitamos associar condições, e não valores, nós podemos recorrer ao `cond`; Isso é semelhante ao `else if` ou `elsif` de outras linguagens:

Este exemplo vem diretamente do [Guia Introdutório](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) oficial do Elixir._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

Como `case`, `cond` irá gerar um erro caso não seja achado associação. Para lidar com isso, nós podemos definir a condição para `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```
