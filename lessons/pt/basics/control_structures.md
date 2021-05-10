%{
  version: "1.1.2",
  title: "Estruturas de Controle",
  excerpt: """
  Nesta lição iremos conhecer algumas estruturas de controle disponíveis em Elixir.
  """
}
---

## if e unless

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
Usar `unless/2` é bem parecido com o uso do `if/2` porém trabalhando de forma negativa:
```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## case

Caso seja necessário combinar múltiplos padrões nós poderemos utilizar `case/2`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```
A variável `_` é uma importante inclusão na declaração do `case/2`. Sem isso a falha em procura de combinação iria causar um erro:

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
Já que `case/2` depende de combinação de padrões, todas as mesmas regras e restrições são aplicadas. Se você pretende procurar padrões em variáveis que já existem, você irá precisar utilizar o operador pin `^/1`:

```elixir
iex> pie = 3.14
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```
Outra característica interessante do `case/2` é o seu suporte para cláusulas de guarda:

_Este exemplo vem diretamente do [Guia Introdutório](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) oficial do Elixir._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```
Verifique a documentação oficial sobre [Expressões permitidas em cláusulas guard](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).


## cond

Quando necessitamos associar condições, e não valores, nós podemos recorrer ao `cond/1`; Isso é semelhante ao `else if` ou `elsif` de outras linguagens:

_Este exemplo vem diretamente do [Guia Introdutório](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) oficial do Elixir._

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

Como `case/2`, `cond/1` irá gerar um erro caso não seja achado associação. Para lidar com isso, nós podemos definir a condição para `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

A forma especial `with/1` é útil quando tentamos usar `case/2` de maneira aninhada ou em situações que não é possível encadear funções. A expressão `with/1` é composta de palavras-chaves, generators e finalmente uma expressão.

Iremos discutir generators na [lição sobre list comprehensions](../comprehensions) para comparar o lado direito do operador `<-` com o lado esquerdo.

Vamos começar com um exemplo simples de `with/1` e então vamos olhar em algo mais:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

Quando uma expressão falha em achar um padrão, o valor da expressão que falhou será retornado:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Agora vamos olhar um exemplo maior sem `with/1` e então ver como nós podemos refatorar:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

Quando utilizamos `with/1` acabamos com um código que é facilmente entendido e possui menos linhas:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```

A partir do Elixir 1.3, `with/1`  suporta `else`:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
    true <- is_even(number) do
      IO.puts "#{number} divided by 2 is #{div(number, 2)}"
      :even
  else
    :error ->
      IO.puts("We don't have this item in map")
      :error

    _ ->
      IO.puts("It is odd")
      :odd
  end
```

Isso ajuda a lidar com erros provendo padrões parecido com o `case`. O valor passado para o else é o primeiro que não foi correspondido com o padrão em uma expressão.
