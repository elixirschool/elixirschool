%{
  version: "1.1.1",
  title: "Structures de Contrôle",
  excerpt: """
  Dans cette leçon nous allons voir les structures de contrôle à notre disposition dans Elixir.
  """
}
---

## if et unless

Il y a des chances que vous ayez déjà rencontré `if/2` auparavant, et si vous avez utilisé Ruby `unless/2` vous est familier. En Elixir ils fonctionnent de la même façon mais sont définis comme des macros, pas des constructions du language. Vous trouverez leur implementation dans le [module Kernel](https://hexdocs.pm/elixir/Kernel.html).

A noter en Elixir, les seules valeurs équivalentes à `false` sont `nil` et le booléen `false`.

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

`unless/2` s'utilise come `if/2` mis à part qu'il fonctionne sur la négation:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## case

S'il est nécessaire de tester plusieurs motifs nous pouvons utiliser `case/2`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

La variable `_` est une inclusion importante dans les déclarations `case/2`. Sans celle-ci, l'impossibilité de trouver une correspondance générera une erreur:

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

Considérez `_` comme le `else` qui correspondra à "tout les autres valeurs".

Comme `case/2` se base sur le pattern matching, les mêmes règles et restrictions s'appliquent. Si vous voulez tester une valeur par rapport à une variable existante, vous devez utiliser l'opérateur pin `^/1`:

```elixir
iex> pie = 3.14 
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Un autre caractéristique sympa de `case/2` est son support des clauses de garde:

_Cet exemple est tiré du [guide officiel Elixir](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

La documentation pour [les expressions permises dans les clauses de garde](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).


## cond

Lorsque nous avons besoin de faire correspondre des conditions et non des valeurs, nous pouvons utiliser `cond/1`; un peu comme `else if` ou `elsif` dans d'autres langages:

_Cet exemple est tiré du [guide officiel Elixir](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

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

Comme `case/2`, `cond/1` générera une erreur s'il n'y a pas de correspondance. Pour palier à ca, on peux définir une condition `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

La forme spécifique `with/1` s'utilise dans les cas où l'on pourrait avoir besoin d'un `case/2` imbriqué ou dans des situations qu'on ne peut pas enchainer de manière propre. L'expression `with/1` est composée de mots clés, de générateurs, et finalement d'une expression.

On discutera plus en profondeur des générateurs dans la [leçon sur les compréhensions de listes](../comprehensions/), mais pour le moment nous avons juste besoin de savoir qu'ils utilisent le [pattern matching](../pattern-matching/) pour comparer le coté droit du `<-` au coté gauche.

Commençons par un exemple simple de `with/1` avant d'aller voir des exemples plus complexes:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

Si une expression ne correspond pas, la valeur de cette non-correspondance sera retournée:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Regardons maintenant un exemple plus important sans `with/1` et voyons comment nous pouvons l'améliorer:

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

En utilisant `with/1` nous obtenons un code facile à comprendre et beaucoup plus concis:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```


Depuis Elixir 1.3, la déclaration `with/1` supporte `else`:

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

Il aide à gérer les erreurs en fournissant un pattern matching rappelant `case`. La valeur utilisée est la première valeur de non-correspondance.
