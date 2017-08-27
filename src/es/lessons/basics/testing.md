---
version: 0.9.0
title: Pruebas
---

Las pruebas son una parte importante en el desarrollo de software. En esta lección vamos a ver como hacer pruebas de nuestro código Elixir con ExUnit y también vamos a ver algunas buenas prácticas para hacer las pruebas.

{% include toc.html %}

## ExUnit

El framework de pruebas que viene con Elixir es ExUnit e incluye todo lo que necesitamos para hacer pruebas a fondo de nuestro código. Antes de empezar es importante tener en cuenta que las pruebas en Elixir están implementadas como scripts de Elixir por lo que necesitamos usar la extensión `.exs`. Antes de ejecutar nuestras pruebas necesitamos iniciar ExUnit con `ExUnit.start()`, esto suele estar hecho en `test/test_helper.exs`.

Cuando generamos nuestro proyecto de ejemplo en las lecciones anteriores, mix fue lo suficientemente útil para crear una prueba simple para nosotros, podemos encontrarla en `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

Podemos ejecutar las pruebas de nuestro proyecto con `mix test`. Si hacemos esto ahora deberíamos ver una salida similar a:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

Si has escrito pruebas antes, entonces debes estar familiarizado con `assert`; en algunos frameworks `should` o `expect` cumplen el rol de `assert`.

Usamos el macro `assert` para probar que la expresión es verdadera. En el caso que no lo sea, un error será lanzado y nuestras pruebas fallarán. Para probar un error vamos a cambiar nuestro ejemplo y luego ejecutamos `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

Ahora deberíamos ver un tipo diferente de salida:

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

ExUnit nos dirá exactamente donde están las aserciones que fallaron, cual es el valor esperado y cual fue el valor actual.

### refute

`refute` es a `assert` como `unless` es a `if`.  Usa `refute` cuando deseas asegurarte que una declaración siempre es falsa.

### assert_raise

A veces puede ser necesario verificar que un error fue lanzado, podemos hacer esto con `assert_raise`. Vamos a ver un ejemplo de `assert_raise` en la siguiente lección (Plug).

## Configuración de pruebas

En algunos casos puede ser necesario realizar una configuración antes de ejecutar nuestras pruebas. Para realizar esto podemos usar los macros `setup` y `setup_all`, `setup` se ejecutará antes de cada prueba y `setup_all` una vez antes del conjunto de pruebas. Se espera que ellos retornen una tupla de la siguiente forma `{:ok, state}`, el estado (state) estará disponible para nuestras pruebas.

Por motivo del ejemplo, vamos a cambiar nuestro código para usar `setup_all`:

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

## Mocking (simulaciones)

Hay una simple respuesta para mocking en Elixir: No lo hagas. Instintivamente puedes llegar a los mocks pero estos son altamente desaprobados en la comunidad de Elixir por una buena razón. Si sigues buenos principios de diseño el código resultante será fácil de probar como componentes individuales.

Resiste la tentación.
