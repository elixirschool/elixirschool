---
version: 1.1.3
title: Depuração
---

Bugs são problemas comuns em qualquer projeto, é por isso que precisamos da depuração.

Nesta sessão vamos aprender sobre como fazer depuração no código Elixir, bem como ferramentas de análises estáticas para ajudar a encontrar possíveis bugs.

{% include toc.html %}

## IEx

A ferramenta mais direta que nós temos para depurar código Elixir é o IEx

Mas não se deixa enganar por sua simplicidade - você pode resolver a maioria dos problemas da sua aplicação com ele.

IEx significa `Elixir's Interactive Shell`.

Você pode já ter visto o IEx em uma das lições anteriores como [Básicos](../../basisc/basics) onde nós executamos código interativo no shell.

A ideia aqui é simples.

Você inicia o shell interativo no contexto do local que deseja depurar.

Vamos tentar.

```elixir
defmodule TestMod do
  def sum([a, b]) do
    b = 0

    a + b
  end
end

IO.puts(TestMod.sum([34, 65]))
```

E se você executar isso - você receberá uma saída aparente de '34':

```shell
$ elixir test.exs
warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
 test.exs:2

34
```

Mas agora vamos para a parte empolgante - a depuração.

Insira `require IEx; IEx.pry` depois da linha com `b = 0` e vamos tentar executar o código novamente.

Você vai receber algo assim:

```shell
$ elixir test.exs
warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

Cannot pry #PID<0.92.0> at TestMod.sum/1 (test.exs:5). Is an IEx shell running?
34
```

Você deve perceber aquela mensagem crucial.

Quando estiver executando uma aplicação, como sempre, o IEx gera essa mensagem em vez de bloquear a execução do programa.

Para executar ela apropriadamente você precisa prefixar seu comando com `iex -S`.

O que isso faz é executar `mix` dentro do comando `iex`, fazendo com que a aplicação seja executada em um modo especial, de tal jeito que chame `IEx.pry` para parar a execução da aplicação.

Por exemplo, use `iex -S mix phx.server` para depurar sua aplicação Phoenix. No nosso caso será `iex -r test.exs` para requerir o arquivo:

```elixir
$ iex -r test.exs
Erlang/OTP 21 [erts-10.3.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

Request to pry #PID<0.107.0> at TestMod.sum/1 (test.exs:5)

    3:     b = 0
    4:
    5:     require IEx; IEx.pry
    6:
    7:     a + b

Allow? [Yn]
```

Depois de responder a confirmação com `y` ou pressionar Enter, você vai entrar no modo interativo.

```elixir
$ iex -r test.exs
Erlang/OTP 21 [erts-10.3.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

warning: variable "b" is unused (if the variable is not meant to be used, prefix it with an underscore)
  test.exs:2

Request to pry #PID<0.107.0> at TestMod.sum/1 (test.exs:5)

    3:     b = 0
    4:
    5:     require IEx; IEx.pry
    6:
    7:     a + b

Allow? [Yn] y
Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)
pry(1)> a
34
pry(2)> b
0
pry(3)> a + b
34
pry(4)> continue
34

Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
BREAK: (a)bort (c)ontinue (p)roc info (i)nfo (l)oaded
       (v)ersion (k)ill (D)b-tables (d)istribution
```
Para sair do IEx, você pode pressionar `Ctrl + C` duas vezes para sair do aplicativo ou digitar `continue` para seguir para o próximo breakpoint.

Como você pode ver, é possivel executar qualquer código Elixir.

Entretato, a limitação é que você não pode modificar nenhuma variável do código existente, devido a imutabilidade da linguagem.

Apesar disso, você pode obter todos os valores das variáveis e executar qualquer computação.

Nesse caso, o bug seria em `b` sendo reatribuído para 0, e a função `sum` sendo afetada como resultado.

Claro, a linguagem já capturou esse bug até mesmo na primeira execução, mas isso é um exemplo!

### IEx.Helpers

Uma das partes mais chatas de trabalhar com o IEx é que ele não tem nenhum histórico de comandos que você usou em execuções anteriores.

Para resolver esse problema, existe uma subseção na [Documentação do IEx](https://hexdocs.pm/iex/IEx.html#module-shell-history), onde você pode achar a solução de acordo com sua plataforma.

Você também pode checar a lista com o resto dos utilitários disponíveis na [Documentação de Helpers do IEx](https://hexdocs.pm/iex/IEx.Helpers.html).

## Dialyxir e Dialyzer

O [Dialyzer](http://erlang.org/doc/man/dialyzer.html) (**DI**screpancy **A**na**LYZ**er for **ER**lang), é uma ferramenta para análise de
código estático.
Em outras palavras eles _leem_ e analisam mas não _rodam_ o código. Exemplo:
procurando por alguns bugs, códigos mortos, desnecessários ou inacessíveis.

O [Dialyxir](https://github.com/jeremyjh/dialyxir) é uma tarefa mix para simplificar o uso do Dialyzer em Elixir.

Ferramentas de especificação como o Dialyzer ajudam a entender melhor o código.
Ao contrário da documentação, que é legível por humanos (se apenas existe e é bem escrito), `@spec` usa uma sintaxe mais formal e que pode ser entendida pela máquina.

Vamos adicionar Dialyxir ao nosso projeto.
A maneira mais simples é adicionar dependência ao arquivo `mix.exs`:

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

O primeiro comando vai fazer o download e instalar o Dialyxir.
Você pode ser solicitado a instalar o Hex juntamente com ele.
O segundo vai compilar a aplicação Dialyxir. Se você deseja instalar o Dialyxir globalmente, por favor leia esta [documentação](https://github.com/jeremyjh/dialyxir#installation).

O último passo é rodar o Dialyzer para reconstruir o PLT (Persistent Lookup Table).
Você precisa fazer isso toda vez após a instalação de uma nova versão do Erlang ou Elixir.
Felizmente, o Dialyzer não tentará analisar a biblioteca padrão toda vez que você tentar usá-lo.
Demora alguns minutos para que o download seja concluído.

```shell
$ mix dialyzer --plt
Starting PLT Core Build ... this will take awhile
dialyzer --build_plt --output_plt /.dialyxir_core_18_1.3.2.plt --apps erts kernel stdlib crypto public_key -r /Elixir/lib/elixir/../eex/ebin /Elixir/lib/elixir/../elixir/ebin /Elixir/lib/elixir/../ex_unit/ebin /Elixir/lib/elixir/../iex/ebin /Elixir/lib/elixir/../logger/ebin /Elixir/lib/elixir/../mix/ebin
  Creating PLT /.dialyxir_core_18_1.3.2.plt ...
...
 done in 5m14.67s
done (warnings were emitted)
```

### Análise estática de código

Agora nós vamos usar o Dialyxir:

```shell
$ mix dialyzer
...
examples.ex:3: Invalid type specification for function 'Elixir.Examples':sum_times/1.
The success typing is (_) -> number()
...
```

A mensagem do Dialyzer é clara: o tipo de retorno da nossa função `sum_times/1` é diferente do declarado.
Isso ocorre porque `Enum.sum/1` retorna um `number` e não um `integer`, mas o tipo de retorno de `sum_times/1` é `integer`.

Como `number` não é `integer`, obtemos um erro.
Como podemos consertar isso? Precisamos usar a função `round/1` para mudar nosso `number` para `integer`:

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
  Proceeding with analysis...
done in 0m0.95s
done (passed successfully)
```

O uso de especificações com ferramentas para realizar a análise de código estático nos ajuda a fazer com que o código seja auto-testado e contenha menos bugs.

## Depuração

Às vezes, a análise estática de código não é suficiente.
Pode ser necessário entender o fluxo de execução para encontrar bugs.
A maneira mais simples é colocar as instruções de saída em nosso código como `IO.puts/2` para rastrear valores e fluxo de código, mas essa técnica é primitiva e tem limitações.
Felizmente para nós, podemos usar o Erlang debugger para depurar nosso código Elixir.

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

O modulo `:debugger` do Erlang fornece acesso ao depurador.
Podemos usar a função `start/1` para configurá-lo:

+ Um arquivo de configuração externo pode ser usado passando o caminho do arquivo.
+ Se o argumento for `:local` ou `:global`, o depurador vai:
    + `:global` – o depurador irá interpretar o código em todos os nós conhecidos.
    Esse é o valor padrão.
    + `:local` – o depurador irá interpretar o código somente no nó atual.

O próximo passo é anexar nosso módulo ao depurador:

```elixir
iex > :int.ni(Example)
{:module, Example}
```

O modulo `:int` é um intérprete que nos dá a capacidade de criar pontos de interrupção e passo através da execução do código.

Quando você inicia o depurador, você verá uma nova janela como esta:

![Debugger Screenshot 1]({% asset debugger_1.png @path %})

Depois de ter anexado o nosso módulo para o depurador estará disponível no menu à esquerda:

![Debugger Screenshot 2]({% asset debugger_2.png @path %})

### Criando breakpoints

Um breakpoint é um ponto no código onde a execução será interrompida.
Temos duas maneiras de criar breakpoint:

+ `:int.break/2` em nosso código
+ O IU do depurador

Vamos tentar criar um breakpoint em IEx:

```elixir
iex > :int.break(Example, 8)
:ok
```

Isso define um breakpoint na linha 8 do módulo `Example`.
Agora, quando chamamos nossa função:

```elixir
iex > Example.cpu_burns(1, 1, 1)
```

A execução será pausada no IEx e a janela do depurador deverá ter esta aparência:

![Debugger Screenshot 3]({% asset debugger_3.png @path %})

Aparecerá uma janela adicional com o nosso código fonte:

![Debugger Screenshot 4]({% asset debugger_4.png @path %})

Nesta janela, podemos procurar o valor das variáveis, avançar para a próxima linha ou avaliar expressões.
`:int.disable_break/2` pode ser chamado para desabilitar um breakpoint:

```elixir
iex > :int.disable_break(Example, 8)
:ok
```

Para reativar um breakpoint, podemos chamar `:int.enable_break/2` ou podemos remover um breakpoint como este exemplo:

```elixir
iex > :int.delete_break(Example, 8)
:ok
```

As mesmas operações estão disponíveis na janela do depurador. No menu superior, __Break__, nós podemos selecionar  __Line Break__ e configurar o breakpoint. Se selecionarmos uma linha que não contenha código, os pontos de interrupção serão ignorados, mas ele aparecerá na janela do depurador. Existem três tipos de breakpoint:

+ Breakpoint de linha - o depurador suspende a execução quando chegamos à linha, com a configuração `:int.break/2`
+ Breakpoint condicional — semelhante ao breakpoint de linha, mas o depurador suspende somente quando a condição especificada for atingida, estes são configurados usando `:int.get_binding/2`
+ Breakpoint da função - o depurador irá suspender na primeira linha de uma função, configurada usando `:int.break_in/3`

Isso é tudo! E um feliz debugging!
