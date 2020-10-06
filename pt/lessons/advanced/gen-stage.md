---
version: 1.1.1
title: GenStage
---

Nesta lição vamos examinar de perto o GenStage, para que serve e como podemos usá-lo em nossas aplicações.

{% include toc.html %}

## Introdução

Então, o que é GenStage? De acordo com a documentação oficial, é uma "especificação e um fluxo computacional para o Elixir", mas o que isso significa pra nós?

Significa que o GenStage nos fornece uma forma de definir um pipeline de trabalho a ser realizado por passos independentes (ou etapas) em processos separados; se você já trabalhou com pipelines anteriormente, então alguns desses conceitos devem ser familiares.

Para entender melhor como isso funciona, vamos visualizar um simples fluxo produtor-consumidor:

```
[A] -> [B] -> [C]
```

Neste exemplo temos três etapas: `A` um produtor, `B` um produtor-consumidor, e `C` um consumidor.  `A` produz um valor que é consumido por `B`, `B` executa algum trabalho e retorna um novo valor que é recebido pelo nosso consumidor `C`; o papel da nossa etapa é importante como veremos na próxima seção.

Enquanto nosso exemplo é 1-para-1, produtor-para-consumidor, é possível que ambos tenham múltiplos produtores e múltiplos consumidores em qualquer etapa.

Para ilustrar melhor esses conceitos, vamos construir um pipeline com GenStage, mas antes vamos explorar os papéis que o GenStage depende um pouco mais.

## Consumidores e Produtores

Conforme lemos, o papel que damos à nossa etapa é importante. A especificação do GenStage reconhece três papéis:

+ `:producer` — Uma fonte. Produtores esperam por demanda de consumidores e respondem com os eventos solicitados.

+ `:producer_consumer` — Tanto uma fonte como um tanque. Produtor-consumidores podem responder por demandas de outros consumidores assim como solicitar eventos de produtores.

+ `:consumer` — Um tanque. Um consumidor solicita e recebe dados de produtores.

Notou que nossos produtores __esperam__ por demanda? Com o GenStage nossos consumidores enviam demanda e processam os dados de nosso produtor. Isso facilita o mecanismo conhecido como _back-pressure_. _Back-pressure_ coloca o ônus no produtor a não gerar sobrepressão quando consumidores estão ocupados.

Agora que cobrimos os papéis dentro do GenStage, vamos começar a nossa aplicação.

## Começando

Neste exemplo construiremos uma aplicação GenStage que emite números, separa os números pares, e finalmente os imprime.

Para nossa aplicação usaremos todos os três papéis do GenStage. Nosso produtor será responsável por contar e emitir números. Usaremos um produtor-consumidor para filtrar somente os números pares e depois responder à demanda. Por último, vamos construir um consumidor para nos mostrar os números restantes.

Começaremos gerando um projeto com uma árvore de supervisão:

```shell
$ mix new genstage_example --sup
$ cd genstage_example
```

Vamos atualizar nossas dependências no `mix.exs` para incluir `gen_stage`:

```elixir
defp deps do
  [
    {:gen_stage, "~> 1.0.0"}
  ]
end
```

Devemos buscar nossas dependências e compilar antes de avançar mais:

```shell
$ mix do deps.get, compile
```

Agora estamos prontos para construir nosso produtor!

## Produtor

O primeiro passo da nossa aplicação GenStage é criar nosso produtor. Conforme falamos antes, queremos criar um produtor que emite um fluxo constante de números. Vamos criar o arquivo do nosso produtor:

```shell
$ touch lib/genstage_example/producer.ex
```

Agora podemos adicionar o código:

```elixir
defmodule GenstageExample.Producer do
  use GenStage

  def start_link(initial \\ 0) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(counter), do: {:producer, counter}

  def handle_demand(demand, state) do
    events = Enum.to_list(state..(state + demand - 1))
    {:noreply, events, state + demand}
  end
end
```

As duas partes mais importantes para tomar nota aqui são `init/1` e `handle_demand/2`. No `init/1` definimos o estado inicial como fizemos em nossos GenServers, mas mais importante, nos rotulamos como produtores. A resposta da nossa função `init/1` é o que o GenStage confia para classificar nossos processo.

A função `handle_demand/2` é onde a maioria de nosso produtor está definida. Ela precisa ser implementada por todos os produtores GenStage. Aqui retornamos o conjunto de números demandados pelos nossos consumidores e incrementamos nosso contador. A demanda dos consumidores, `demand` no nosso código acima, é representada como um inteiro correspondendo ao número de eventos que eles podem tratar; seu padrão é 1000.

## Produtor Consumidor

Agora que temos um produtor gerador de números, vamos ao nosso produtor-consumidor. Queremos solicitar números de nosso produtor, filtrar os ímpares, e responder à demanda.

```shell
$ touch lib/genstage_example/producer_consumer.ex
```

Vamos atualizar nosso arquivo para se parecer com o código de exemplo:

```elixir
defmodule GenstageExample.ProducerConsumer do
  use GenStage

  require Integer

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state_doesnt_matter, name: __MODULE__)
  end

  def init(state) do
    {:producer_consumer, state, subscribe_to: [GenstageExample.Producer]}
  end

  def handle_events(events, _from, state) do
    numbers =
      events
      |> Enum.filter(&Integer.is_even/1)

    {:noreply, numbers, state}
  end
end
```

Você deve ter notado com nosso produtor-consumidor que introduzimos uma nova opção no `init/1` e uma nova função: `handle_events/3`. Com a opção `subscribe_to`, instruímos o GenStage a nos colocar em comunicação com um produtor específico.

A função `handle_events/3` é nosso cavalo de batalha, onde recebemos nossos eventos de entrada, os processamos, e retornamos nosso conjunto modificado. Como veremos, consumidores são implementados de maneira muito semelhante, mas a diferença importante é que nossa função `handle_events/3` retorna e como ela é usada. Quando rotulamos nosso processo um produtor_consumidor, o segundo argumento da nossa tupla — `numbers` no nosso caso — é usado para conhecer a demanda de consumidores. Em consumidores esse valor é descartado.

## Consumidor

Por último, mas não menos importante, nós temos nosso consumidor. Vamos começar:

```shell
$ touch lib/genstage_example/consumer.ex
```

Uma vez que consumidores e produtores-consumidores são tão similares, nosso código não será muito diferente:

```elixir
defmodule GenstageExample.Consumer do
  use GenStage

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [GenstageExample.ProducerConsumer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect({self(), event, state})
    end

    # As a consumer we never emit events
    {:noreply, [], state}
  end
end
```

Conforme abordamos na seção anterior, nosso consumidor não emite eventos, então o segundo valor em nossa tupla será descartado.

## Colocando tudo junto

Agora que temos nosso produtor, produtor-consumidor, e consumidor construídos, estamos prontos para ligá-los todos juntos.

Vamos começar abrindo o `lib/genstage_example/application.ex` e adicionando nosso novo processo para a árvore de supervisores:

```elixir
def start(_type, _args) do
  import Supervisor.Spec, warn: false

  children = [
    {GenstageExample.Producer, 0},
    {GenstageExample.ProducerConsumer, []},
    {GenstageExample.Consumer, []}
  ]

  opts = [strategy: :one_for_one, name: GenstageExample.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Se tudo estiver certo, podemos executar nosso projeto e devemos ver tudo funcionando:

```shell
$ mix run --no-halt
{#PID<0.109.0>, 2, :state_doesnt_matter}
{#PID<0.109.0>, 4, :state_doesnt_matter}
{#PID<0.109.0>, 6, :state_doesnt_matter}
...
{#PID<0.109.0>, 229062, :state_doesnt_matter}
{#PID<0.109.0>, 229064, :state_doesnt_matter}
{#PID<0.109.0>, 229066, :state_doesnt_matter}
```

Pronto! Como esperávamos, nossa aplicação apenas omite números pares e faz isso __rapidamente__.

Neste ponto temos um pipeline funcionando. Existe um produtor emitindo números, um produtor-consumidor descartando números ímpares, e um consumidor mostrando tudo isso e continuando o fluxo.

## Múltiplos Produtores ou Consumidores

Mencionamos na introdução que era possível ter mais que um produtor ou consumidor. Vamos dar uma olhada nisso.

Se examinarmos a saída do `IO.inspect/1` do nosso exemplo, vemos que todo evento é tratado por um único PID. Vamos fazer alguns ajustes para múltiplos _workers_ modificando o `lib/genstage_example/application.ex`:

```elixir
children = [
  {GenstageExample.Producer, 0},
  {GenstageExample.ProducerConsumer, []},
  %{
    id: 1,
    start: {GenstageExample.Consumer, :start_link, [[]]}
  },
  %{
    id: 2,
    start: {GenstageExample.Consumer, :start_link, [[]]}
  },
]
```

Agora que configuramos dois consumidores, vamos ver o que obtemos se rodarmos nossa aplicação agora:

```shell
$ mix run --no-halt
{#PID<0.120.0>, 0, :state_doesnt_matter}
{#PID<0.120.0>, 2, :state_doesnt_matter}
{#PID<0.120.0>, 4, :state_doesnt_matter}
{#PID<0.120.0>, 6, :state_doesnt_matter}
...
{#PID<0.120.0>, 86478, :state_doesnt_matter}
{#PID<0.121.0>, 87338, :state_doesnt_matter}
{#PID<0.120.0>, 86480, :state_doesnt_matter}
{#PID<0.120.0>, 86482, :state_doesnt_matter}
```

Como você pode ver, agora nós temos múltiplos PIDs, simplesmente adicionando uma linha de código e dando IDs aos nossos consumidores.

## Casos de Uso

Agora que cobrimos o GenStage e construímos nossa primeira aplicação exemplo, quais são alguns casos de uso _reais_ do GenStage?

+ Pipeline de Transformação de Dados — Produtores não precisam ser simples geradores de números. Poderíamos produzir eventos de um banco de dados ou mesmo de outra fonte como Apache Kafka. Com uma combinação de produtor-consumidores e consumidores, podemos processar, ordenar, catalogar, e armazenar métricas à medida que elas ficam disponíveis.

+ Filas de Trabalho — Uma vez que eventos podem ser qualquer coisa, poderíamos produzir unidades de trabalho para serem completadas por uma séries de consumidores.

+ Processamento de Eventos — Semelhante a um pipeline de dados, poderíamos receber, processar, classificar e agir em eventos emitidos em tempo real de nossas fontes.

Estas são apenas __algumas__ possibilidades para o GenStage.
