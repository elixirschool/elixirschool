%{
  version: "1.1.0",
  title: "Traitement des erreurs",
  excerpt: """
  Bien qu'il soit commun pour les fonctions de retourner un tuple `{:error, reason}`, Elixir supporte les exceptions. Dans cette leçon, nous expliquons comment prendre en charge les erreurs, et nous passerons en revue les mécanismes disponibles.
  
  En général, la convention en Elixir est de créer une fonction (`example/1`) qui retourne `{:ok, result}` ou `{:error, reason}`, et une fonction à part (`example!/1`) qui retourne simplement `result` ou lève une erreur. Nous nous concentrerons sur le second cas dans cette leçon.
  """
}
---

## Conventions générales

Pour l'instant, la communauté d'Elixir a quelques conventions quant aux valeurs retournées par les fonctions :

* Pour les erreurs qui sont un produit attendu d'une fonction (p. ex. un utilisateur a inséré une date avec un format incorrect), la fonction retourne `{:ok, result}` ou `{:error, reason}`, selon le cas ;
* Pour les erreurs qui ne font pas partie du cours normal des opérations (p. ex. incapacité de lire des données de configuration), la fonction lève une exception.

Généralement, nous traitons le premier cas par [Pattern Matching](/fr/lessons/basics/pattern_matching) ; mais, dans cette leçon, nous nous concentrons sur le second cas : les exceptions.

Souvent, dans les *API* publiques, nous trouvons également une seconde version d'une fonction avec un `!` en suffixe (p. ex. `example!/1`). Dans ce cas, la convention est que cette fonction lève une erreur ou retourne directement le résultat.

## Traitement d'une erreur

Avant de traiter des erreurs, nous devons les créer, et le moyen le plus simple pour ce faire est d'utiliser `raise/1` :

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Si nous voulons spécifier le type et le message de l'erreur, nous devons utiliser `raise/2` :

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Quand nous savons qu'une erreur peut survenir, nous pouvons l'intercepter avec le couple `try` et `rescue`, et du *Pattern Matching* :

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Un même `rescue` peut intercepter plusieurs types d'erreurs :

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## Suite du traitement d'une erreur

Il peut être nécessaire de réaliser des actions après un couple `try` et `rescue`, peu importe qu'une erreur ait été interceptée ou non. Dans ce cas, nous disposons de `after`.
Si vous êtes familier avec Ruby, cela correspond au triptyque `begin/rescue/ensure`, ou à `try/catch/finally` en Java.

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

`after` est communément utilisé quand il faut fermer des fichiers ou des connexions :

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## Nouveaux types d'exceptions

Si Elixir comptent plusieurs types d'exceptions dans sa bibliothèque standard, telle que `RuntimeError`, nous avons la capacité de définir nos propres exceptions si besoin.

Créer une nouvelle exception passe par la macro `defexception/1`. Cette macro accepte l'option `:message` pour définir un message par défaut :

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Utilisons notre nouvelle exception :

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Lever une exception

Un autre mécanisme pour traiter des erreurs en Elixir est le couple `throw` et `catch`. Il est peu commun de croiser ces mots-clés dans du code Elixir récent, mais il est utile de les connaître et de les comprendre.

La fonction `throw/1` permet d'interrompre l'exécution d'une fonction avec une valeur particulière, interceptable grâce à `catch` :

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Comme nous l'avons indiqué, `throw` et `catch` sont plutôt rares et existent pour pallier aux insuffisances de certaines bibliothèques.

## Interrompre l'exécution du programme

Le dernier mécanisme d'erreur en Elixir est `exit`, qui permet de sortir du programme. Un signal de sortie est émis quand un processus meurt, et c'est une partie importante de la tolérance aux pannes en Elixir.

Pour explicitement sortir du programme, nous utilisons `exit/1` :

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Bien qu'il soit possible d'interception un signal de sortie avec `try` et `catch`, il est _extrêmement_ rare d'y avoir recours. Dans quasiment tous les cas, il est judicieux de laisser au superviseur le traitement des signaux de sortie :

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
