---
version: 0.9.0
title: Tests
---

Faire des tests est une partie importante du développement informatique. Dans cette leçon, nous allons voir comment tester notre code Elixir avec ExUnit ainsi que les bonnes pratiques pour cela.

{% include toc.html %}

## ExUnit

L'outil de test intégré dans Elixir est ExUnit et il contient tout ce qu'il faut pour tester rigoureusement le code.  Avant de continuer, il est important de noter que les tests sont implémentés comme tout script Elixir donc nous utilisons l'extension `.exs`.  Avant de pouvoir lancer nos tests, il nous faut démarrer ExUnit avec `ExUnit.start()` que l'on place généralement dans `test/test_helper.exs`.

Quand nous avons généré notre projet d'exemple dans la leçon précédente, mix nous a aidé en créant un test simple que nous pouvons trouver dans `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

Nous pouvons alors lancer les tests de notre projet avec `mix test`.  Si nous exécutons cela maintenant, nous devrions voir la sortie suivante:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

Si vous avez déjà écrit des tests auparavant, vous êtes certainement habitués à `assert`; dans certains frameworks `should` ou `expect` prennent la place de `assert`.

Nous utilisons `assert` pour vérifier qu'une expression est correcte.  Dans le cas ou cette dernière ne l'est pas, une erreur sera remontée et le test va échouer.  Pour tester un échec, modifions l'exemple comme suit et lançons `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

Nous devrions alors maintenant voir une autre sortie:

```shell
  1) test the truth (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/example_test.exs:6

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

ExUnit nous dira exactement où nos tests ont échoués, quelle était la valeurs attendue, et celle réellement reçue.

### refute

`refute` est à `assert` ce que `unless` est à `if`.  Utilisez `refute` pour vous assurer qu'une expression est fausse.

### assert_raise

Il est parfois nécessaire d'affirmer qu'une erreur est soulevée et nous pouvons le faire avec `assert_raise`.  Nous verrons un exemple d'utilisation de `assert_raise` dans la prochaine leçon concernant Plug.

## Configuration de test

Dans certains cas, il peut être nécessaire de définir la configuration avant de lancer nos tests.  Pour cela, nous allons utiliser `setup` et `setup_all`.  `setup` sera exécuté avant chaque test et `setup_all` une fois avant la suite.  Ceux-ci doivent retourner un tuple de `{:ok, state}`, où state sera accessible dans nos tests.

Pour cet exemple, nous allons changer le code pour utiliser `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```

## Mocking

L'utilisation des mocks avec Elixir est fortement déconseillée.  Vous pourriez vouloir les utiliser par instinct mais cela est fortement découragé par la communauté Elixir et pour de bonnes raisons.  Si vous suivez les principes d'une bonne architecture, le code résultant sera facile à tester en tant que composant individuel.

Résistez donc à l'envie.
