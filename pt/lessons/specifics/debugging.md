---
version: 1.0.1
title: Debugging
---

Às vezes, os bugs estão presentes em nosso projeto, é por isso que precisamos investigar o problema. Nesta sessão vamos aprender sobre como fazer debug no código Elixir, bem como ferramentas de análise de estática para ajudar a encontrar possíveis bugs.

{% include toc.html %}

# Dialyxir e Dialyzer

O [Dialyzer](http://erlang.org/doc/man/dialyzer.html) (**DI**screpancy **A**nal**YZ**er for **ER**lang), é uma ferramenta para análise de
código estático. Em outras palavras eles _leem_ e analisam mas não _rodam_ o código. Exemplo: procurando por alguns bugs, códigos mortos,
desnecessários ou inacessíveis.

O [Dialyxir](https://github.com/jeremyjh/dialyxir) é uma tarefa mix para simplificar o uso do Dialyzer em Elixir.

Ferramentas de especificação como o Dialyzer ajudam a enteder melhor o código. Este é um exemplo do que é legível e compreensível apenas para outros seres humanos (se apenas existe e é bem escrito), `@spec` usar sintaxe mais formal e que pode ser entendido pela máquina.

Vamos adicionar Dialixyr ao nosso projeto. A maneira mais simples é adicionar dependência ao arquivo `mix.exs`:

```elixir
defp deps do
  [{:dialyxir, "~> 0.4", only: [:dev]}]
end
```

Então, nós chamamos:

```shell
$ mix deps.get
...
$ mix deps.compile
```

O primeiro comando vai fazer o download e instalar o Dialyxir. Você pode ser solicitado a instalar o Hex juntamente com ele. O segundo
vai compilar a aplicação Dialyxir. Se você deseja instalar o Dialyxir globalmente, por favor leia esta [documentação](https://github.com/jeremyjh/dialyxir#installation).

O último passo é rodar o Dialyzer para reconstruir o PLT (Persistent Lookup Table). Você precisa fazer isso toda vez após a instalação de uma nova versão do Erlang ou Elixir. Felizmente, o Dialyzer não tentará analisar a biblioteca padrão toda vez que você tentar usá-lo. Demora alguns minutos para que o download seja concluído.

```shell
$ mix dialyzer --plt
Starting PLT Core Build ... this will take awhile
dialyzer --build_plt --output_plt /.dialyxir_core_18_1.3.2.plt --apps erts kernel stdlib crypto public_key -r /Elixir/lib/elixir/../eex/ebin /Elixir/lib/elixir/../elixir/ebin /Elixir/lib/elixir/../ex_unit/ebin /Elixir/lib/elixir/../iex/ebin /Elixir/lib/elixir/../logger/ebin /Elixir/lib/elixir/../mix/ebin
  Creating PLT /.dialyxir_core_18_1.3.2.plt ...
...
 done in 5m14.67s
done (warnings were emitted)
```

## Análise estática de código

Agora nós vamos usar o Dialyxir:

```shell
$ mix dialyzer
...
examples.ex:3: Invalid type specification for function 'Elixir.Examples':sum_times/1. The success typing is (_) -> number()
...
```

A mensagem do Dialyzer é clara: o tipo de retorno da nossa função `sum_times/1` é diferente do declarado. Isso ocorre porque `Enum.sum/1` retorna um `number` e não um `integer`, mas o tipo de retorno de `sum_times/1` é `integer`.

Como `number` não é `integer`, obtemos um erro. Como podemos consertar isso? Precisamos usar a função `round/1` para mudar nosso `number` para `integer`:

```elixir
@spec sum_times(integer) :: integer
def sum_times(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Finalmente:

```shell
$ mix dialyzer
...
  Proceeding with analysis... done in 0m0.95s
done (passed successfully)
```

O uso de especificações com ferramentas para realizar a análise de código estático nos ajuda a fazer com que o código seja auto-testado e contenha menos bugs.

# Debugging

Às vezes, a análise estática de código não é suficiente. Pode ser necessário entender o fluxo de execução para encontrar bugs. A maneira mais simples é colocar as instruções de saída em nosso código como `IO.puts/2` para rastrear valores e fluxo de código, mas essa técnica é primitiva e tem limitações. Felizmente para nós, podemos usar o Erlang debugger para depurar nosso código Elixir.

Vejamos um módulo básico:

```elixir
defmodule Example do
  def cpu_burns(a, b, c) do
    x = a * 2
    y = b * 3
    z = c * 5

    x + y + z
  end
end
```

Então rodamos o `iex`:

```bash
$ iex -S mix
```

E rodamos o debugger:

```elixir
iex > :debugger.start()
{:ok, #PID<0.307.0>}
```

O modulo `:debugger` do Erlang fornece acesso ao depurador. Podemos usar a função `start/1` para configurá-lo:

+ Um arquivo de configuração externo pode ser usado passando o caminho do arquivo.
+ Se o argumento for `:local` ou `:global`, o depurador vai:
    + `:global` – o depurador irá interpretar o código em todos os nós conhecidos. Esse é o valor padrão.
    + `:local` – o depurador irá interpretar o código somente no nó atual.

O próximo passo é anexar nosso módulo ao depurador:

```elixir
iex > :int.ni(Example)
{:module, Example}
```

O modulo `:int` é um intérprete que nos dá a capacidade de criar pontos de interrupção e passo através da execução do código.

Quando você inicia o depurador, você verá uma nova janela como esta:

![Debugger Screenshot 1]({% asset_path "debugger_1.png" %})

Depois de ter anexado o nosso módulo para o depurador estará disponível no menu à esquerda:

![Debugger Screenshot 2]({% asset_path "debugger_2.png" %})

## Criando breakpoints

Um breakpoint é um ponto no código onde a execução será interrompida. Temos duas maneiras de criar breakpoints:

+ `:int.break/2` em nosso código
+ O IU do depurador

Vamos tentar criar um breakpoint em IEx:

```elixir
iex > :int.break(Example, 8)
:ok
```

Isso define um breakpoint na linha 8 do módulo `Example`. Agora, quando chamamos nossa função:

```elixir
iex > Example.cpu_burns(1, 1, 1)
```

A execução será pausada no IEx e a janela do depurador deverá ter esta aparência:

![Debugger Screenshot 3]({% asset_path "debugger_3.png" %})

Aparecerá uma janela adicional com o nosso código fonte:

![Debugger Screenshot 4]({% asset_path "debugger_4.png" %})

Nesta janela, podemos procurar o valor das variáveis, avançar para a próxima linha ou avaliar expressões. `:int.disable_break/2` pode ser chamado para desabilitar um breakpoint:

```elixir
iex > :int.disable_break(Example, 8)
:ok
```

Para reativar um breakpoint, podemos chamar `:int.enable_break/2` ou podemos remover um ponto de interrupção como este exemplo:

```elixir
iex > :int.delete_break(Example, 8)
:ok
```

As mesmas operações estão disponíveis na janela do depurador. No menu superior, __Break__, nós podemos selecionar  __Line Break__ e configurar o breakpoints. Se selecionarmos uma linha que não contenha código, os pontos de interrupção serão ignorados, mas ele aparecerá na janela do depurador. Existem três tipos de breakpoint:

+ Breakpoint de linha - o depurador suspende a execução quando chegamos à linha, com a configuração `:int.break/2`
+ Breakpoint condicional — semelhante ao breakpoint de linha, mas o depurador suspende somente quando a condição especificada for atingida, estes são configurados usando `:int.get_binding/2`
+ Breakpoint da função - o depurador irá suspender na primeira linha de uma função, configurada usando `:int.break_in/3`

Isso é tudo! E um feliz debugging!
