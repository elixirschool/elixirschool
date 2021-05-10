%{
  version: "1.1.0",
  title: "Documentation",
  excerpt: """
  Documentation du code Elixir.
  """
}
---

## Annotations

La quantité de commentaires et ce qu'est une documentation de qualité reste une question discutable dans le monde de la programmation. Cependant, nous pouvons tous convenir que la documentation est importante pour nous-même et pour ceux qui travaillent avec notre code source.

Elixir traite la documentation comme une *valeur de première classe*, offrant diverses fonctions pour accéder et générer de la documentation pour vos projets. Le noyau d'Elixir nous fournit de nombreux attributs différents pour annoter le code source. Regardons 3 manières de faire :

  - `#` - Pour la documentation en ligne.
  - `@moduledoc` - Pour la documentation au niveau des modules.
  - `@doc` - Pour la documentation au niveau des fonctions.

### Documentation en ligne (ou commentaire)

La façon la plus simple de commenter votre code est probablement d'utiliser des commentaires en ligne. Semblable à Ruby ou Python, le commentaire en ligne d'Elixir est indiqué par un `#`, souvent connu sous le nom de *pound*, ou un *hash*, ou un *hashtag* (ou encore *croisillon* en Français) selon l'endroit d'où vous êtes originaires dans le monde.

Par exemple, prenez ce script Elixir (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

Lorsqu'Elixir exécute ce script, il ignore tout ce qui se trouve après `#`. Il n'ajoute aucune valeur à l'opération ou à la performance du script mais, lorsque l'opération n'est pas évidente à comprendre, la simple lecture de ce commentaire devrait suffire. Attention tout de même à ne pas abuser des commentaires en ligne ! Cela pourrait vite devenir un cauchemar malvenu pour certains, il est important de l'utiliser avec modération.

### La documentation des modules

L'annotation (ou *décorateur*) `@moduledoc` permet la documentation d'un module. Il se trouve généralement juste en dessous de la déclaration `defmodule` en haut d'un fichier. L'exemple ci-dessous montre une ligne de commentaire dans le décorateur `@moduledoc`.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

La documentation de ce module est accessible en utilisant la fonction d'aide `h` dans IEx.
Nous pouvons le constater directement si nous plaçons le module `Greeter` dans un nouveau fichier, `greeter.ex`, et que nous le compilons :

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

_Note_: nous n'avons pas besoin de compiler manuellement les fichiers comme nous l'avons fait ci-dessus si nous travaillons dans le contexte d'un projet mix. Vous pouvez en effet utiliser `iex -S mix` pour charger le terminal IEx pour le projet courant quand vous travaillez avec un projet mix.

### La documentation des fonctions

Tout comme Elixir nous permet de documenter les modules, il nous permet également de documenter les fonctions avec des annotations similaires. Le décorateur `@doc` permet de documenter une fonction, il se trouve juste au-dessus de la fonction concernée.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Si nous entrons à nouveau dans IEx et utilisons la commande d'aide (`h`) sur la fonction précédée du nom du module, nous devrions voir ce qui suit :

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Remarquez comment le balisage met en forme la documentation dans le terminal. En plus d'être vraiment cool et d'être un nouvel atout au vaste écosystème d'Elixir, il devient beaucoup plus intéressant lorsqu'on regarde ExDoc pour générer de la documentation HTML à la volée !

**Note:** L'annotation `@spec` est utilisé pour analyser statiquement le code. Pour en savoir plus, consultez la leçon [Specifications and types](../../advanced/typespec).

## ExDoc

ExDoc est un projet officiel d'Elixir que vous pouvez trouver sur [GitHub](https://github.com/elixir-lang/ex_doc). Il génère la documentation hors-ligne et en-ligne en **HTML (HyperText Markup Language)** des projets Elixir. Pour commencer, créons un projet Mix pour notre application :

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
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

Maintenant copiez/collez le code de la leçon du décorateur `@doc` dans un fichier appelé `lib/greeter.ex` et assurez-vous que tout fonctionne depuis la ligne de commande. Désormais nous travaillons dans un projet mix, donc nous devons démarrer IEx un peu différemment, avec la commande `iex -S mix` :

```elixir
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Installation

En supposant que tout va bien et que nous voyons le résultat ci-dessus, nous sommes maintenant prêts à mettre en place ExDoc. Dans le fichier `mix.exs`, ajoutez la dépendance `:ex_doc` pour démarrer.

```elixir
  def deps do
    [{:ex_doc, "~> 0.21", only: :dev, runtime: false}]
  end
```

Nous spécifions la paire de valeurs-clés `only: :dev` car nous ne voulons pas télécharger et compiler la dépendance `ex_doc` dans un environnement de production.

`ex_doc` ajoute également une autre bibliothèque pour nous, Earmark.

Earmark est un analyseur (*parser*) Markdown pour le langage de programmation Elixir qu'ExDoc utilise pour transformer notre documentation dans `@moduledoc` et `@doc` en HTML formaté.

Il est important de noter à ce stade que vous pouvez changer l'outil de balisage par Cmark si vous le souhaitez ; cependant vous aurez un peu plus de configuration à faire, configuration sur laquelle vous pouvez en lire plus [ici](https://hexdocs.pm/ex_doc/ExDoc.Markdown.html#module-using-cmark). Pour ce tutoriel, nous nous en tiendrons à Earmark.

### Génération de la documentation

En continuant, à partir de la ligne de commande, exécutez les deux commandes suivantes :

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

Si tout s'est déroulé comme prévu, vous devriez voir un message similaire à celui de l'exemple ci-dessus. Regardons maintenant à l'intérieur de notre projet Mix et nous devrions voir qu'il y a un autre répertoire appelé **doc/**. À l'intérieur se trouve notre documentation générée. Si nous visitons la page d'index dans notre navigateur, nous devrions voir ce qui suit :

![ExDoc Screenshot 1](/images/documentation_1.png)

Nous pouvons voir qu'Earmark a généré notre balisage Markdown et qu'ExDoc l'affiche de manière lisible et navigable, dans un format pratique.

![ExDoc Screenshot 2](/images/documentation_2.png)

Nous pouvons maintenant le déployer sur notre propre site web ou plus communément sur [HexDocs](https://hexdocs.pm/).

## Bonne pratique (Best Practice)

L'ajout de documentation devrait se faire en suivant la ligne directive dictée par les bonnes pratiques du langage. Cependant, comme Elixir est un langage encore jeune de nombreuses normes sont encore à découvrir au fur et à mesure que l'écosystème se développe. Néanmoins la communauté essaye d'établir les pratiques exemplaires (les `Best Practices`). Pour en savoir plus sur les bonnes pratiques, consultez : [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Toujours documenter un module.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Si vous n'avez pas l'intention de documenter un module, **ne le laissez pas** vide. Envisagez d'annoter le module à `false`, comme suit :

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Lorsque vous vous référez aux fonctions de la documentation du module, utilisez les backticks (*apostrophes inverses* en français) de la manière suivante (sur un clavier AZERTY Français les "backticks" s'écrivent ainsi : `[alt gr] + [è] puis [espace]`) :

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Sautez une ligne sous la documentation du module avant tout code comme suit :

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Utilisez Markdown dans vos documentations. Elles seront plus lisibles via IEx ou ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Essayez d'inclure quelques exemples de code dans votre documentation. Cela vous permet également de générer des tests automatiques à partir des exemples de code trouvés dans un module, une fonction ou une macro avec [ExUnit.DocTest][]. Pour ce faire, vous devez invoquer la macro `doctest/1` de votre scénario de test et écrire vos exemples selon les directives détaillées dans la [documentation officielle][ExUnit.DocTest].

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
