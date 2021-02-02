%{
  version: "1.2.1",
  title: "Básico",
  excerpt: """
  Preparar el entorno, tipos y operaciones básicas.
  """
}
---

## Preparar el entorno

### Instalar Elixir

Las instrucciones de instalación para cada sistema operativo pueden ser encontradas en [Elixir-lang.org](http://elixir-lang.org) en la guía [Installing Elixir](http://elixir-lang.org/install.html)(en inglés).

Después de que Elixir haya sido instalado, puedes confirmar la versión instalada fácilmente.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Probando el Modo Interactivo

Elixir viene con `iex`, una consola interactiva, que nos permite evaluar expresiones Elixir al vuelo.

Para empezar, ejecutamos `iex`:

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

Avancemos y hagamos una prueba escribiendo unas cuantas expresiones sencillas:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

No te preocupes si no entiendes cada expresión todavía, pero esperamos que puedas captar la idea.

## Tipos Básicos

### Enteros

```elixir
iex> 255
255
```

El soporte para números binarios, octales y hexadecimales también viene incluido:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Coma flotante

En Elixir, los números con coma flotante requieren un decimal después de al menos un dígito; estos tienen una precisión de 64 bits y soportan `e` para números exponenciales.

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Booleanos

Elixir soporta `true` y `false` como booleanos; todo valor es verdadero a excepción de `false` y `nil`:

```elixir
iex> true
true
iex> false
false
```

### Átomos

Un átomo es una constante cuyo nombre es su valor.
Si estás familiarizado con Ruby estos son equivalentes a los Símbolos:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Los booleanos `true` y `false` son también los átomos `:true` y `:false` respectivamente.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Los nombres de módulos en Elixir tambien son átomos. `MyApp.MyModule` es un átomo válido, incluso si el módulo no ha sido declarado aún.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Los átomos también son usados para hacer referencia a módulos de las librerias de Erlang, incluyendo las nativas.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Cadenas

Las cadenas en Elixir están codificadas en UTF-8 y están encerradas en comillas dobles:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Las cadenas soportan saltos de línea y secuencias de escape:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir también incluye tipos de datos más complejos.
Aprenderemos más sobre ellos cuando veamos [colecciones](../collections/) y [funciones](../functions/).

## Operaciones Básicas

### Aritmética

Elixir soporta los operadores básicos `+`, `-`, `*`, y `/` como era de esperarse.
Es importante resaltar que `/` siempre retornará un número con coma flotante:

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

Si necesitas una división entera o el resto de una división, Elixir viene con dos funciones útiles para para lograr esto:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Booleanas

Elixir provee los operadores booleanos: `||`, `&&`, y `!`, que soportan cualquier tipo de dato:

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

Hay tres operadores adicionales cuyo primer argumento _tiene_ que ser un booleano (`true` y `false`):

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

Nota: Los operadores de Elixir `and` y `or` en realidad mapean a `andalso` y `orelse` de Erlang.

### Comparación

Elixir viene con todos los operadores de comparación a los que estamos acostumbrados: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` y `>`.

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

Para comparación estricta de enteros y flotantes usamos `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Una característica importante de Elixir es que cualquier par de tipos se pueden comparar, esto es útil particularmente en ordenación. No necesitamos memorizar el orden pero es importante ser consciente de este:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Esto puede conducir a algunas interesantes y válidas comparaciones que no puedes encontrar en otros lenguajes:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolación de cadenas

Si has usado Ruby, la interpolación de cadenas en Elixir te parecerá muy familiar:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Concatenación de cadenas

La concatenación de cadenas usa el operador `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
