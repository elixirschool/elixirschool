---
version: 1.1.1
title: Testowanie kodu
---

Testowanie kodu jest bardzo ważną częścią procesu produkcji oprogramowania. W tej lekcji przyjrzymy się zagadnieniu testowania kodu w Elixirze z wykorzystaniem ExUnit. Poznamy też kilka dobrych praktyk z tym związanych.  

{% include toc.html %}

## ExUnit

Elixir posiada wbudowaną bibliotekę ExUnit, która zawiera wszystko, co potrzebne do pisania testów. Zanim zagłębimy się w ten temat, musimy wspomnieć, że testy są w Elixirze tworzone w postaci skryptów w plikach `.exs`. Zanim uruchomimy nasze testy, musimy wystartować ExUnita za pomocą `ExUnit.start()`, jest to zazwyczaj robione w skrypcie `test/test_helper.exs`.

Generując projekt w poprzedniej lekcji, mix był na tyle miły, że utworzył plik `test/example_test.exs` zawierający prosty test:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

Możemy uruchomić nasz test za pomocą `mix test`.  Powinniśmy otrzymać komunikat podobny do poniższego:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

Dlaczego w wyniku otrzymujemy, że dwa testy zostały uruchomione? Zajrzyjmy do pliku `lib/example.ex`. Mix utworzył tam dla nas kolejny test, doctest.

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

Jeżeli kiedyś pisałeś już testy to zapewne znasz pojęcie `assert`; niektóre biblioteki używają `should` lub `expect` zamiennie z `assert`.

Makro `assert` sprawdza, czy wyrażenie jest prawdziwe. Jeżeli nie jest, to zwróci błąd, a nasz test nie powiedzie się. By to sprawdzić, zmieńmy nasz przykładowy test i uruchommy polecenie `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

W efekcie otrzymamy zupełnie inny komunikat:

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

`refute` jest tym dla `assert` czym `unless` dla `if`.  Użyj `refute` jeżeli chcesz sprawdzić wyrażenie, które zawsze jest nieprawdziwe.  

### assert_raise

Czasami ważne jest sprawdzenie, czy został zwrócony wyjątek. Możemy to zrobić za pomocą `assert_raise`.  W kolejnej lekcji poświęconej Plugowi zobaczymy przykłady zastosowania `assert_raise`.

### assert_receive

Typowa aplikacja zawiera wiele procesów/aktorów, którzy komunikują się między sobą za pomocą wiadomości. Testy mają nam odpowiedzieć na pytanie, czy wiadomość została wysłana. Jako że ExUnit działa jako niezależny proces, to może być adresatem wiadomości. By sprawdzić, czy testowa wiadomość dodarła, możemy wykorzystać makro `assert_received`: 

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

Przechwytywanie informacji produkowanych przez aplikację jest możliwe za pomocą `ExUnit.CaptureIO` bez konieczności ingerowania w jej kod. Wystarczy jako argument przekazać funkcję, która wypisuje informacje na standardowe wyjście:  

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

Jeżeli w naszej aplikacji wykorzystujemy `Logger`, to możemy użyć `ExUnit.CaptureLog` do przechwytywania informacji zapisywanych do dziennika.

## Konfiguracja testów

W pewnych sytuacjach musimy przygotować środowisko przed uruchomieniem testów. W tym celu możemy użyć makr `setup` i `setup_all`. Makro `setup` będzie uruchomione przed każdym testem, a `setup_all` zostanie uruchomione jednorazowo przed wszystkimi testami. Powinny one zwrócić `{:ok, state}`, gdzie `state` będzie dostępny dla naszych testów.

Przykładowo zmieńmy nasz test tak, by korzystał z `setup_all`:

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

W Elixirze mockom mówimy stanowcze nie. Możesz mieć chęć skorzystania z mocków, ale są one niechętnie widziane w społeczności Elixira i to nie bez powodu. 

Temat ten w wyczerpujący sposób został omówiony w [artykule](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/) autorstwa José Valima. Istotą problemu jest użycie mocków, które wymusza jawne zdefiniowanie interfejsów pomiędzy naszym kodem i kodem klienta. Mocki są w takim przypadku specyficznymi, ponieważ służą tylko do testowania, implementacjami kodu klienta. 

Rozwiązaniem jest taka implementacja po naszej stronie, by przekazywać moduł jako argument i używać wartości domyślnych. Jeżeli takie rozwiązanie nie jest wystarczające, to możemy użyć wbudowanego mechanizmu konfiguracji, by utworzyć odpowiednie mocki. Jednocześnie nie potrzebujemy żadnej dodatkowej biblioteki do tworzenia mocków dla naszych zachowań i wywołań zwrotnych.
