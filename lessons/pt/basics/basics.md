%{
  version: "1.4.1",
  title: "Básico",
  excerpt: """
  Primeiros Passos, tipos básicos e operações básicas.
  """
}
---

## Primeiros Passos

### Instalando Elixir

As instruções de instalação para cada sistema operacional podem ser encontradas em [Elixir-lang.org](http://elixir-lang.org) na aba [Install](http://elixir-lang.org/install.html).

Após instalar o Elixir, você pode encontrar a versão instalada.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Tentando o Modo Interativo

Elixir vem com IEx, um console interativo, que nos permite avaliar expressões em Elixir à medida que avançamos.

Para iniciar, vamos executar o `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Nota: No Windows PowerShell, é necessário executar `iex.bat`.

Vamos em frente e tentar agora digitando algumas expressões básicas:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Não se preocupe se você ainda não entendeu todas as expressões, mas esperamos que você tenha entendido a ideia.

## Tipos Básicos

### Inteiros

```elixir
iex> 255
255
```

O suporte para números binários, octais e hexadecimais também estão inclusos:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Pontos Flutuantes

Em Elixir, os números de ponto flutuante requerem um decimal depois de pelo menos um dígito; estes possuem uma precisão de 64 bits e suportam `e` para números exponenciais:

```elixir
iex> 3.14
 3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Booleanos

Elixir suporta `true` e `false` como booleanos; tudo é verdadeiro com exceção de `false` e `nil`:

```elixir
iex> true
true
iex> false
false
```

### Átomos

Um átomo é uma constante cujo nome é seu valor.
Se você está familiarizado com Ruby, estes são equivalentes aos Symbols:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Booleanos `true` e `false` também são os átomos `:true` e `:false`, respectivamente.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Nomes de módulos em Elixir também são átomos. `MyApp.MyModule` é um átomo válido, mesmo que tal módulo ainda não tenha sido declarado.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Átomos também são usados para referenciar módulos de bibliotecas Erlang, incluindo as bibliotecas embutidas.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Strings

As strings em Elixir são codificadas em UTF-8 e são representadas com aspas duplas:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

As strings suportam quebras de linha e caracteres de escape:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir também inclui tipos de dados mais complexos.
Nós aprenderemos mais sobre estes quando aprendermos sobre [coleções](/pt/lessons/basics/collections) e [funções](/pt/lessons/basics/functions).

## Operações Básicas

### Aritmética

Elixir suporta os operadores básicos `+`, `-`, `*`, e `/` como era de se esperar.
É importante lembrar que `/` sempre retornará um número de ponto flutuante:

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

Se você precisa de uma divisão inteira ou o resto da divisão, Elixir vem com duas funções úteis para conseguir isso:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Booleanos

Elixir provê os operadores booleanos `||`, `&&`, e `!`.
Estes suportam qualquer tipo:

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

Há três operadores adicionais cujo primeiro argumento _deve_ ser um booleano (`true` e `false`):

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

Nota: O `and` e `or` do Elixir são mapeados para `andalso` e `orelse` do Erlang.

### Comparação

Elixir vem com todos os operadores de comparação que estamos acostumados a usar: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` e `>`.

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

Para comparação estrita de inteiros e pontos flutuantes usa-se `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Uma característica importante do Elixir é que qualquer tipo pode ser comparado; isto é particularmente útil em ordenação. Não precisamos memorizar a ordem de classificação, mas é importante estar ciente disto:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Isto pode levar a algumas comparações interessantes e válidas, que você pode não encontrar em outras linguagens:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolação de Strings

Se você já usou Ruby, a interpolação de strings em Elixir parecerá familiar:

```elixir
iex> name = "Sean"
"Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Concatenação de Strings

A concatenação de strings usa o operador `<>`:

```elixir
iex> name = "Sean"
"Sean"
iex> "Hello " <> name
"Hello Sean"
```
