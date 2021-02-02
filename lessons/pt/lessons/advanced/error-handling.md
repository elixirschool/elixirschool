%{
  version: "1.1.0",
  title: "Tratamento de Erros",
  excerpt: """
  Embora seja mais comum o retorno da tupla `{:error, reason}`, o Elixir suporta exceções e nesta lição veremos como lidar com erros e os diferentes mecanismos disponíveis para nós.

Em geral, a convenção em Elixir é criar uma função (`example/1`) que retorna `{:ok, result}` e `{:error, reason}` e uma função separada (`example!/1`) que retorna o `result` desempacotado ou levanta um erro.

Esta lição irá focar na interação com o último.
  """
}
---

## Convenções Gerais

No momento, a comunidade Elixir chegou a algumas convenções sobre o retorno de erros:

* Para erros que fazem parte da operação regular de uma função (ex: um usuário digitou um tipo errado de data), uma função retornaria `{:ok, result}` e `{:error, reason}` adequadamente.

* Para erros que não fazem parte das operações normais (ex: não é possível analisar os dados de configuração), você lançaria uma exceção.

Geralmente lidamos com fluxo de erros padrão com [Pattern Matching](../basics/pattern-matching/), mas nesta lição, estamos focando no segundo caso - nas exceções.

Muitas vezes, em APIs públicas, você também pode encontrar uma segunda versão da função com um ! (exemplo!/1) que retorna o resultado desempacotado(ex: retorna o resultado no lugar de retornar uma tupla) ou levanta um erro.

## Tratamento de Erros

Antes de podermos lidar com os erros, precisamos criá-los e a maneira mais simples de fazer isso é com o `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Se queremos especificar o tipo e mensagem, precisamos usar `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Se sabemos que um erro pode ocorrer, podemos lidar com isso usando `try/rescue` e *pattern matching*:

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
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## Depois

Às vezes pode ser necessário executar alguma ação depois do nosso `try/rescue` independentemente do erro. Para isso temos `try/after`. Se você estiver familiarizado com Ruby isso é semelhante ao `begin/rescue/ensure` ou em Java `try/catch/finally`:

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
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## Novos Erros

Enquanto o Elixir inclui uma série de tipos de erro nativos, como `RuntimeError`, nós mantemos a capacidade de criar o nosso próprio se precisamos de algo específico. Criar um novo erro é fácil com o `defexception/1` macro que aceita convenientemente a opção `:message` para definir uma mensagem de erro padrão:

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

Outro mecanismo para trabalhar com erros no Elixir é o `throw` e o `catch`. Na prática, isso não ocorre frequentemente no código mais recente de Elixir. Mas, é importante conhecer e entendê-los mesmo assim.

A função `throw/1` nos dá a capacidade para sair da execução com um valor específico que podemos `catch` (pegar) e usar:

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

O mecanismo de erro final que o Elixir fornece é o `exit`. Sinais de saída ocorrem sempre que um processo morre e são uma parte importante da tolerância a falhas do Elixir.

Para sair explicitamente podemos usar `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Embora seja possível pegar uma saída com `try/catch` fazê-lo é _extremamente_ raro. Em quase todos os casos é vantajoso deixar o supervisor controlar a saída do processo:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
