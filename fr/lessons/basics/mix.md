---
version: 0.9.0
title: Mix
---

Avant de plonger dans les profondeurs d'Elixir, nous devons d'abord apprendre mix. Si vous êtes familier avec Ruby, mix est l'équivalent de Bundler, Rubygems, et Rake combinés. C'est une part primordiale de tout projet Elixir et dans cette leçon nous allons explorer quelques une de ses fonctionnalités. Pour voir tout ce que mix permet de faire, lancez `mix help`.

Jusqu'ici nous avons travaillé exclusivement dans `iex`, ce qui a ses limitations. Dans le cas d'un projet réel nous avons besoin de séparer notre code dans différents fichiers, et mix est là pour nous aider à les gérer efficacement.

{% include toc.html %}

## Nouveau projet

Mix rend facile la création d'un nouveau projet avec la commande `mix new`. Cela génére la structure de dossiers de notre projet et crée les fichiers de base. C'est tout simple, allons-y:

```bash
$ mix new example
```

On peut lire dans les messages de sortie que mix a créé notre dossier et un certain nombre de fichiers:

```bash
* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

Dans cette leçon nous allons nous intéresser au fichier `mix.exs`, où on configure notre application, ses dépendances, son environnement et sa version. Ouvrez le fichier dans votre éditeur préféré, vous devriez voir quelque chose comme ça (les commentaires ont été supprimés pour plus de concision):

```elixir
defmodule Example.Mixfile do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

La première section qui nous intéresse est `project`. On y définit le nom de notre application (`app`), on spécifie la version (`version`), la version d'Elixir (`elixir`), et enfin nos dépendances (`deps`).

La section `application` est utilisée pendant la génération de notre fichier d'application, que nous verrons par la suite.

## <a name="interactif"></a>Intéractif

Il peut être nécessaire d'utiliser `iex` dans le contexte de notre application. Heureusement, mix rend ça facile. On peut commencer une nouvelle session `iex`:

```bash
$ iex -S mix
```

Démarrer `iex` de cette façon va charger notre application et ses dépendances dans le contexte d'exécution.

## Compilation

Mix est malin et ne compile que ce qui est nécessaire, mais il faut tout de même lancer la compilation de votre projet explicitement. Dans cette section nous verrons comment compiler notre projet et ce que fait la compilation.

Pour compiler un projet mix nous avons simplement besoin de lancer `mix compile` dans notre répertoire de base:

```bash
$ mix compile
```

Il n'y a pas grand chose dans notre projet donc la sortie n'est pas très passionnante, mais elle devrait terminer avec succès:

```bash
Compiled lib/example.ex
Generated example app
```

Quand on compile un projet, mix crée un dossier `_build` pour nos artefacts. Si on regarde dans ce dossier `_build` on y trouve notre applicaton compilée `example.app`.

## <a name="gestion-des-dependances"></a>Gestion des dépendances

Notre projet n'a aucune dépendance mais en aura bientôt, donc allons-y et voyons comment définir des dépendances et les obtenir.

Pour ajouter une nouvelle dépendance, on la définit dans notre `mix.exs` dans la section `deps`. La liste des dépendances est constituée de tuples de deux valeurs requises et une optionnelle: le nom du paquet (un atome), la version (une chaîne de caractères), et d'éventuelles options.

Pour cet exemple, regardons les dépendances d'un projet existant, comme [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

Comme vous l'avez probablement compris, la dépendance à `cowboy` est nécessaire uniquement pendant les phases de développement et de test.

Une fois nos dépendances définies, il reste une dernière étape, les obtenir. C'est similaire à `bundle install`:

```bash
$ mix deps.get
```

Et voilà ! Nous avons défini et obtenu nos dépendances. On est maintenant prêt à en ajouter quand cela sera nécessaire.

## Environnements

Mix, tout comme Bundler, supportes différents environnements. De base, mix fonctionne avec trois environnements:

+ `:dev` — L'environnement par défaut.
+ `:test` — Utilisé par `mix test`. Couvert plus loin dans la leçon suivante.
+ `:prod` — Utilisé quand l'application fonctionne en production.

L'environnement courant peut être accédé en utilisant `Mix.env`. Il peut être modifié via la variable d'environnemnt `MIX_ENV`:

```bash
$ MIX_ENV=prod mix compile
```
