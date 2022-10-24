%{
  version: "1.2.1",
  title: "Testes",
  excerpt: """
  Testes são uma parte importante do desenvolvimento de software.
  Nesta lição nós veremos como testar nosso código Elixir com ExUnit e algumas das melhores práticas de como fazer isto.
  """
}
---

## ExUnit

O framework de testes integrado do Elixir é o ExUnit e ele inclui tudo o que precisamos para testar exaustivamente o nosso código.
Antes de avançar, é importante notar que testes são implementados como scripts Elixir, por isso precisamos usar a extensão de arquivo `.exs`.
Antes de podermos executar nossos testes nós precisamos iniciar o ExUnit com `ExUnit.start()`, e isto é mais comumente feito em `test/test_helper.exs`.

Quando geramos nosso projeto de exemplo na lição anterior, o mix foi útil o suficiente para criar um teste simples para nós e podemos encontrá-lo em `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

Podemos executar testes do nosso projeto com `mix test`.
Se fizermos isso agora devemos ver uma saída semelhante a:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

Porque há dois testes na saída? Além do teste em `test/example_test.exs`, Mix também criou um doctest em `lib/example.ex`.

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### assert

Se você escreveu testes antes, então você está familiarizado com `assert`; em alguns frameworks `should` ou `expect` preenchem o papel de `assert`.

Usamos o `assert` macro para testar se a expressão é verdadeira.
No caso em que não é, um erro vai ser gerado e os nossos testes irão falhar.
Para testar uma falha, vamos mudar nossa amostra e em seguida executar o `mix test`.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

Agora nós devemos ver uma saída bem diferente:

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

ExUnit nos diz exatamente onde nossas asserções falharam, qual era o valor esperado e qual o valor atual.

### refute

`refute` é para `assert` como `unless` é para `if`.
Use `refute` quando você quiser garantir que uma declaração é sempre falsa.

### assert_raise

Às vezes pode ser necessário afirmar que um erro foi gerado.
Podemos fazer isso com `assert_raise`.
Vamos ver um exemplo de `assert_raise` na lição sobre Plug.

### assert_receive

Em Elixir, aplicações consistem em atores/processos que enviam mensagens um para o outro, portanto você irá querer testar mensagens sendo enviadas.
Como o ExUnit é executado no seu próprio processo, ele pode receber mensagem como qualquer outro processo e você pode afirmar nele mesmo com a macro `assert_received`:

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` não espera mensagens, com `assert_receive` você pode especificar um tempo limite.

### capture_io e capture_log

Capturar uma saída da aplicação é possível com `ExUnit.CaptureIO` sem mudar a aplicação original.
Basta passar a função gerando a saída em:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` é o equivalente para capturar a saída de `Logger`.

## Configuração de Teste

Em alguns casos, pode ser necessária a realização de configuração antes de nossos testes.
Para fazer isso acontecer, nós podemos usar as macros `setup` e `setup_all`.
`setup` será executado antes de cada teste e `setup_all` uma vez antes do suíte de testes.
Espera-se que eles vão retornar uma tupla de `{:ok, state}`, o estado estará disponível para os nossos testes.

Por uma questão de exemplo, vamos mudar o nosso código para usar `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## Simulações de Teste (Mocks)

Queremos ter cuidado com a forma que pensamos sobre “mocks”. Quando simulamos certas interações criando funções de simulação exclusivas em um determinado exemplo de teste, estabelecemos um padrão perigoso. Acoplamos a execução dos nossos testes ao comportamento de uma dependência específica, como um cliente de API. Evitamos definir o comportamento compartilhado entre nossas funções simuladas. Tornamos mais difícil iterar nossos testes.

Em vez disso, a comunidade Elixir nos encoraja a mudar como pensamos sobre simulações de teste; para pensarmos em mock como um substantivo, em vez de um verbo. 

Para uma discussão mais longa neste tópico, veja este [excelente artigo](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/).

A essência é que, em vez de simular dependências em testes (mock como *verbo*), existem muitas vantagens em explicitamente definir interfaces (comportamentos) para código fora da aplicação e usar implementações de simulações (mock como *substantivo*) no seu código para testes.

Para aproveitar esse padrão "mock-como-substantivo" você pode:

* Definir um comportamento que seja implementado pela entidade para qual você gostaria de definir uma simulação *e* pelo módulo que atuará como a simulação
* Definir o módulo de simulação
* Configurar seu código da aplicação para usar o mock em um certo teste ou ambiente de teste, por exemplo, passando o módulo de simulação como argumento em uma chamada de função ou configurando sua aplicação para usar o módulo de simulação no ambiente de teste.

Para um mergulho mais profundo em simulações de teste em Elixir, e uma olhada na biblioteca Mox que permite definir simulações simultâneas, confira nossa lição sobre Mox [aqui](/pt/lessons/testing/mox).
