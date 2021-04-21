---
version: 0.9.1
title: Testen
---

Testen ist ein wichtiger Teil der Softwareentwicklung. In dieser Lektion werden wir uns anschauen, wie man Elixir Code mit ExUnit testet und einige best practices davon kennen lernen.

{% include toc.html %}

## ExUnit

Elixirs eingebautes Testframework ist ExUnit und es beinhaltet alles, was wir brauchen, um unseren Code durch und durch zu testen. Bevor wir fortfahren, ist es wichtig festzuhalten, dass Tests als Elixirscripts implementiert werden, also müssen wir die `.exs`-Dateiendung verwenden. Bevor wir Tests laufen lassen können, müssen wir ExUnit startet mit den Aufruf `ExUnit.start()`, was meist in `test/test_helper.exs` geschieht.

Wenn wir unser Beispielprojekt in der letzten Lektion erstellt haben, hat mix bereits einfache Tests für uns generiert, die wir in `test/example_test.exs` finden:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

Wir können die Tests unserer Projekts mit `mix test` starten. Falls wir das jetzt tun, sehen wir eine Ausgabe wie hier:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

Falls du schon mal Tests geschrieben hast, bist du vertraut mit `assert`; in manchen Frameworks übernehmen `should` oder `expect` die Rolle von `assert`.

Wir benutzen das `assert`-Makro, um zu überprüfen, ob ein Ausdruck wahr ist. Im Falle, dass dem nicht so ist, wird ein Fehler geworfen und unser Test schlägt fehl. Um einen Fehler zu testen, lass uns unser Beispiel verändern und dann `mix test` aufrufen:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

Dann sollten wir eine Ausgabe ähnlich wie hier sehen:

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

ExUnit sagt uns exakt, wo unsere fehlgeschlagene Annahme ist, was der erwartete Wert ist und was der tatsächliche Wert war.

### refute

`refute` ist zu `assert` das, was `unless` zu `if` ist. Benutze `refute` wenn du sicher stellen willst, dass ein Ausdruck immer falsch ist.

### assert_raise

Manchmal kann es notwendig sein sicherzustellen, dass ein Fehler geworfen wurde. Wir können das mit `assert_raise` machen.  Wir werden ein Beispiel von `assert_raise` in der nächsten Lektion zu Plug sehen.

### assert_receive

In Elixir bestehen Anwendungen aus Actors/Prozessen, die sich gegenseitig Nachrichten schicken können. Daher möchtest du oft testen, ob eine Nachricht versendet wurde. Da ExUnit in seinem eigenen Prozess läuft, kann es wie jeder andere Prozess Nachrichten empfangen und du kannst mit dem `assert_received`-Makro asserten:

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

`assert_received` wartet nicht auf Nachrichten, mit `assert_receive` kannst du einen Timeout festlegen.

### capture_io und capture_log

Die Ausgabe einer Anwendung aufzuzeichen ist mit `ExUnit.CaptureIO` möglich, ohne die Originalanwendung umzuschreiben. Gib ihr einfach nur die Funktion, die die Ausgabe generiert:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` ist das Äquivalent zu `Logger`, um Ausgaben aufzuzeichen.

## Test Setup

Manchmal kann es notwendig sein, ein paar Setups auszuführen, bevor Tests laufen können. Um das zu bewerkstelligen können wir die `setup`- und `setup_all`-Makros nutzen. `setup` wird vor jedem Test aufgerufen und `setup_all` einmal vor der Testsuite. Es wird davon ausgegangen, dass sie ein Tupel mit `{:ok, state}` zurückgeben, der Zustand wird für unsere Tests verfügbar sein.

Deutlichkeitshalber werden wir unseren Code so ändern, dass er `setup_all` nutzt:

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

Die einfache Antwort für mocking in Elixir ist: Tu es nicht. Du magst vielleicht instinktiv mocks nehmen wollen, aber sie werden aus gutem Grund von der Elixir-Community nicht benutzt.

Für eine längere Diskussion ist hier ein [exzellenter Artikel](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/). Die Zusammenfassung ist, dass statt dem mocken (mock als *Verb*) von Testen von Abhängigkeiten es mehr Vorteile hat, Schnittstellen für Code außerhalb deines Codes explizit zu definieren (Verhaltensweisen) und Mocks (als *Nomen*) in deinem Clientcode zum Testen dazu zu benutzen.

Um die Implementierung in deinem Anwendungscode zu wechseln ist der präferierte Weg ein Modul als Argument zu übergeben und einen Defaultwert zu verwenden. Falls das nicht funktioniert, benutze den eingebauten Konfigurationsmechanismus. Um dies Mock-Implementierungen zu erstellen brauchst du keine spezielle Mocking-Bibliothek, sondern einfach nur behaviours und callbacks.
