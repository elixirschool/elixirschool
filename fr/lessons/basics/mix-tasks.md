---
version: 0.9.1
title: Tâches Mix Personnalisées
---

Créer des tâches Mix personnalisées pour votre projet Elixir.

{% include toc.html %}

## Introduction

Il n'est pas rare de vouloir étendre les fonctionnalités des applications Elixir en y ajoutant des tâches Mix personnalisées. Avant d'apprendre à en créer pour votre projet, jettons un coup d'oeil à une qui existe déjà:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Comme nous pouvons le voir dans la commande ci-dessus, le framework Phoenix dispose d'une tâche Mix pour générer un nouveau projet. Et si nous pouvions faire pareil dans notre projet? Et bien, la bonne nouvelle c'est que c'est possible et de façon très simple.

## Initialisation

Commençons par créer une application minimaliste avec Mix.

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Ensuite, dans le fichier **lib/hello.ex** que Mix a généré pour nous, créons une fonction pour afficher "Hello, World!"

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Tâche Mix

Créons maintenant la tâche Mix. Ajoutez le fichier **hello/lib/mix/tasks/hello.ex** et placez-y les 7 lignes suivantes:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Notez comment nous avons déclaré `defmodule` avec `Mix.Tasks` et le nom que nous voulons donner à la commande. Sur la seconde ligne, nous avons ajouté `use Mix.Task` qui inclut les fonctionnalités de `Mix.Task` dans l'espace de noms. Ensuite, nous déclarons la function `run`qui ne prend aucun argument pour le moment. Dans cette fonction, nous appellons le module `Hello` et sa fonction `say`.

## Tâches Mix en Action

Vérifions maintenant notre tâche Mix. Du moment que nous restons dans le même répertoire, cela devrait marcher. Exécutez `mix hello` dans la ligne de commande et vous devriez voir:

```shell
$ mix hello
Hello, World!
```

Mix est assez sympatique de nature. Il sait qu'il nous arrive de faire des erreurs de saisie ici et là, ainsi, il nous remonte des propositions le cas échéant:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Avez-vous remarqué que nous avons introduit un nouvel attribut de module, `@shortdoc`? Il nous est très utile lors de lancement de notre application, comme quand un utilisateur éxécute `mix help`  dans la ligne de commande.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
