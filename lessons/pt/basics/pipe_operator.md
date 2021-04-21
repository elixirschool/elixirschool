---
version: 1.0.1
title: Operador Pipe
---

O operador pipe `|>` passa o resultado de uma expressão como o primeiro parâmetro de outra expressão.

{% include toc.html %}

## Introdução

Programação pode se tornar algo bem confuso. Tão confuso que o fato de chamadas em funções podem ficar tão incorporadas a outras chamadas de função, tornando-se muito difícil de seguir. Tome em consideração as seguintes funções aninhadas:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Aqui, nós estamos passando o valor `other_function/0` para `new_function/1`, e `new_function/1` para `baz/1`, `baz/1` para `bar/1`, e finalmente o resultado de `bar/1` para `foo/1`. Elixir possui um modo pragmático para esse caos sintático, permitindo-nos a utilização do operador pipe. O operador pipe é representado por `|>`, *recebe o resultado de uma expressão e passa ele adiante*. Vamos dar mais uma olhada no trecho de código acima reescrito com o operador pipe.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

O pipe pega o resultado da esquerda e o passa para o lado direito.

## Exemplos

Por este conjunto de exemplos, nós iremos usar o módulo String de Elixir.

- Tokenize String (vagamente)

```shell
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Converte palavras para letras maiúsculas

```shell
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Checa terminação de palavra

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Boas Práticas

Se a aridade de uma função for maior do que 1, certifique-se de usar parênteses. Isso não importa muito para Elixir, porém é importante para outros programadores que podem interpretar mal o seu código. Mas ainda assim, a ordem é importante com o operador pipe. Se tomarmos o nosso terceiro exemplo, e retirarmos os parênteses do `String.ends_with?/2`, receberemos o seguinte aviso:

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
