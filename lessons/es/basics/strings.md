%{
  version: "1.1.1",
  title: "Cadenas",
  excerpt: """
  Cadenas, listas de caracteres, Grafemas y puntos de código.
  """
}
---

## Cadenas

Las cadenas en Elixir no son mas que una secuencia de _bytes_. Vamos a ver un ejemplo:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

Concatenando la cadena con el byte `0` IEx muestra la cadena como un binario porque ya no es una cadena válida. Este truco puede ayudarnos a ver los _bytes_ subyacentes de cualquier cadena.

>NOTA: Usando la sintaxis << >> estamos diciéndole al compilador que los elementos dentro de esos símbolos son _bytes_.

## Listas de caracteres

Internamente las cadenas en Elixir son representadas como una secuencia de _bytes_ en lugar de un arreglo de caracteres. Elixir también tiene un tipo de lista de caracteres. Las cadenas de Elixir están encerradas con comillas dobles mientras que las listas de caracteres están encerradas con comillas simples.

¿Cuál es la diferencia? Cada valor en una lista de caracteres es el punto de código Unicode de un carácter mientras que en un binario los puntos de código se codifican en UTF-8. Vamos a profundizar en:

```elixir
iex(5)> 'hełło'
[104, 101, 322, 322, 111]
iex(6)> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` es el punto de código Unicode para ł pero esta codificado en UTF-8 como los 2 _bytes_ `197` y `130`.

Cuando programamos en Elixir usualmente usamos cadenas no listas de caracteres. El soporte para listas de caracteres esta incluido principalmente porque es requerido para algunos módulos Erlang.

Para mas información podemos ver la [`Guía de inicio`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## Grafemas y puntos de código

Los puntos de código son solo caracteres Unicode los cuales están representados por uno o mas _bytes_ dependiendo de la codificación UTF-8. Los caracteres fuera del conjunto de caracteres US ASCII siempre se codificarán con mas de un byte. Por ejemplo los caracteres latinos con tilde o acento (`á, ñ, è`) son usualmente codificados con dos _bytes_. Los caracteres de idiomas asiáticos son frecuentemente codificados con tres o cuatro _bytes_. Los grafemas consisten de múltiples puntos de código que son dibujados como un simple carácter.

El módulo String ya provee dos funciones para obtenerlos, `graphemes/1` y `codepoints/1`. Vamos a ver un ejemplo:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Funciones para cadenas

Vamos a revisar algunos de las mas importantes y útiles funciones de módulo String. Esta lección solo cubrirá un subconjunto de las funciones disponibles. Para ver un conjunto completo de funciones visita la documentación oficial [`String`](https://hexdocs.pm/elixir/String.html).

### length/1

Retorna el número de grafemas en la cadena.

```elixir
iex> String.length "Hello"
5
```

### replace/3

Retorna una nueva cadena reemplazando un patrón actual en una cadena con uno nuevo.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### duplicate/2

Retorna una nueva cadenas repetida n veces.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### split/2

Retorna una lista de cadenas divididas por un patrón.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Ejercicios

Veamos unos ejercicios simples para demostrar que estamos listos para trabajar con cadenas.

### Anagramas

A y B son considerados anagramas si hay una forma de reorganizar A o B haciéndolos iguales. Por ejemplo:

+ A = super
+ B = perus

Si reorganizamos los caracteres de la cadena A podemos obtener la cadena B y viceversa.

Entonces ¿Cómo podemos revisar si dos cadenas son Anagramas en Elixir? La solución simple es solo ordenar los grafemas de cada cadena alfabéticamente y luego revisar si ambas listas son iguales. Intentemos eso:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Vamos primero a revisar `anagrams?/2`. Estamos revisando si los parámetros que estamos recibiendo son binarios o no. Esa es la forma de revisar si un parámetro es una cadena en Elixir.

Luego de eso llamamos a una función que ordena las cadenas alfabéticamente. Primero convierte la cadena a minúsculas y luego usa `String.graphemes/1` para obtener una lista de grafemas de la cadena. Finalmente envía esa lista a `Enum.sort/1`. 

Vamos a revisar la salida en iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

Como puedes ver la última llamada a `anagrams?` causa un `FunctionClauseError`. Este error esta diciendo que no hay una función en nuestro módulo que coincida con el patrón de recibir 2 argumentos no binarios, y eso es exactamente lo que queremos, solo recibir cadenas y nada mas.
