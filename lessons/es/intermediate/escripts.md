%{
  version: "0.9.1",
  title: "Ejecutables",
  excerpt: """
  Para construir ejecutables en Elixir utilizaremos escript. Escript produce un ejecutable que puede correr en cualquier sistema con Erlang instalado.
  """
}
---

## Comenzando

Para crear un ejecutable con escript hay sólo unas pocas cosas que necesitamos hacer: implementar una función `main/1` y actualizar nuestro Mixfile.

Comenzaremos por crear un módulo que sirve como el punto de entrada a nuestro ejecutable. Aquí es donde implementaremos `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Después necesitaremos actualizar nuestro Mixfile para incluir la opción `:escript` para nuestro proyecto junto con la especificación de nuestro módulo `:main_module`:

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Análisis sintáctico de argumentos

Con nuestra aplicación preparada podemos movernos al análisis sintáctico de argumentos de la línea de comandos. Para ello utilizaremos la función `OptionParser.parse/2` de Elixir con la opción `:switches` para indicar que nuestra bandera es booleana:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Construyendo

Una vez que hemos finalizado de configurar nuestra aplicación para usar escript, construir nuestro ejecutable es sencillo utilizando Mix:

```elixir
$ mix escript.build
```

Pongamos a prueba nuestro ejecutable:

```elixir
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

Eso es todo. Hemos construido nuestro primer ejecutable en Elixir usando escript.
