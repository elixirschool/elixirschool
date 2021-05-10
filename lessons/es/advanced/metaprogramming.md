%{
  version: "1.0.2",
  title: "Metaprogramación",
  excerpt: """
  La Metaprogramación es el proceso de usar código para escribir código.
En Elixir esto nos da la habilidad de extender el lenguaje para que encaje con nuestras necesidades y poder cambiar el código dinámicamente.
Vamos a empezar mirando como Elixir está representado por detrás, luego vamos a modificarlo y finalmente podemos usar este conocimiento para extenderlo.

Unas palabras de advertencia: La Metaprogramación es complicada y solo debería ser usada cuando sea realmente necesario.
El abuso con seguridad acabará con código complejo que es difícil de mantener y depurar.
  """
}
---

## Quote

El primer paso en Metaprogramación es entender como las expresiones están representadas.
En Elixir el árbol de sintaxis abstracto (AST), la representación interna de nuestro código, está compuesta de tuplas.
Estas tuplas contienen tres partes: el nombre de la función, la metadata y los argumentos de la función.

Para ver estas estructuras internas, Elixir nos provee con la función `quote/2`.
Usando `quote/2` podemos convertir código Elixir a su representación subyacente.

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

¿Te das cuenta de que el primer árbol no retorna tuplas? Hay cinco literales que se retornan a si mismos cuando son `quoted`.

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Unquote

Ahora podemos recuperar la representación interna de nuestro código, ¿cómo lo modificamos? Para inyectar nuevo código o valores podemos usar `unquote/1`.
Cuando hacemos `unquote` a una expresión esta será evaluada e inyectada dentro del AST.
Para demostrar `unquote/1` vamos a mirar algunos ejemplos:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

En el primer ejemplo nuestra variable `denominator` es `quoted` entonces el AST resultante incluye una tupla para acceder a la variable.
En cambio en el ejemplo con `unquote/1` el código resultante incluye el valor de `denominator`.

## Macros

Una vez que entendemos `quote/2` y `unquote/1` estamos listos para sumergirnos dentro de los macros.
Es importante recordar que los macros, al igual que toda la Metaprogramación, debería ser usada escasamente.

En términos simples los macros son funciones especiales diseñadas para retornar una expresión `quoted` que será insertada dentro del código de nuestra aplicación.
Imagina al macro siendo reemplazado con la expresión `quoted` en lugar de ser llamado como una función.
Con macros tenemos todo lo necesario para extender Elixir y agregar código dinámicamente a nuestra aplicación.

Empecemos por definir un macro usando `defmacro/2` el cual como mucho de Elixir es un macro en si mismo.
Como ejemplo vamos a implementar `unless` como un macro.
Recuerda que nuestro macro necesita retornar una expresión `quoted`:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

Vamos a requerir nuestro módulo y darle a nuestro macro un giro:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

Debido a que los macros reemplazan código de nuestra aplicación, podemos controlar cuando y que es compilado.
Un ejemplo de esto puede encontrarse en el módulo `Logger`.
Cuando el _logging_ está deshabilitado ningún código es inyectado y la aplicación resultante no contiene referencias o funciones que llamen al _logging_.
Esto es diferente de otros lenguajes donde hay incluso una sobrecarga de una función incluso cuando la implementación no fue provista.

Para demostrar esto vamos a hacer un _logger_ simple que puede ser habilitado o deshabilitado:

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

Con el logging habilitado nuestra función `test` resultaría en un código como este:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

Si deshabilitamos el logging el resultado sería:

```elixir
def test do
end
```

## Depuración

Listo, ahora sabemos como usar `quote/2`, `unquote/1` y escribir macros.
¿Pero qué pasa si tienes un enorme pedazo de código `quoted` y quieres entenderlo? En este caso puedes usar`Macro.to_string/2`.
Échale un vistazo a este ejemplo:

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

Y cuando quieras mirar en el código generado por un macro puedes combinar `Macro.expand/2` y `Macro.expand_once/2`, estas funciones expanden macros a su código `quoted`.
El primero puede expandirlo muchas veces, mientras que el último solo una vez.
Por ejemplo vamos a modificar el ejemplo `unless` de la sección previa.

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

Si ejecutamos el mismo código con `Macro.expand/2` es intrigante:

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

Puede que recuerdes que mencionamos que `if` es un macro en Elixir, aquí lo vemos expandido en su forma interna como un enunciado `case`.

### Macros privados

No es tan común pero Elixir soporta macros privados.
Un macro privado está definido con `defmacrop` y solo puede ser llamado dentro del módulo donde fue definido.
Los macros privados deben ser definidos antes del código que los invoca.

### Higiene de macro

La forma como los macros interactúan con el contexto de quien los llama es conocido como higiene de macros.
Por defecto los macros en Elixir son higiénicos y no entrarán en conflicto con nuestro contexto.

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

¿Qué pasa si queremos manipular el valor de `val`? Para marcar una variable como antihigiénica podemos usar `var!/2`.
Vamos a actualizar nuestro ejemplo para incluir otro macro utilizando `var!/2`:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

Vamos a comparar como ellos interactuar con nuestro contexto:

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

Incluyendo `var!/2` en nuestro macro manipulamos el valor de `val` sin pasarlo a nuestro macro.
El uso de macros antihigiénicos debería ser mantenido al mínimo.
Incluyendo `var!/2` aumentamos el riesgo de tener un conflicto en la resolución de variables.

### Enlazamiento

Ya hemos cubierto la utilidad de `unquote/1` pero hay otra forma de inyectar valores en nuestro código: el enlazamiento(binding).
Con `binding` variable somos capaces de incluir múltiples variables en nuestro macro y asegurar que ellos solo van a ser `unquoted` una vez evitando revaluaciones accidentales.
Para usar variables enlazadas necesitamos pasar una lista de claves a la opción `bind_quoted` en `quote/2`.

Para ver el beneficio de `bind_quote` y demostrar el problema de la revaluación vamos a usar un ejemplo.
Podemos empezar creando un macro que simplemente imprime la expresión dos veces:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

Vamos a probar nuestro nuevo macro pasándole la hora actual del sistema.
Deberíamos esperar verla impresa dos veces:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

¡Las horas son diferentes! ¿Qué pasó? Usando `unquote/1` en la misma expresión muchas veces conlleva a una revaluación y eso puede tener consecuencias involuntarias.
Vamos a actualizar el ejemplo para usar `bind_quoted` y veamos que obtenemos:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

Con `bind_quoted` obtenemos la salida esperada: la misma hora impresa dos veces.

Ahora que hemos cubierto `quote/2`, `unquote/1` y `defmacro/2` tenemos todas las herramientas necesarias para extender Elixir y adaptarlo a nuestras necesidades.
