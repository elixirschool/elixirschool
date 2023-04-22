%{
  version: "1.0.1",
  title: "Mox",
  excerpt: """
  Mox est une librairie pour concevoir des mocks qui fonctionnent de façon simultanée en Elixir.
  """
}
---

## Écrire du code que l'on peut tester

Les tests, ainsi que les mocks qui les facilitent, ne sont en général pas les choses les plus impressionnantes d'un langage, ce n'est donc pas une surprise qu'il y ai moins de choses écrites à leur propos.
La bonne nouvelle, c'est que vous _pouvez_ utiliser les mocks en Elixir!
La méthodologie exacte est peut-être différente des habitudes que vous avez avec d'autres langages, mais le but final est le même: les mocks peuvent simuler la sortie d'une fonction interne, et ils nous permettent donc d'affirmer les réponses de toutes les exécutions possibles de notre code.

Avant de voir des cas d'utilisation complexes, parlons d'abord des techniques qui peuvent nous aider à rendre notre code plus facile à tester.
Une tactique simple est de passer un module à une fonction en tant que paramètre, plutôt que de donner en dur le module à l'intérieur de la fonction.

Par exemple, si on codait en dur un client HTTP dans une fonction :

```elixir
def get_username(username) do
HTTPoison.get("https://elixirschool.com/users/#{username}")
end
```

On pourrait plutôt passer le module du client HTTP en tant qu'argument, de cette façon :

```elixir
def get_username(username, http_client) do
http_client.get("https://elixirschool.com/users/#{username}")
end
```

On pourrait utiliser la fonction [apply/3](https://hexdocs.pm/elixir/Kernel.html#apply/3) pour accomplir la même tâche :

```elixir
def get_username(username, http_client) do
apply(http_client, :get, ["https://elixirschool.com/users/#{username}"])
end
```

Passer le module en tant qu'argument aide à séparer les responsabilités, et si nous ne nous égarons pas trop sur le verbiage orienté objet de la définition, on peut reconnaitre cette inversion de contrôle comme une [Dépendance d'Injection](https://en.wikipedia.org/wiki/Dependency_injection).
Pour tester la méthode `get_username/2`, on aura seulement besoin de passer un module dont la fonction `get` retourne la valeur nécessaire pour nos assertions.

Ce concept est très simple, et est seulement utile quand la fonction est hautement accessible (et pas, par exemple, enfouie aux fins fonds d'une fonction privée).

Une tactique plus flexible serait de se baser sur la configuration de l'application.
Peut-être ne l'avez-vous pas réalisé, mais une application Elixir conserve l'état dans sa configuration.
Plutôt que de coder en dur un module ou de le passer comme argument, on peut le lire depuis la config de l'application.

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

Puis, dans notre fichier config:

```elixir
config :my_app, :http_client, HTTPoison
```

Ce concept et sa dépendance à la config de l'application forme la base de tout ce qui suit.

Oui, on pourrait omettre la fonction `http_client/0` et appeler `Application.get_env/2` directement, et oui, on pourrait aussi donner un troisième argument par défaut à `Application.get_env/3` et arriver au même résultat.

Tirer parti de la config de l'application nous permet d'avoir des implémentations spécifiques du module pour chaque environnement ; on peut référencer un module sandbox pour l'environnement `dev`, alors que l'environnement `test` peut utiliser un module en mémoire.

Cependant, avoir seulement un module fixe par environnement peut ne pas être assez flexible : en fonction de comment notre fonction est utilisée, on peut avoir besoin de retourner des réponses différentes afin de tester tous les cas d'exécutions possibles.
Ce que la plupart ne savent pas, c'est que l'on peut _changer_ la configuration de l'application au moment de lancer !
Regardons [Application.put_env/4](https://hexdocs.pm/elixir/Application.html#put_env/4).

Imaginons que notre application a besoin de se comporter différemment en fonction de si notre requête HTTP a réussi.
On pourrait créer plusieurs modules, chacun avec sa propre fonction `get/1`.
Un module pourrait retourner un tuple `:ok`, et l'autre pourrait retourner un tuple `:error`.
Ensuite, on pourrait utiliser `Application.put_env/4` pour mettre en place la configuration avant d'appeler notre fonction `get_username/1`.
Notre module de test ressemblerait à ceci :

```elixir
# Don't do this!
defmodule MyAppTest do
  use ExUnit.Case

  setup do
    http_client = Application.get_env(:my_app, :http_client)
    on_exit(
      fn ->
        Application.put_env(:my_app, :http_client, http_client)
      end
    )
  end

  test ":ok on 200" do
    Application.put_env(:my_app, :http_client, HTTP200Mock)
    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    Application.put_env(:my_app, :http_client, HTTP404Mock)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

On assume que les modules requis ont été créés (`HTTP200Mock` and `HTTP404Mock`).
On ajoute [`on_exit`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#on_exit/2) callback to the [`setup`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#setup/1) pour être sûr que le `:http_client` soit retourné à son état précédent après chaque test.

Cependant, un format comme celui que l'on vient de voir n'est en général _PAS_ quelque chose que l'on doit suivre !
Les raisons peuvent ne pas paraître évidentes de suite.

Tout d'abord, il n'y a rien qui nous garantis que les modules que l'on définit pour notre `:http_client` puissent faire ce que l'on veut qu'ils fassent : rien ne leur impose d'avoir une fonction `get/1`.

Ensuite, les tests comme ceux que l'on vient de voir ne peuvent pas être exécutés en toute sécurité de façon asynchrone.
L'état de l'application est partagé par l'application _dans son entièreté_, c'est donc possible que lorsque l'on outrepasse le `:http_client` dans un test, un autre test (qui est exécuté de façon simultanée) soit affecté alors qu'il attend un résultat différent.
Vous pouvez avoir eu des problèmes similaires, avec des tests qui passent _en général_, mais parfois ne passent pas, sans explication.

Pour finir, cette approche peut devenir compliquée, car on peut finir avec plein de modules mock cachés dans les recoins de notre application, et ça... Ce n'est pas très propre !

Nous avons montré la structure au-dessus, car elle dessine les grandes lignes de la solution de façon assez directe, et nous aide à comprendre comment la _vrai_ solution fonctionne.

## Mox : La Solution à tout les Problèmes

Le package de choix pour travailler avec des mocks en Elixir est [Mox](https://hexdocs.pm/mox/Mox.html), créé par José Valim lui-même, et il résout tous les problèmes que l'on vient de voir.

Rappel : comme pré-requis, notre code doit aller chercher les modules dans la config de l'application.

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

Ensuite, on peut inclure `mox` dans nos dépendences.

```elixir
# mix.exs
defp deps do
  [
    # ...
    {:mox, "~> 0.5.2", only: :test}
  ]
end
```

Installez le avec `mix deps.get`.

Ensuite, modifiez votre `test_helper.exs` afin qu'il fasse ces deux choses :

1. Il doit définir un ou plusieurs mocks
2. Il doit mettre en place la config d'application avec le mock.

```elixir
# test_helper.exs
ExUnit.start()

# 1. définis des mocks dynamiques
Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# ... etc...

# 2. passe outre les paramètres de la config (même résultat que si on les ajoutait à config/test.exs) 
Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)
# ... etc...
```

Quelques choses importantes à noter à propos de `Mox.defmock` : le nom à gauche est arbitraire.
Les noms de modules en Elixir sont des atomes -- vous n'avez pas besoin de créer le module, vous "réservez" un nom pour le module mock.
Derrière les rideaux, Mox va créer le module avec ce nom directement dans le BEAM (Bogdan Erlang Abstract Machine, machine virtuelle Erlang).

Autre chose épineuse, le module référencé par `for:` _doit_ être un behaviour : il _doit_ définir des callbacks.
Mox utilise l'introspection sur ce module et on peut définir des fonctions mock seulement quand un `@callback` a été défini.
C'est ainsi que Mox applique un contrat.
Parfois, il peut être difficile de trouver le module behaviour: `HTTPoison` par exemple, se base sur `HTTPoison.Base`, mais on ne le sait pas à moins d'aller voir le code source.
Si vous essayez de créer un mock pour un package tiers, vous découvrirez peut être qu'il n'existe pas de behaviour!
Dans ces cas, vous aurez peut-être besoin de définir vos propre behavious et callbacks pour satisfaire les besoins du contrat.

Cela nous amène à un point important : vous aurez peut-être besoin d'utiliser une couche d'abstraction (a.k.a. [indirection](https://en.wikipedia.org/wiki/Indirection)) pour que votre application ne dépende pas _directement_ d'un package tiers, et plutôt utiliser votre propre module, qui lui-même utilise ce package tiers. 
Il est important pour une application bien conçue de définir des "limites", mais les mécaniques des mocks ne changent pas, alors ne laissez pas ça vous importuner.

Enfin, dans notre module de test, on peut mettre nos mocks à l'usage en important `Mox` et appelant sa fonction `:verify_on_exit!`.
Ensuite, vous êtes libres de définir les valeurs de retour de votre module de mock en utilisant un ou plusieurs appels à la fonction `expect`.

```elixir
defmodule MyAppTest do
  use ExUnit.Case, async: true
  # 1. Import Mox
  import Mox
  # 2. setup fixtures
  setup :verify_on_exit!

  test ":ok on 200" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:ok, "What a guy!"} end)

    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:error, "Sorry!"} end)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

Pour chaque test, on référence le _même_ module de mock (`HTTPoison.BaseMock` dans cet exemple), et on utilise la fonction `expect` pour définir les valeurs de retour pour chaque fonction appelée.

Utiliser `Mox` est sûr pour les exécutions asynchrones, et requière que chacun des mocks suive un contrat.
Comme ces mocks sont "virtuels", il n'y a pas besoin de définir de vrais modules qui mettraient du désordre dans votre application.

Bienvenue à votre initiation aux mocks en Elixir!