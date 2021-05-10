%{
  version: "0.9.1",
  title: "Nadzorcy OTP",
  excerpt: """
  Nadzorcy to wyspecjalizowane procesy mające tylko jeden cel: monitorowanie innych procesów. Pozwalają oni na tworzenie aplikacji odpornych na błędy, które będą samodzielnie restartować procesy, które zawiodły.
  """
}
---

## Konfiguracja

Cała „magia” nadzorców dzieje się w funkcji `Supervisor.start_link/2`.  Poza uruchomieniem nadzorcy i procesów potomnych pozwala ona na określenie strategii użytej do zarządzania procesami potomnymi.

Procesy potomne są przekazywane jako lista do funkcji `worker/3`, zaimportowanej z `Supervisor.Spec`. Funkcja `worker/3` jako parametry przyjmuje moduł, argumenty wywołania oraz opcje. W praktyce funkcja `worker/3` wywołuje `start_link/3` przekazując do niej podane przez nasz argumenty.

Zmodyfikujmy przykład `SimpleQueue` z lekcji [Współbieżność OTP](../../advanced/otp-concurrency):

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], name: SimpleQueue)
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Jeżeli nadzorowany proces ulegnie awarii albo się zakończy, nadzorca automatycznie go zrestartuje, tak jak by nic się nie stało.

### Strategie

Do zarządzania procesami potomnymi nadzorca może wykorzystać jedną z czterech strategii:

+ `:one_for_one` - Ponownie uruchamia tylko uszkodzony proces potomny.
+ `:one_for_all` - Ponownie uruchamia wszystkie procesy potomne.
+ `:rest_for_one` - Uruchamia ponownie uszkodzony proces i wszystkie procesy, które zostały uruchomione po nim.
+ `:simple_one_for_one` - Najlepszy przy dynamicznym tworzeniu procesów. Specyfikacja nadzorcy pozwala na zarządzanie tylko jednym procesem potomnym, ale proces ten może być uruchomiony wiele razy. Strategia ta może być stosowana, gdy chcemy dynamicznie uruchamiać i zatrzymywać proces potomny.  

### Restart procesu potomnego

Restart procesu potomnego można obsłużyć na kilka sposobów:

+ `:permanent` – proces potomny jest zawsze restartowany,
+ `:temporary` – proces potomny nigdy nie jest restartowany,
+ `:transient` – proces potomny zostanie zrestartowany, tylko jeżeli zakończył się w wyniku awarii.
 
Konfiguracja ta jest opcjonalna, a wartością domyślną jest `:permanent`. 

### Zagnieżdżanie

Poza procesami potomnymi możemy też tworzyć nadzorców, którzy będą zarządzać innymi nadzorcami. W ten sposób tworzymy drzewo nadzorców. Jedyna różnica polega na użyciu funkcji `supervisor/3` zamiast `worker/3`:

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Nadzorcy zadań

Zadania mają swojego wyspecjalizowanego nadzorcę `Task.Supervisor`. Zaprojektowany jest on z myślą o dynamicznym tworzeniu zadań, oznacza to, że używa strategii `:simple_one_for_one`.

### Przygotowanie

Użycie `Task.Supervisor` nie różni się od użycia innych nadzorców:

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

### Zadania nadzorowane

Mając uruchomionego nadzorcę możemy użyć funkcji `start_child/2`, by uruchamiać nadzorowane zadania:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

Jeżeli zadanie ulegnie awarii, to zostanie automatycznie zrestartowane. Jest to szczególnie przydatne, gdy pracujemy z zadaniami do obsługi połączeń przychodzących lub pracującymi w tle.