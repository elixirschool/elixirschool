%{
  version: "1.2.1",
  title: "Testowanie kodu",
  excerpt: """
  Testowanie kodu jest ważną częścią procesu tworzenia oprogramowania.
  W tej lekcji przyjrzymy się zagadnieniu testowania kodu w Elixirze z wykorzystaniem ExUnit i poznamy kilka dobrych praktyk z tym związanych.
  """
}
---

## ExUnit

Elixir posiada wbudowaną bibliotekę ExUnit, która zawiera wszystko, czego potrzebujemy, by dokładnie przetestować nasz kod.
Zanim zagłębimy się w ten temat, musimy wspomnieć, że testy są w Elixirze tworzone w postaci skryptów w plikach `.exs`.
Przed uruchomieniem naszych testów musimy wystartować ExUnit za pomocą `ExUnit.start()`, co jest zazwyczaj wykonywane w skrypcie `test/test_helper.exs`.

Generując projekt w poprzedniej lekcji, Mix był na tyle miły, że utworzył plik `test/example_test.exs`, zawierający prosty test:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

Możemy uruchomić nasz test za pomocą polecenia `mix test`.
Jeśli to zrobimy, powinniśmy zobaczyć mniej więcej coś takiego:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

Dlaczego w zwróconym wyniku widzimy dwie kropki? Oprócz testu w `test/example_test.exs`, Mix utworzył również test dokumentacyjny — doctest — w pliku `lib/example.ex`.

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

Jeżeli kiedyś pisałeś już testy, to zapewne znasz pojęcie `assert`; niektóre biblioteki używają `should` lub `expect` zamiast `assert`.

Makra `assert` używamy do sprawdzania, czy wyrażenie jest prawdziwe.
Jeżeli nie jest, zostanie zwrócony błąd, a nasz test nie powiedzie się.
By to sprawdzić, spróbujmy zmienić nasz przykładowy test i ponownie uruchomić polecenie `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

Teraz powinniśmy zobaczyć zupełnie inny rezultat:

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

ExUnit dokładnie wskazuje miejsca, w których testy się nie powiodły, jakie były wartości oczekiwane, a jakie zostały faktycznie zwrócone.

### refute

`refute` jest tym dla `assert` czym `unless` dla `if`.
Możesz użyć `refute`, jeżeli chcesz sprawdzić wyrażenie, które zawsze jest nieprawdziwe.

### assert_raise

Czasami ważne jest sprawdzenie, czy został zwrócony wyjątek.
Możemy to zrobić za pomocą `assert_raise`.
W lekcji poświęconej Plugowi zobaczymy przykłady zastosowania `assert_raise`.

### assert_receive

Typowa Elixirowa aplikacja zawiera wiele aktorów/procesów, którzy komunikują się między sobą za pomocą wiadomości, dlatego też w testach będziemy chcieli sprawdzać, czy wiadomości są wysyłane.
Ponieważ ExUnit działa jako niezależny proces, może on być adresatem takich wiadomości, tak jak dowolny inny proces, a do testów możemy użyć w tym przypadku makra `assert_received`:

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

`assert_received` nie czeka na wiadomość, a wykorzystując `assert_receive` możemy określić maksymalny czas oczekiwania na wiadomość (timeout).

### capture_io i capture_log

Przechwytywanie informacji produkowanych przez aplikację jest możliwe za pomocą `ExUnit.CaptureIO` bez konieczności ingerowania w jej kod.
Wystarczy przekazać jako argument funkcję, która wypisuje informacje na standardowe wyjście:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` jest odpowiednikiem przechwytywania informacji ze standardowego wyjścia przez `Logger`.

## Konfiguracja testów

W pewnych sytuacjach musimy przygotować środowisko przed uruchomieniem testów.
W tym celu możemy użyć makr `setup` i `setup_all`.
Makro `setup` będzie uruchamiane przed każdym testem, a `setup_all` zostanie uruchomione jednorazowo przed wszystkimi testami w module.
Makra te powinny zwracać krotkę `{:ok, state}`, gdzie `state` będzie dostępny dla naszych testów.

Dla przykładu zmieńmy nasz kod tak, by korzystał z `setup_all`:

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

## Mockowanie

Bądźmy ostrożni w myśleniu o mockowaniu. Kiedy tworzymy mockupy dla poszczególnych interakcji poprzez tworzenie okrojonych wersji funkcji (ang. _stubs_), ustanawiamy niebezpieczny wzorzec. Łączymy przebieg naszych testów z zachowaniem konkretnej zależności, takiej jak klient API. Unikamy definiowania współdzielonych zachowań między tymi funkcjami. Czynimy w ten sposób trudniejszym powtarzanie naszych testów.

Zamiast tego społeczność Elixira zachęca, by zmienić myślenie na ten temat w testach: myśleć o mockupach (rzeczowniku), a nie o mockowaniu (czasowniku).

By poznać szerszą dyskusję w tej sprawie, przeczytaj ten [znakomity artykuł](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/).

Mówiąc w dużym skrócie, zamiast mockowania zależności dla testów (mockowania jako *czasownika*), istotnie lepszym podejściem jest jawne definiowanie interfejsów (zachowań) dla kodu znajdującego się poza naszą aplikacją i użycie w testach mockupów (jako *rzeczownika*).

By lepiej zrozumieć wzorzec „mocków jako rzeczowników”, możesz:

* Zdefiniować zachowanie, które jest zaimplementowane zarówno przez moduł, dla którego chcesz zdefiniować mockup _oraz_ przez moduł, który będzie pełnił rolę mockupu.
* Zdefiniować moduł-mockup.
* Skonfigurować swoją aplikację tak, by używała mockupu w danym teście — na przykład poprzez przekazanie modułu mockupu jako argumentu w wywołaniu funkcji — lub w całym środowisku testowym, poprzez odpowiednią konfigurację tego środowiska.

Jeśli chcesz nieco bardziej zagłębić się w temat mockupów w Elixirze i poznać bibliotekę Mox, która pozwala na definiowanie równoległych mockupów, zajrzyj do lekcji na ten temat w [tym miejscu](/en/lessons/testing/mox).
