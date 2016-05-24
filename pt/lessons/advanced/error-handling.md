---
layout: page
title: Tratamento de Erros
category: advanced
order: 2
lang: pt
---

Embora seja mais comum o retorno da tupla `{: erro, reason}`, Elixir suporta exceções e nesta lição veremos como lidar com erros e os diferentes mecanismos disponíveis para nós.

Em geral, a convenção em Elixir é criar uma função (`example/1`) que retorna` {: ok, result} `e` {: error, reason} `e uma função separada (`example!/1`) que retorna o `result` desembrulhado ou gerará um erro.

Esta lição irá focar interagindo com o último.

{% include toc.html %}

## Tratamento de Erros

Antes de podermos lidar com erros, precisamos criá-los e a maneira mais simples de fazer isso é com o `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Se queremos especificar o tipo e mensagem, precisamos usar `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Se sabemos que um erro pode ocorrer, podemos lidar com isso usando `try/rescue` e padrões semelhantes:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

É possível combinar vários erros em um único rescue:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!
rescue
  e in KeyError -> IO.puts "missing :source_file option"
  e in File.Error -> IO.puts "unable to read source file"
end
```

## Depois

Às vezes pode ser necessário para executar alguma ação depois de nossa `try/rescue` independentemente do erro, por isso temos `try/after`. Se você estiver familiarizado com Ruby este é semelhante ao `begin/rescue/ensure` ou em Java `try/catch/finally`:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Esta é geralmente mais usada com arquivos ou conexões que devem ser fechados:

```elixir
{:ok, file} = File.open "example.json"
try do
   # Do hazardous work
after
   File.close(file)
end
```

## Novos Erros

Enquanto Elixir inclui uma série de tipos de erro nativos como `RuntimeError`, mantemos a capacidade de criar a nossa própria se precisamos de algo específico. Criar um novo erro é fácil com o `defexception/1` macro que aceita convenientemente `:message` opções para definir uma mensagem de erro padrão:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Vamos tentar forçar a execução do nosso novo erro:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Lançar

Outro mecanismo para trabalhar com erros no Elixir é `throw` e `catch`. Na prática, isso não ocorre frequentemente no código mais recente de Elixir. Mas, é importante conhecer e entendê-los mesmo assim.

A função `throw/1` nos dá a capacidade para sair de execução com um valor específico que podemos usar com o `catch`:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Como mencionado, `throw/catch` são bastante incomuns e normalmente existem como tapa-buracos quando as bibliotecas não fornecem APIs adequadas.

## Saindo

O mecanismo de erro final que Elixir fornece é o `exit`. Sinais de saída ocorrem sempre que um processo morre e são uma parte importante da tolerância a falhas do Elixir.

Para sair explicitamente podemos usar `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) "oh no"
```

Embora seja possível pegar uma saída com `try/catch` fazê-lo é extremamente raro. Em quase todos os casos, isso é vantajoso para permitir que o supervisor possa lidar com a saída do processo:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
