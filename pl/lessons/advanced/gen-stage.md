---
layout: page
title: GenStage
category: advanced
order: 11
lang: pl
---

W tej lekcji przyjrzymy się z bliska GenStage, jaką pełni funkcję i jak może mieć wpływ na nasze aplikacje. 

{% include toc.html %}

## Wstęp

Zatem czym jest GenStage? Oficjalna dokumentacja mówi, że jest to „specification and computational flow”, co można rozumieć jako silnik reguł obliczeniowych, ale co to w praktyce oznacza?

Oznacza to, że GenStage pozwala nam na zdefiniowanie potoków pracy, podzielonych na niezależne kroki (etapy), które będą obsługiwane przez różne procesy. Jeżeli wcześniej pracowałeś z potokami, to wiele przedstawionych tu elementów będzie znajome. 

By lepiej zrozumieć jak, to wszystko działa przyjrzyjmy się prostemu potokowi producent-konsument:

```
[A] -> [B] -> [C]
```

W tym przykładzie mamy trzy etapy: `A` producenta, `B` producenta i konsumenta oraz`C` konsumenta. `A` produkuje wartości konsumowane przez `B`, `B` wykonuje pewne zadania, produkując wartość konsumowaną przez `C`. Rola poszczególnych etapów jest kluczowa, co za chwilę zobaczymy.

Nasz przykład to prosty układ 1 do 1, ale możemy tworzyć systemy z wieloma producentami i wieloma konsumentami na dowolnym etapie.

By lepiej zrozumieć ten mechanizm, stworzymy potok z użyciem GenStage, ale zanim do tego przystąpimy, musimy poznać koncepcję ról, z której korzysta GenStage.

## Producenci i konsumenci

Jak już wiemy role, które przypisujemy do poszczególnych etapów, są bardzo ważne. Specyfikacja GenStage definiuje trzy role:

+ `:producer` — źródło. Producent oczekuje na zapotrzebowanie zgłoszone przez konsumentów i odpowiada żądanym zasobem.

+ `:producer_consumer` — źródło jak i cel. Producent-konsument potrafi odpowiadać na żądania innych konsumentów jak i samemu wysyłać je do innych producentów.

+ `:consumer` — cel. Wysyła żądania do producentów oraz przetwarza otrzymane dane.

Co znaczy, że producenci __oczekują__ na żądania? Konsumenci GenStage wysyłają strumień żądań i następnie przetwarzają dane otrzymane od producentów. Mechanizm ten znany jest jako ciśnienie wsteczne (ang. back-pressure). Ciśnienie wsteczne przenosi ciężar na producentów, chroniąc aplikację przed przeciążeniem, gdy konsumenci są zajęci. 

Gdy wiemy już, czym są role w GenStage, możemy rozpocząć pisanie aplikacji.

## Pierwsze kroki

Nasza przykładowa aplikacja używająca GenStage będzie generować strumień liczb, sortować numery parzyste i w końcu wypisywać je.

Użyjemy wszystkich ról GenStage. Producent będzie odliczać i emitować kolejne numery. Użyjemy producenta-konsumenta do odfiltrowania numerów parzystych oraz późniejszego ich odesłania do konsumenta, który będzie wyświetlać je na ekranie. 

Naszą pracę zaczniemy od stworzenia projektu z wykorzystaniem drzewa nadzorców:

```shell
$ mix new genstage_example --sup
$ cd genstage_example
```

Następnie zmieńmy `mix.exs` dodając zależność do `gen_stage`:

```elixir
  defp deps do
    [
      {:gen_stage, "~> 0.7"},
    ]
  end
```

Musimy pobrać i skompilować zależności zanim przejdziemy dalej: 

```shell
$ mix do deps.get, compile
```

I już jesteśmy gotowi by stworzyć naszego producenta!

## Producent

Pierwszym krokiem w naszej aplikacji jest stworzenie producenta. Tak jak wcześniej zaplanowaliśmy, chcemy stworzyć producenta, który będzie emitował stały strumień liczb. Stworzymy zatem plik modułu: 

```shell
$ mkdir lib/genstage_example
$ touch lib/genstage_example/producer.ex
```

I dodajmy kod:

```elixir
defmodule GenstageExample.Producer do
  alias Experimental.GenStage

  use GenStage

  def start_link(initial \\ 0) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(counter), do: {:producer, counter}

  def handle_demand(demand, state) do
    events = Enum.to_list(state..state + demand - 1)
    {:noreply, events, (state + demand)}
  end
end
```

Dwa najważniejsze elementy, na które trzeba zwrócić uwagę to `init/1` i `handle_demand/2`. W funkcji `init/1` ustawiamy stan początkowy, ale co ważniejsze określamy moduł jako producenta. Odpowiedź z `init/1` pozwala GenStage na klasyfikację procesu.

W funkcji `handle_demand/2` jest centrum logiki producenta i musi być zaimplementowana we wszystkich producentach GenStage. To tutaj zwracamy zbiór numerów żądanych przez konsumentów i zwiększamy licznik. Żądanie ze strony konsumentów, parametr `demand`, odpowiada liczbie całkowitej określającej maksymalną ilość zdarzeń, której mogą oni podołać. Domyślnie jest to 1000. 

## Producent-konsument

Teraz gdy mamy już naszego producenta generującego liczby, możemy zająć się producentem-konsumentem. Będzie on żądać od producenta zbioru liczb, wybierać tylko parzyste i odsyłać tak odfiltrowany zbiór na żądanie konsumenta.

```shell
$ touch lib/genstage_example/producer_consumer.ex
```

Po utworzeniu pliku dodajmy kod:

```elixir
defmodule GenstageExample.ProducerConsumer  do
  alias Experimental.GenStage
  use GenStage

  require Integer

  def start_link do
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

Jak łatwo zauważyć w funkcji `init/1` dodaliśmy nową opcję oraz zdefiniowaliśmy funkcję `handle_events/3`.  Za pomocą opcji `subscribe_to` instruujemy GenStage, że chcemy komunikować się z określonym producentem.

Funkcja `handle_events/3` to nasz koń roboczy. Obsługujemy tutaj przychodzące odpowiedzi, transformując zbiór danych. Jak widać konsumenci są implementowani w podobny sposób, ale ważną różnicą jest to co zwraca funkcja `handle_events/3` i to jak jest używana. Jeżeli oznaczymy nasz proces jako producenta-konsumenta, drugi argument w krotce, tu `numbers`, zostanie wykorzystany do odpowiadania na żądania. W przypadku konsumentów będzie on zignorowany.

## Consumer

Last but not least we have our consumer.  Let's get started:

```shell
$ touch lib/genstage_example/consumer.ex
```

Since consumers and producer-consumers are so similar our code won't look much different:

```elixir
defmodule GenstageExample.Consumer do
  alias Experimental.GenStage
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [GenstageExample.ProducerConsumer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect {self(), event, state}
    end

    # As a consumer we never emit events
    {:noreply, [], state}
  end
end
```

As we covered in the previous section, our consumer does not emit events, so the second value in our tuple will be discarded.

## Putting It All Together

Now that we have our producer, producer-consumer, and consumer built, we're ready to wire everything together.

Let's start by opening `lib/genstage_example.ex` and adding our new processes to the supervisor tree:

```elixir
def start(_type, _args) do
  import Supervisor.Spec, warn: false

  children = [
    worker(GenstageExample.Producer, [0]),
    worker(GenstageExample.ProducerConsumer, []),
    worker(GenstageExample.Consumer, []),
  ]

  opts = [strategy: :one_for_one, name: GenstageExample.Supervisor]
  Supervisor.start_link(children, opts)
end
```

If things are all correct, we can run our project and we should see everything working:

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

We did it!  As we expected our application only omits even numbers and it does so _quickly_.

At this point we have a working pipeline.  There is a producer emitting numbers, a producer-consumer discarding odd numbers, and a consumer displaying all of this and continuing the flow.

## Multiple Producers or Consumers

We mentioned in the introduction that it was possible to have more than one producer or consumer. Let's take a look at just that.

If we examine the `IO.inspect/1` output from our example we see that every event is handled by a single PID. Let's make some adjustments for multiple workers by modifying `lib/genstage_example.ex`:

```elixir
children = [
  worker(GenstageExample.Producer, [0]),
  worker(GenstageExample.ProducerConsumer, []),
  worker(GenstageExample.Consumer, [], id: 1),
  worker(GenstageExample.Consumer, [], id: 2),
]
```

Now that we've configured two consumers, let's see what we get if we run our application now:

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

As you can see we now have multiple PIDs, simply by adding a line of code and giving our consumers IDs.

## Use Cases

Now that we've covered GenStage and built our first example application, what are some of the _real_ use cases for GenStage?

+ Data Transformation Pipeline — Producers don't have to be simple number generators. We could produce events from a database or even another source like Apache's Kafka.  With a combination of producer-consumers and consumers, we could process, sort, catalog, and store metrics as they become available.

+ Work Queue — Since events can be anything, we could produce works of unit to be completed by a series of consumers.

+ Event Processing — Similar to a data pipeline, we could recieve, process, sort, and take action on events emitted in real time from our sources.

These are just a _few_ of the possibilities for GenStage.
