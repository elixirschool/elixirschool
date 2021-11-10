%{
  version: "1.0.2",
  title: "Pattern Matching",
  excerpt: """
  Pattern matching é uma poderosa parte de Elixir que nos permite procurar padrões simples em valores, estruturas de dados, e até funções. Nesta lição iremos começar a ver como pattern matching é usado.
  """
}
---

## Operador Match

Você está preparado para ficar um pouco confuso? Em Elixir, o operador `=` é na verdade o nosso operador match, comparável ao sinal de igualdade da matemática. Quando usado, a expressão inteira se torna uma equação e faz com que Elixir combine os valores do lado esquerdo com os valores do lado direito da expressão. Se a comparação for bem sucedida, o valor da equação é retornado. Se não, um erro é lançado. Vejamos a seguir:

```elixir
iex> x = 1
1
```

Agora vamos tentar a simples correspondência:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Vamos tentar isso com algumas das coleções que nós conhecemos:

```elixir
# Listas
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2 | _] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuplas
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Operador Pin

Acabamos de aprender que o operador match manuseia atribuições quando o lado esquerdo da associação é uma variável. Em alguns casos este comportamento de reassociação de variável é algo não desejável. Para estas situações, nós temos o operador pin:`^`.

Quando fixamos a variável em associação ao valor existente ao invés de reassociar a um novo valor. Vamos ver como isso funciona:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```
Elixir 1.2 introduziu suporte para pins em chaves de mapas e cláusulas de função:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

Um exemplo do uso do pin em uma cláusula de função:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
iex> greeting
"Hello"
```

Note que no exemplo `"Mornin'"`, a reassociação de `greeting` para `"Mornin'"` só acontece dentro de uma função. Fora da função, `greeting` continua sendo `"Hello"`.
