%{
  version: "0.9.1",
  title: "Elixir Embebido (EEx)",
  excerpt: """
  Al igual que Ruby tiene ERB y Java JSP, Elixir tiene EEx o Elixir Embebido. Con EEx podemos integrar y evaluar Elixir dentro de las cadenas.
  """
}
---

## API

La API EEx soporta trabajar con cadenas y archivos directamente. El API se divide en tres componentes principales: evaluación simple, definición de funciones y compilación a AST.

### Evaluación

Usando `eval_string/3` y `eval_file/2` podemos realizar una evaluación simple contra una cadena o contenido de archivos. Esta es la API mas sencilla pero también la más lenta ya que el código es evaluado y no compilado.

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### Definiciones

El más rápido, y preferido, método de utilizar EEx es el de insertar nuestra plantilla en un módulo por lo que este puede ser compilado. Para ello necesitamos nuestra plantilla en tiempo de compilación y las macros `function_from_string/5` y `function_from_file/5`.

Vamos a pasar nuestro saludo a otro archivo y generar una función para nuestra plantilla:

```elixir
# greeting.eex
Hi, <%= name %>

defmodule Example do
  require EEx
  EEx.function_from_file(:def, :greeting, "greeting.eex", [:name])
end

iex> Example.greeting("Sean")
"Hi, Sean"
```

### Compilación

Por último, EEx nos proporciona una forma directa de generar Elixir AST de una cadena o archivo usando `compile_string/2` o `compile_file/2`. Esta API es utilizada principalmente por las API citadas pero está disponible si desea implementar su propio manejo de Elixir incrustado.

## Etiquetas

De forma predeterminada, hay cuatro etiquetas admitidas en EEx:

```elixir
<% Expresion Elixir - en linea con salida %>
<%= Expresion Elixir - reemplaza con resultado %>
<%% EEx quotation - retorna el contenido en su interior %>
<%# Comentarios - estos son descartados en el código fuente %>
```

Todas las expresiones que se desean emitir __deben__ utilizan el signo igual (`=`). Es importante señalar que, si bien otros lenguajes de plantillas tratan cláusulas como `if` de una manera especial, EEx no lo hace. Sin `=` nada sera emitido:

```elixir
<%= if true do %>
  A truthful statement
<% else %>
  A false statement
<% end %>
```

## Motor

Por defecto Elixir utiliza el `EEx.SmartEngine` que incluye soporte para asignaciones (como `@name`):

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

Las asignaciones `EEx.SmartEngine` son útiles porque las asignaciones se pueden cambiar sin necesidad de compilación de plantilla:

¿Interesado en escribir su propio motor? Echa un vistazo a el comportamiento de [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html) para ver lo que se requiere.
