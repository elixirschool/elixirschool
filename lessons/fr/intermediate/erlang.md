%{
  version: "1.0.3",
  title: "Interopérabilité Erlang",
  excerpt: """
  Un des bénéfices de coder par dessus la VM Erlang (BEAM) provient de la pléthore de librairies existantes disponibles.
  L'interoperabilité permet d'utiliser ces librairies et la librairie standard d'Erlang depuis notre code Elixir.
  Dans cette leçon nous allons voir comment nous pouvons accéder aux fonctionnalités de la librairie standard d'Erlang mais aussi les librairies tierces d'Erlang.
  """
}

---

## Librairie standard

On accède à la librairie standard étendue d'Erlang depuis n'importe quel code Elixir dans notre application.
Les modules d'Erlang sont représentés par des atomes en minuscule comme `:os` et `:timer`.

Utilisons `:timer.rc` pour chronométrer l'exécution d'une fonction:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

Pour connaître la liste complètes des modules disponibles, voir la documentation de la [librairie standard d'Erlang](http://erlang.org/doc/apps/stdlib/).

## Librairies tierces d'Erlang

Dans une leçon précédente nous avons couvert Mix et la gestion de nos dépendances.
Les librairies d'Erlang fonctionnent de la même façon.
Dans l'éventualité où la librairie Erlang n'existe pas sur [Hex](https://hex.pm) vous pouvez faire une référence au dépôt git à la place.

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Nous pouvons ensuite accéder à la librairie Erlang :

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Différences notables

Maintenant que nous connaissons comment utiliser Erlang nous devons couvrir quelques-uns des pièges qui se cachent avec l'interopérabilité d'Erlang.

### Atomes

Les atomes Erlang sont similaires à ceux d'Elixir sans le double point (`:`) :
Ils sont représentés par des chaines de caractères en minuscule et des tiret bas :

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Chaînes

Les chaînes dans Elixir sont en fait des suites d'octets encodés en UTF-8.
Pour Erlang les chaînes utilisent aussi les double guillemets mais font références à une liste de caractères+:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

Il est important de noter que certaines librairies anciennes d'Erlang peuvent ne pas supportes les suites d'octets donc nous devons convertir les chaînes Elixir en listes de caractères.
Heureusement la conversion est facile avec la fonction `to_charlist/1` :

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist() |> :string.words
2
```

### Variables

Avec Erlang les variables commencent par une lettre majuscule et la re-déclaration n'est pas autorisée.

Elixir:

```elixir
iex> x = 10
10

iex> x = 20
20

iex> x1 = x + 10
30
```

Erlang:

```erlang
1> X = 10.
10

2> X = 20.
** exception error: no match of right hand side value 20

3> X1 = X + 10.
20
```

Et voilà! Tirer parti d'Erlang depuis nos applications Elixir est facile et double le nombre de librairies disponibles.
