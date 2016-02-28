---
layout: page
title: Testando
category: basics
order: 12
lang: pt
---

Testes são uma parte importante do desenvolvimento de software. Nesta lição nós veremos como testar nosso código Elixir com ExUnit e algumas das melhores práticas de como fazer isto.

## Sumário

- [ExUnit](#exunit)
  - [assert](#assert)
  - [refute](#refute)
  - [assert_raise](#assertraise)
- [Configuração de Teste](#configuracao-de-teste)
- [Mocking](#mocking)

## ExUnit

O framework de testes integrado do Elixir é o ExUnit, isto inclui tudo o que precisamos para testar exaustivamente o nosso código. Antes de avançar, é importante notar que testes são implemnetados como scripts Elixir, por isso precisamos usar a extensão de arquivo `.exs`. Antes de podermos executar nossos testes nós precisamos iniciar o ExUnit com `ExUnit.start()`, este é mais comumente feito em `test/test_helper.exs`.

Quando geramos nosso projeto de exemplo na lição anterior, o mix foi útil o suficiente para criar um teste simples para nós, podemos contrá-lo em `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

Podemos executar testes do nosso projeto com `mix test`. Se fizermos isso agora devemos ver uma saída semelhante a:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

Se você escreveu testes antes, então você está familiarizado com `assert`; em alguns frameworks `should` ou `expect` preenchem o papel de `assert`.

Usamos o `assert` macro para testar se a expressão é verdadeira. No caso em que não é, um erro vai ser levantado e os nossos testes irão falhar. Para testar uma falha vamos mudar nosso exemplo e em seguida, executar o `mix test`.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```
Agora nós devemos ver uma saída bem diferente:

```shell
  1) test the truth (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/example_test.exs:6

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

ExUnit nos diz exatamente onde nossos asserts falharam, qual era o valor esperado e qual o valor atual.

### refute

`refute` é para `assert` como `unless` é para `if`. Use `refute` quando você quiser garantir que uma declaração é sempre falsa.

### assert_raise

As vezes pode ser necessário afirmar que um erro foi levantado, podemos fazer isso com `assert_raise`. Vamos ver um exemplo de `assert_raise` na próxima lição sobre Plug.

## Configuração de Teste

Em alguns casos, pode ser necessária a realização de configuração antes de nossos testes. Para fazer isso acontecer, nós podemos usar o `setup` e `setup_all` macros. `setup` irá ser executado antes de cada teste, e `setup_all` uma vez antes da suite de testes. Espera-se que eles vão retornar uma tupla de `{:ok, state}`, o estado estará disponível para os nossos testes.

Por uma questão de exemplo, vamos mudar o nosso código para usar `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```

## Mocking

A resposta simples para mocking no Elixir é: não faça isso.Você pode instintivamente querer utilizar mocks, porém eles são altamente desaconselhados na comunidade Elixir por uma boa razão. Se você seguir bons princípios de design o código resultante será fácil para testar os componentes individuais.

Resista à tentação.
