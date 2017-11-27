---
version: 1.0.1
title: Benchee
redirect_from:
  - /lessons/libraries/benchee/
---

Não podemos simplesmente adivinhar quais funções são rápidas e quais são lentas - precisamos de medidas reais quando estamos curiosos. É aí que _benchmarking_ entra. Nesta lição, aprenderemos sobre como é fácil medir a velocidade do nosso código.

{% include toc.html %}

# Sobre Benchee

Enquanto existe uma [função no Erlang](http://erlang.org/doc/man/timer.html#tc-1) que pode ser usada para medição muito básica do tempo de execução de uma função, ela não é tão boa de usar como algumas das ferramentas disponíveis e não lhe dá várias medidas para obter boas estatísticas, então vamos usar [Benchee](https://github.com/PragTob/benchee). Benchee nos fornece uma série de estatísticas com comparações fáceis entre cenários, uma ótima característica que nos permite testar diferentes entradas para as funções que estamos avaliando, e vários formatadores diferentes que podemos usar para mostrar nossos resultados, assim como a capacidade de escrever seu próprio formatador se desejado.

# Uso 

Para adicionar Benchee ao seu projeto, adicione-o como uma dependência ao seu arquivo `mix.exs`:
```elixir
defp deps do
  [{:benchee, "~> 0.9", only: :dev}]
end
```
Então chamamos:

```shell
$ mix deps.get
...
$ mix compile
```

O primeiro comando vai baixar e instalar o Benchee. Você pode ser solicitado a instalar o Hex junto com ele. O segundo compila a aplicação Benchee. Agora estamos prontos para escrever nosso primeiro _benchmark_!

**Uma nota importante antes de começarmos:** Quando avaliar comparativamente, é muito importante não usar `iex` uma vez que isso funciona de forma diferente e é frequentemente muito mais lento do que seu código usado em produção. Então, vamos criar um arquivo que chamaremos `benchmark.exs`, e nesse arquivo vamos adicionar o seguinte código.

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})
```

Agora para executar nosso _benchmark_, chamamos:

```shell
$ mix run benchmark.exs
```

E devemos ver algo com a seguinte saída no seu console:

```shell 
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: none specified
Estimated total run time: 14.00 s


Benchmarking flat_map...
Benchmarking map.flatten...

Name                  ips        average  deviation         median
flat_map           1.03 K        0.97 ms    ±33.00%        0.85 ms
map.flatten        0.56 K        1.80 ms    ±31.26%        1.60 ms

Comparison:
flat_map           1.03 K
map.flatten        0.56 K - 1.85x slower
```

É claro que as informações e os resultados do seu sistema podem ser diferentes dependendo das especificações da máquina em que você está executando seus _benchmarks_, mas esta informação geral deve estar toda lá.

À primeira vista, a seção `Comparison` nos mostra que a versão do nosso `map.flatten` é 1.85x mais lenta do que `flat_map` - muito útil saber! Mas vamos olhar as outras estatísticas que obtivemos:

* **ips** - isso significa "iterações por segundo", que nos diz com que frequência a função pode ser executada em um segundo. Para esta métrica, um número maior é melhor.
* **average** - este é o tempo médio de execução da função. Para esta métrica, um número baixo é melhor.
* **deviation** - este é o desvio padrão, que nos diz o quanto os resultados para cada iteração variam nos resultados. Aqui é dado como uma porcentagem da média.
* **median** - quando todos tempos medidos são ordenados, este é o valor médio (ou média dos dois valores do meio quando o número de amostras é par). Devido à inconsistências de ambiente este será mais estável do que a `average`, e um pouco mais provável que reflita a performance normal do seu código em produção. Para esta métrica, um número baixo é melhor.

Há também outras estatísticas disponíveis, mas estas quatro são frequentemente as mais úteis e comumente usadas para _benchmarking_,  por isso elas são exibidas no formatador padrão. Para aprender mais sobre outras métricas disponíveis, confira a documentação [hexdocs](https://hexdocs.pm/benchee/Benchee.Statistics.html#statistics/1).

# Configuração

Uma das melhores partes do Benchee são todas as opções de configuração disponíveis. Examinaremos o básico primeiro, uma vez que não requerem exemplos de código, e então mostraremos como usar uma das melhores características do Benchee - _inputs_.

## Básico

Benchee possui uma grande variedade de opções de configuração. Na interface mais comum `Benchee.run/2`, estas são passadas como segundo argumento na forma de uma _keywork list_ opcional:

```elixir
Benchee.run(%{"example function" => fn -> "hi!" end}, [
  warmup: 4,
  time: 10,
  inputs: nil,
  parallel: 1,
  formatters: [&Benchee.Formatters.Console.output/1],
  print: [ 
    benchmarking: true,
    configuration: true,
    fast_warning: true
  ],
  console: [
    comparison: true,
    unit_scaling: :best
  ]
])
```

As opções disponíveis são as seguintes (também documentadas em [hexdocs](https://hexdocs.pm/benchee/Benchee.Configuration.html#init/1)).

* **warmup** - o tempo em segundos para o qual um cenário de _benchmarking_ deve ser executado sem tempos de medição antes do início das medidas reais. Isso simula um sistema de funcionamento "quente". Padrão é 2.
* **time** - o tempo em segundos por quanto tempo cada cenário de _benchmarking_ individual deve ser executado e medido. Padrão é 5.
* **inputs** - um mapa com _strings_ que representam o nome de entrada como as chaves e a entrada real como valores. Padrão é `nil`. Vamos abordá-lo em detalhes na próxima seção.
* **parallel** - o número de processos para usar no _benchmark_ de suas funções. Então, se você definir `parallel: 4`, serão gerados 4 processos que executam a mesma função para determinado `time`. Quando estes terminam, então 4 novos processos serão gerados para a próxima função. Isso lhe dá mais dados no mesmo tempo, mas também adiciona mais carga ao sistema interferindo nos resultados do _benchmark_. Isso pode ser útil para simular um sistema sobrecarregado, o que algumas vezes é útil, mas deve ser usado com algum cuidado pois isso pode afetar os resultados de maneiras imprevisíveis. Padrão é 1 (o que significa nenhuma execução em paralelo). 
* **formatters** - a list of formatter functions you'd like to run to output the benchmarking results of the suite when using `Benchee.run/2`. Funções precisam aceitar um argumento (que é a suite de _benchmarking_ para todos dados) e então usá-la para produzir a saída. Padrão é o formatador de console embutido chamando `Benchee.Formatters.Console.output/1`. Vamos abordar mais sobre isso em uma seção posterior.
* **print** - um _map_ ou _keyword list_ com as seguintes opções como átomos para as chaves e valores de `true` ou `false`. Isso nos permite controlar se a saída identificada pelo átomo será impressa durante o processo padrão de _benchmarking_. Todas as opções são habilitadas por padrão (true). Opções são:
  * **benchmarking** - imprime quando Benchee inicia o _bencharking_ de um novo _job_.
  * **configuration** - um resumo de opções de _benchmarking_ configuradas, incluindo o tempo total de execução estimado. Isso é impresso antes do _benchmarking_ iniciar.
  * **fast_warning** - avisos são mostrados se funções são executadas muito rapidamente, potencialmente levando a medidas imprecisas.
* **console** - um _map_ ou _keyword list_ com as seguintes opções como átomos para as chaves e valores variáveis. Os valores de variáveis são listados para cada opção:
  * **comparison** - se a comparação dos diferentes _jobs_ de _benchmarking_ (x vezes mais lento do que) é mostrado. Padrão é `true`, mas também pode ser definido como `false`.
  * **unit_scaling** - a estratégia para escolher uma unidade para durações e contagens. Ao dimensionar um valor, Benchee encontra a unidade de "best fit" (a maior unidade para qual o resultado é ao menos 1). Por exemplo, `1_200_000` escala até 1.2 M, enquanto `800_000` escala até 800 K. A estratégia de escala da unidade determina como Benchee escolhe a unidade de "best fit" para uma lista inteira de valores, quando os valores individualemnte na lista podem ter diferentes unidades de "best fit". Existem quatro estratégias, todas dadas como átomos, padronizadas como `:best`:
    * **best** - a mais frequente unidade de _best fit_ será usada. Um empate resultará na maior unidade sendo selecionada.
    * **largest** - a maior unidade de _best fit_ será usada
    * **smallest** - a menor unidade de _best fit_ será usada
    * **none** - nenhuma escala de unidade ocorrerá. Durações serão mostradas em microsegundos, e contadores de _ips_ serão mostrados sem unidades.

## Inputs

É muito importante fazer o _benchmark_ de suas funções com dados que refletem o que a função pode realmente operar no mundo real. Frequentemente uma função pode se comportar diferentemente em conjuntos menores de dados versus conjuntos grandes de dados! Isso é onde a configuração de `input` do Benchee entra. Isso permite que você teste a mesma função mas com muitas entradas diferentes conforme desejar, e então você pode ver os resultados do _benchmark_ com cada uma dessas funções.

Então, vamos olhar nosso exemplo original novamente:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})
```

No exemplo estamos usando apenas uma lista simples de inteiros de 1 à 10.000. Vamos atualizar isso para usar algumas entradas diferentes para que possamos ver o que acontece com listas menores e maiores. Então, abra o arquivo, e nós vamos mudá-lo para ficar assim:

```elixir
map_fun = fn i -> [i, i * i] end

inputs = %{
  "small list" => Enum.to_list(1..100),
  "medium list" => Enum.to_list(1..10_000),
  "large list" => Enum.to_list(1..1_000_000)
}

Benchee.run(
  %{
    "flat_map" => fn list -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn list -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  inputs: inputs
)
```

Você notará duas diferenças. Primeiro, agora temos um mapa `inputs` que contém a informação para nossas entradas para nossas funções. Estamos passando aquele mapa de entradas como uma opção de configuração para `Benchee.run/2`.

E como nossas funções precisam de um argumento agora, precisamos atualizar nossas funções de benchmark para aceitar um argumento, então em vez de:
```elixir
fn -> Enum.flat_map(list, map_fun) end
```

agora temos:
```elixir
fn list -> Enum.flat_map(list, map_fun) end
```

Vamos rodar isso novamente usando:

```shell
$ mix run benchmark.exs
```

Agora você deve ver a saída no seu console como isso:

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: large list, medium list, small list
Estimated total run time: 2.10 min

Benchmarking with input large list:
Benchmarking flat_map...
Benchmarking map.flatten...

Benchmarking with input medium list:
Benchmarking flat_map...
Benchmarking map.flatten...

Benchmarking with input small list:
Benchmarking flat_map...
Benchmarking map.flatten...


##### With input large list #####
Name                  ips        average  deviation         median
flat_map             6.29      158.93 ms    ±19.87%      160.19 ms
map.flatten          4.80      208.20 ms    ±23.89%      200.11 ms

Comparison:
flat_map             6.29
map.flatten          4.80 - 1.31x slower

##### With input medium list #####
Name                  ips        average  deviation         median
flat_map           1.34 K        0.75 ms    ±28.14%        0.65 ms
map.flatten        0.87 K        1.15 ms    ±57.91%        1.04 ms

Comparison:
flat_map           1.34 K
map.flatten        0.87 K - 1.55x slower

##### With input small list #####
Name                  ips        average  deviation         median
flat_map         122.71 K        8.15 μs   ±378.78%        7.00 μs
map.flatten       86.39 K       11.58 μs   ±680.56%       10.00 μs

Comparison:
flat_map         122.71 K
map.flatten       86.39 K - 1.42x slower
```

Agora podemos ver informações para nossos _benchmarks_, agrupados por entrada. Este exemplo simples não fornece nenhuma intuição surpreendente, mas você ficaria bem surpreso o quanto a performance varia baseada no tamanho da entrada.

# Formatadores

A saída do console que vimos é um começo útil para medir o tempo de execução de funções, mas não é sua única opção. Nessa seção vamos olhar brevemente os três formatadores disponíveis, e também tocar no que você vai precisar para escrever seu próprio formatador se quiser.

## Outros formatadores

Benchee tem um formatador embutido no console, que é o que já vimos, mas há outros três formatadores oficialmente suportados - `benchee_csv`, `benchee_json` e `benchee_html`. Cada um deles faz exatamente o que você esperaria, que é escrever os resultados no formato dos arquivos nomeados de forma que você possa trabalhar os resultados futuramente no formato que quiser.

Cada um desses formatadores é um pacote separado, então para usá-los você precisa adicioná-los como dependências no seu arquivo `mix.exs` como:

```elixir
defp deps do
  [
    {:benchee_csv, "~> 0.6", only: :dev},
    {:benchee_json, "~> 0.3", only: :dev},
    {:benchee_html, "~> 0.3", only: :dev}
  ]
end
```

Enquanto `benchee_json` e `benchee_csv` são muito simples, `benchee_html` é na verdade muito completo! Ele pode ajudá-lo a produzir belos diagramas e gráficos de seus resultados facilmente, e você pode até mesmo exportá-los como imagens PNG. Todos os três formatadores são bem documentados nas suas respectivas páginas no GitHub, então não vamos cobrir todos os detalhes deles aqui.

## Formatadores customizados

Se os quatro formatadores não são suficientes para você, você também pode escrever seu próprio formatador. Escrever um formatador é bem fácil. Você precisa escrever uma função que aceite uma estrutura `%Benchee.Suite{}`, e dela você pode tirar qualquer informação que você queira. Informação sobre o que exatamente está nessa estrutura pode ser encontrada no [GitHub](https://github.com/PragTob/benchee/blob/master/lib/benchee/suite.ex) ou [HexDocs](https://hexdocs.pm/benchee/Benchee.Suite.html). A base de código é bem documentada e fácil de ler se quiser ver quais tipos de informações podem estar disponíveis para escrever formatadores personalizados.

Por enquanto, vou mostrar um exemplo rápido de como um formatador customizado se pareceria como um exemplo de quão fácil ele é. Digamos que queremos um formatador mínimo que apenas imprima o tempo médio de cada cenário - isso é como ele se pareceria:

```elixir
defmodule Custom.Formatter do
  def output(suite) do
    suite
    |> format
    |> IO.write()

    suite
  end

  defp format(suite) do
    Enum.map_join(suite.scenarios, "\n", fn scenario ->
      "Average for #{scenario.job_name}: #{scenario.run_time_statistics.average}"
    end)
  end
end
```

E então podemos rodar nosso _benchmark_ desta forma:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  formatters: [&Custom.Formatter.output/1]
)
```

E quando rodamos agora como nosso formatador customizado, veremos:

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
Number of Available Cores: 4
Available memory: 8.589934592 GB
Elixir 1.5.1
Erlang 20.0
Benchmark suite executing with the following configuration:
warmup: 2.00 s
time: 5.00 s
parallel: 1
inputs: none specified
Estimated total run time: 14.00 s


Benchmarking flat_map...
Benchmarking map.flatten...
Average for flat_map: 851.8840109326956
Average for map.flatten: 1659.3854339873628
```
