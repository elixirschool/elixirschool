%{
  version: "1.0.2",
  title: "Coincidencia de Patrones",
  excerpt: """
  La coincidencia de patrones es una parte poderosa de Elixir. Esta nos permite coincidir valores simples, estructuras de datos, e incluso funciones.
En esta lección vamos a comenzar a ver cómo es usada la coincidencia de patrones.
  """
}
---

## Operador de coincidencia

¿Estás listo para algo un poco sorprendente? En Elixir, el operador `=` es en realidad un operador de coincidencia, comparable al signo igual en el álgebra. Escribirlo transforma la expresión en una igualdad y hace que Elixir haga coincidencia de los valores del lado izquierdo con los del derecho. Si la coincidencia es exitosa, esta retorna el valor de la ecuación. De lo contrario, esta lanzará un error. Echemos un vistazo:

```elixir
iex> x = 1
1
```

Ahora vamos a intentarlo con una coincidencia simple:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Vamos a intentar esto con algunas de las colecciones que conocemos:

```elixir
# Listas
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuplas
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Operador Pin

El operador de coincidencia realiza una asignación cuando el lado izquierdo de la coincidencia incluye una variable.
En algunos casos reenlazar la variable no es el comportamiento deseado.
Para esas situaciones, tenemos el operador `^` (pin).

Cuando usamos el operador pin con una variable, hacemos una coincidencia sobre el valor existente en lugar de enlazarlo a uno nuevo.
Vamos a ver cómo funciona esto:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2 introduce soporte para usar el operador pin en las claves de los mapas y en las cláusulas de función:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

Un ejemplo de usar el operador pin en una cláusula de función:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
```

Nota que en el ejemplo `"Mornin"` que la reasignación de `greeting` a `"Mornin"` solo ocurre dentro de la función. Afuera de la función `greeting` aún es `"Hello"`.
