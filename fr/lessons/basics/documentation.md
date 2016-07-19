---
layout: page
title: Documentation
category: basics
order: 11
lang: fr
---

Documenter du code Elixir.

## Table des Matières.

- [Annotations](#annotations)
  - [La documentation linéaire](#documentation-lineaire)
  - [Documenter les modules](#documenter-les-modules)
  - [Documenter les fonctions](#documenter-les-fonctions)
- [ExDoc](#exdoc)
  - [Installer](#installer)
  - [Générer la documentation](#generer-la-documentation)
- [Les bonnes pratiques](#les-bonnes-pratiques)


## Annotations

La quantité de commentaires et les tenants d'une documentation de qualité demeurent un sujet problématique au sein du monde de la programmation.
Néanmoins, nous pouvons tous convenir que la documentation est importante, autant pour nous-même que pour les personnes amenées à travailler avec
notre code.

Elixir traite la documentation comme une *citoyenne de premier ordre*, et offre de multiples fonctions pour accéder et générer de la documentation
pour vos projets. La bibliothèque standard d'Elixir fourni différents attributs pour annoter un code source. Examinons trois d'entre eux : 
>>>>>>> fr-documentation
  - `#` - Pour la documentation linéaire.
  - `@moduledoc` - Pour la documentation à l'échelle d'un module.
  - `@doc` - Pour la documentation à l'échelle d'une fonction.

### La documentation linéaire

C'est probablement la façon la plus simple de commenter votre code. De façon similaire à Ruby ou Python, les commentaire d'Elixir sont marqués du symbole
`#` appelé *hash*, ou *croisillon* en Français.

Prenez ce script (greeting.exs) : 

```elixir
# Affiche "Hello, chum." dans la console.
IO.puts "Hello, " <> "chum."
```

En executant ce script, Elixir va tout ignorer depuis le `#` jusqu'à la fin de la ligne. Néanmoins, même si il n'ajoute aucune valeur à l'opération
d'execution et n'améliore pas les performances, une développeuse ou un développeur devrait pouvoir comprendre son fonctionnement en lisant votre commentaire.
Mais faites attention à ne pas en abuser !

### Documenter les modules

L'annotateur `@moduledoc` permet d'écrire de la documentation à l'échelle d'un module. Il est utilisé juste en dessous de la déclaration `defmodule`
au début du fichier. L'exemple ci-dessous montre un commentaire au sein de l'annotateur `moduledoc`.

```elixir
defmodule Greeter do
  @moduledoc """
  Fourni une fonction `hello/1` pour saluer un être humain
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Cette documentation est visible en utilisant le helper `h` dans la console IEx.

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter

                Greeter

Fourni une fonction `hello/1` pour saluer un être humain
```

### Documenter les fonctions

Elixir nous permet également d'écrire de la documentation pour les fonctions avec l'annotateur `@doc`. Il se situe juste avant la fonction concernée.

```elixir
defmodule Greeter do
  @moduledoc """
  …
  """

  @doc """
  Affiche un message de salutation

  ## Paramètres

    - nom : Une chaîne de caractères (String) qui représente le nom de la personne.

  ## Exemples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

"""

  @spec hello(String.t) :: String.t
  def hello(nom) do
    "Hello, " <> nom
  end
end
```

Si nous retournons dans IEx et utilisons le helper `h` sur la fonction, accolée au nom du module, nous devrions voir ceci : 

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(nom)

`hello/1` Affiche un message de salutation

Paramètres

    • nom : Une chaîne de caractères (String) qui représente le nom de la personne.

Exemples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Vous remarquerez que vous pouvez utiliser une syntaxe d'embelissement dans la documentation, et que votre terminal en fera le rendu.
Mis à part le fait que cette fonctionnalité vienne s'ajouter à un déjà vaste écosystème, elle devient beaucoup plus intéressante quand on en vient à
ExDoc pour générer de la documentation HTML à la volée.

## ExDoc

ExDoc est un projet officiel d'Elixir qui **produit de la documentation HTML pour les projets Elixir**, et peut être trouvé sur [GitHub](https://github.com/elixir-lang/ex_doc).
Créons d'abord notre premier projet en Elixir :

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone
```

Copiez et collez le code de la leçon sur l'annotateur `@doc` dans un fichier appelé `lib/greeter.ex` et assurez-vous que tout compile bien.
Maintenant que vous travaillez dans un projet Mix, nous avons besoin de démarrer IEx un peu différemment, en utilisant la commande `iex -S mix` : 

```bash
iex> h Greeter.hello

                def hello(nom)

`hello/1` Affiche un message de salutation

Paramètres

    • nom : Une chaîne de caractères (String) qui représente le nom de la personne.

Exemples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

```

### Installer

Si tout va bien et que nous voyons l'affichage ci-dessus, c'est que nous sommes prêts pour installer ExDoc. Dans notre fichier `mix.exs`, ajoutons les deux 
dépendances nécessaires : `earmark` et `:ex_doc`.

```elixir
  def deps do
    [{:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
```

On spécifiera l'option `only: :dev` car nous n'avons pas besoin de ces dépendances dans un environnement de production. Mais pourquoi Earmark ? Et bien, c'est un 
analyseur syntaxique, ou _parser_, de Markdown pour Elixir et utilisé par ExDoc pour produire de magnifiques fichiers HTML à partir de la documentation au sein 
de `@moduledoc` et `@doc`.

Gardez à l'esprit que vous n'êtes pas obligés d'utiliser Earmark. Vous pouvez très facilement vous tourner vers d'autres outils tels que 
Pandoc, Hoedown ou Cmark. Néanmoins, vous aurez besoin d'un peu plus de configuration, que vous pourrez trouver
[à cette addresse](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool)

### Générer la documentation

Entrez les commandes suivantes dans votre terminal : 

```bash
$ mix deps.get # récupère ExDoc et Earmark.
$ mix docs # génère la documentation

Docs successfully generated.
View them at "doc/index.html".
```

Si tout s'est bien passé, vous devriez voir un message similaire à celui affiché dans l'exemple ci-dessus. Un dossier **doc/** devrait avoir été créé dans votre 
projet Mix. Il contient votre documentation, et si nous visitons la page d'index dans notre navigateur, nous devrions voir ceci : 

![ExDoc Screenshot 1]({{ site.url }}/assets/documentation_1.png)

Nous pouvons voir que Earmark a effectué le rendu du Markdown et que ExDoc l'affiche dans un format bien plus agréable.

![ExDoc Screenshot 2]({{ site.url }}/assets/documentation_2.png)

Nous pouvons maintenant déployer la documentation générée sur GitHub, notre propre site web, ou bien sur [HexDocs](https://hexdocs.pm/).

## Les bonnes pratiques

Ajouter de la documentation au code source devrait être ajouté aux lignes directrices du langage. Bien qu'Elixir soit un langage assez jeune, et que de nombreux
standards sont en train d'être établis au fur et à mesure que la communauté grandit, des efforts ont été fournis pour établir ces bonnes pratiques.
Vous pouvez en lire plus sur cette page : [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Documentez toujours les modules

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Si vous ne prévoyez pas fournir de la documentation pour un module, **ne la laissez pas vide**. Utilisez plutôt le booléen `false` comme ceci : 

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Quand vous vous réferez aux fonctions dans la documentation d'un module, utilisez les backquotes (\`) comme ceci : 

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  Ce module a aussi une fonction `hello/1`
  """

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```

 - Séparez la directive `@moduledoc` du reste du code par une ligne d'espacement : 

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  Ce module a aussi une fonction `hello/1`
  """

  alias Goodbye.bye_bye
  # et ainsi de suite…

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```

 - Utilisez du Markdown dans vos documentations pour faciliter le rendu par IEx ou ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Affiche un message de salutation

  ## Paramètres

    • nom : Une chaîne de caractères (String) qui représente le nom de la personne.

  ## Exemples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t) :: String.t
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Essayez d'include des exemples de code dans votre documentation. Cela vous permetra de générer des tests automatiques depuis les exemples de code trouvés 
 dans un module, une fonction ou une macro avec [ExUnit.DocTest][]. Pour faire ça, vous avez besoin d'invoquer la macro `doctest/1` depuis les test et écrire
 les exemples selon les lignes directrices que vous trouverez dans la [documentation officielle][ExUnit.DocTest]

[ExUnit.DocTest]: http://elixir-lang.org/docs/master/ex_unit/ExUnit.DocTest.html
