%{
  version: "1.1.1",
  title: "Pruebas",
  excerpt: """
  Las pruebas son una parte importante en el desarrollo de software.
En esta lección vamos a ver como hacer pruebas de nuestro código Elixir con ExUnit y también vamos a ver algunas buenas prácticas para hacer las pruebas.
  """
}
---

## ExUnit

El framework de pruebas que viene con Elixir es ExUnit e incluye todo lo que necesitamos para hacer pruebas a fondo de nuestro código.
Antes de empezar es importante tener en cuenta que las pruebas en Elixir están implementadas como scripts de Elixir por lo que necesitamos usar la extensión `.exs`.
Antes de ejecutar nuestras pruebas necesitamos iniciar ExUnit con `ExUnit.start()`, esto suele estar hecho en `test/test_helper.exs`.

Cuando generamos nuestro proyecto de ejemplo en las lecciones anteriores, mix fue lo suficientemente útil para crear una prueba simple para nosotros, podemos encontrarla en `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

Podemos ejecutar las pruebas de nuestro proyecto con `mix test`.
Si hacemos esto ahora deberíamos ver una salida similar a:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

¿Por qué hay dos pruebas en la salida? Echemos un vistazo a `lib / example.ex`.
Mix creo ahí otra prueba para nosotros, algunos doctest.

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### assert

Si has escrito pruebas antes, entonces debes estar familiarizado con `assert`; en algunos frameworks `should` o `expect` cumplen el rol de `assert`.

Usamos el macro `assert` para probar que la expresión es verdadera.
En el caso que no lo sea, un error será lanzado y nuestras pruebas fallarán.
Para probar un error vamos a cambiar nuestro ejemplo y luego ejecutamos `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

Ahora deberíamos ver un tipo diferente de salida:

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

ExUnit nos dirá exactamente donde están las aserciones que fallaron, cual es el valor esperado y cual fue el valor actual.

### refute

`refute` es a `assert` como `unless` es a `if`.
Usa `refute` cuando deseas asegurarte que una declaración siempre es falsa.

### assert_raise

A veces puede ser necesario verificar que un error fue lanzado, podemos hacer esto con `assert_raise`.
Vamos a ver un ejemplo de `assert_raise` en la siguiente lección (Plug).

### assert_receive

En Elixir, las aplicaciones constan de actores/procesos que se envían mensajes entre si, a menudo se desea probar los mensajes que se envían.
Dado que ExUnit se ejecuta en su propio proceso, puede recibir mensajes como cualquier otro proceso y podemos buscar equivalencia usando `assert_received`:

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` no espera por los mensajes, con `assert_receive` podemos especificar el tiempo de espera.

### capture_io y capture_log

Capturar la salida de una aplicación es posible con `ExUnit.CaptureIO` sin cambiar la aplicación original.
Simplemente pasa la función generando la salida en:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` es el equivalente a capturar la salida en `Logger`.

## Test Setup

En algunos casos, puede ser necesario realizar la configuración antes de nuestras pruebas.
Para lograr esto, podemos usar los macros `setup` y `setup_all`.
`setup` se ejecutara entes de cada prueba y `setup_all` una vez antes de todas las pruebas.
Se espera que devuelvan una tupla con `{:ok, state}`, el estado estará disponible para nuestras pruebas.

Por ejemplo, cambiaremos nuestro código para usar `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## Mocking (simulaciones)

La respuesta simple en Elixir es: No.
Puede llegar a buscar intensivamente la forma de utilizar los mocks, pero son poco recomendado por la comunidad de Elixir y existe una buena razón.

Para una discusión mas extensa, esta este [excelente articulo](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/).
Lo esencial es que, en lugar de simular las dependencias para las pruebas, tiene muchas ventajas explicitamente definir interfaces (behaviors) para el código fuera de nuestra aplicación usando implementaciones `Mock` en el código cliente para la prueba.

Para cambiar las implementaciones en el código de la aplicación, la forma preferida es pasar el modulo como argumento y usar un valor predeterminado.
Si eso no funciona, use el mecanismo de configuración incorporado.
Para crear estos mocks, no necesita una librería especial para mocks, solo behaviours y callbacks.
