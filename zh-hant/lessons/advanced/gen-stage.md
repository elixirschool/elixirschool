---
version: 1.1.0
title: GenStage
---

在本課程中，將仔細研究 GenStage、它的作用和如何在應用程式中利用。

{% include toc.html %}

## 簡介

那什麼是 GenStage？從官方文件來看，它是＂Elixir 的規範 (specification) 和計算流程 (computational flow)＂，但這表示著什麼？

這表示著 GenStage 提供了一種方式，在一個單獨過程中通過獨立 steps (或 stages) 來定義管線 (pipeline) 的工作以便執行它；如果之前使用過管線，那麼其中一些概念應該不陌生。

為了更好地理解它的工作原理，現在將一個簡易的生產者-消費者 (producer-consumer) 流程可視化：

```
[A] -> [B] -> [C]
```

在這個範例中，有三個 stages：`A` 消費者 (producer)，`B` 生產者-消費者 (producer-consumer) 與 `C` 消費者 (consumer)。  `A` 
產生一個被 `B` 消耗的值，`B` 執行一些工作並回傳將被 consumer `C` 收到的新值；我們將在下一節中看到，stage 的角色很重要。

雖然範例是 1 對 1 的生產者-消費者，但在任何特定 stage 都可能有多個生產者和多個消費者。

為了更好地描繪這些概念，將使用 GenStage 打造一個管線 (pipeline)，但首先探索一下 GenStage 會依賴頗多的這些角色。

## 消費者 (Consumers) 與生產者 (Producers)

正如所讀到的，我們賦予 stage 的角色非常重要。
GenStage 的規範中承認三種角色：

+ `:producer` — 源 (source)。
生產者等待消費者的需求並回應其所請求事件。

+ `:producer_consumer` — 是源（source）也是匯（sink）。
生產者－消費者可以回應其他消費者的需求，也能夠向生產者提出請求。

+ `:consumer` — 匯（sink）。
消費者向生產者提出請求並接收其資料。

注意到生產者是 __等待__ 需求了嗎？通過 GenStage，消費者是向上游發送需求並處理來自生產者的資料。
這有助於稱為背壓（back-pressure）的機制。
當消費者忙碌時，背壓機制使生產者不會造成超壓（over-pressure）。

現在已經介紹過 GenStage 中的角色，開始建立應用程式。

## 入門

在這個範例中，將建立一個產出數字的 GenStage 應用程式，能排序偶數後輸出。

在應用程式中，將使用全部三個 GenStage 角色。
生產者將負責計算和產出數字。
生產者－消費者則過濾出偶數，而後對下游需求做出回應。
最後建立消費者顯示剩餘數字。

讓我們從生成一個有 supervision 樹的專案開始：

```shell
$ mix new genstage_example --sup
$ cd genstage_example
```

現在更新 `mix.exs` 中的耦合性 (dependencies) 以包含 `gen_stage`：

```elixir
defp deps do
  [
    {:gen_stage, "~> 1.0.0"},
  ]
end
```

在進一步研究之前，應該先取得 (fetch) 耦合關係 (dependencies) 並進行編譯：

```shell
$ mix do deps.get, compile
```

現在準備好建立生產者了！

## 生產者

GenStage 應用程式的第一件事是建立生產者。
正如之前討論過的，我們想要建立一個能夠產出持續不斷數字流的生產者。
現在來建立生產者資料夾和檔案：

```shell
$ mkdir lib/genstage_example
$ touch lib/genstage_example/producer.ex
```

這時可以加入我們所需程式碼：

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

這裡需要注意兩個最重要部分是 `init/1` 和 `handle_demand/2`。
在 `init/1` 中，設置了初始狀態，就像在 GenServers 中做的那樣，但更重要的是，我們將自己標記為生產者。
`init/1` 函數的回傳值是 GenStage 對處理程序 (process) 進行分類的依據。

`handle_demand/2` 函數是生產者被定義的主要部份。
它必須由所有 GenStage 生產者實現。
在這裡，我們回傳消費者所需的一組數字，並累加我們的計數器（counter）。
來自消費者的需求，也就是上面程式碼中的 `demand`，被表示為一個能夠處理事件量的相對應整數；預設為 1000。

## 生產者 消費者 (Producer Consumer)

現在已經有了能產出數字的生產者，接著看生產者－消費者。
我們希望從生產者索取數字，濾除奇數，並能回應需求。

```shell
$ touch lib/genstage_example/producer_consumer.ex
```

現在更新檔案，使其看起來像範例內的程式碼：

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

你可能已經注意到，在生產者-消費者裡，`init/1` 已經引入了一個新選項和一個新函數： `handle_events/3`。
通過 `subscribe_to` 選項，指示 GenStage 讓我們在特定生產者的對話中（communication）。

`handle_events/3` 函數是我們的主力，接收傳入事件、處理 (process) 它們並回傳轉換後的集合。
而消費者的實現方式也大致相同，但重要的區別在於 `handle_events/3` 函數的回傳值以及如何被使用的。
當將處理程序標記為 producer_consumer 時，在範例中是 tuple 的第二個引數 - `numbers` 是用於達到下游的消費者需求；
但在消費者中，這個值會被丟棄。     

## 消費者

最後但並非最不重要的是消費者。
開始囉：

```shell
$ touch lib/genstage_example/consumer.ex
```

由於消費者和生產者-消費者如此相似，所以程式碼看起來不會有太大的不同：

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

正如在前面章節中所介紹的，消費者不會產出事件，所以 tuple 中的第二個值將被丟棄。

## 將所有角色組合在一起

現在已經建立了生產者、生產者-消費者和消費者，我們已經準備好將所有東西串在一起了。

首先打開 `lib/genstage_example/application.ex` 並將新處理程序加入到 supervisor 樹：

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

如果一切都是正確的，專案就可以執行，應該會看到所有東西都能正常運作：

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

我們做到了！正如預期那樣，應用程式只會產出偶數，而且它做的非常 __快__。

在此刻，我們有了一個工作管線（pipeline）。
生產者產出數字；生產者-消費者丟棄奇數；消費者則顯示以上這些並繼續流程。

## 多個生產者或消費者

在簡介中提到，有一個以上的生產者或消費者是可行的，
現在來看看這個。

如果檢查範例中的 `IO.inspect/1` 輸出，會看到每個事件都單獨由一個 PID 處理。
現在通過修改 `lib/genstage_example/application.ex` 對多個 worker 進行一些調整：

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

現在已經配置了兩個消費者，看看如果執行應用程式會得到什麼：

```shell
$ mix run --no-halt
{#PID<0.120.0>, 2, :state_doesnt_matter}
{#PID<0.121.0>, 4, :state_doesnt_matter}
{#PID<0.120.0>, 6, :state_doesnt_matter}
{#PID<0.120.0>, 8, :state_doesnt_matter}
...
{#PID<0.120.0>, 86478, :state_doesnt_matter}
{#PID<0.121.0>, 87338, :state_doesnt_matter}
{#PID<0.120.0>, 86480, :state_doesnt_matter}
{#PID<0.120.0>, 86482, :state_doesnt_matter}
```

正如所看到的，現在擁有多個 PID，只需簡單的加入一行程式碼並提供消費者 ID 即可。

## 使用案例

現在已經介紹了 GenStage 並建立了第一個範例應用程式，但 GenStage 有哪些 _真實_ 案例？

+ Data Transformation Pipeline — 生產者不盡然只能是簡單的數字生成器。
可以從資料庫或甚至像 Apache 的 Kafka 這樣的其他來源生成事件。
通過結合生產者-消費者和消費者，可以對度量（metrics）進行處理、排序、編目（catalog） 和儲存。

+ Work Queue — 由於事件可以是任何東西，因此可以生產由一系列被消費者完成的工作單元。

+ Event Processing — 與資料管線類似（data pipeline），能夠接收、處理，排序並針對從來源即時發生的事件採取行動。

而這些還只是 GenStage 的 __一小部分__ 可能性。