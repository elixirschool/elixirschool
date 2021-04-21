%{
  version: "1.1.1",
  title: "OTP Supervisors",
  excerpt: """
  Supervisors sind besondere Prozesse mit einem Zweck: andere Prozesse zu überwachen. Diese Supervisors erlauben uns fehlertolerante Anwendungen zu erstellen, indem sie Kindprozesse automatisch neu starten, falls diese versagen.
  """
}
---

## Konfiguration

Die Magie von Supervisors liegt in der `Supervisor.start_link/2`-Funktion. Zusätzlich zum Starten unserer Supervisors und Kinder erlaubt sie uns die Strategie zu bestimmen, mit der unser Supervisor Kindprozesse verwaltet.

Wir benutzen SimpleQueue aus der Lektion [OTP Concurrency](../../advanced/otp-concurrency) und legen los:

Erstelle ein neues Projekt mit dem Befehl `mix new simple_queue --sup` um ein Projekt mit einem Supervisor-Baum zu erzeugen. Der Code für das Modul SimpleQueue sollte in `lib/simple_queue.ex` liegen und der Supervisor Code, den wir hinzufügen werden, soll in `lib/simple_queue/application.ex` liegen.

Kinder werden werden in einer Liste definiert, entweder eine Liste von Modulnamen:

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], name: SimpleQueue)
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```
oder eine Liste von Tupeln, falls du Konfigurations-Optionen mitgeben willst:

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleQueue, [1, 2, 3]}
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```
Wenn wir `iex -S mix` ausführen, sehen wir, dass unsere SimpleQueue automatisch gestartet wird:

```elixir
iex> SimpleQueue.queue
[1, 2, 3]
```

Falls unser SimpleQueue Prozess abstürzt oder sonstwie terminiert, würde unser Supervisor ihn automatisch neu starten, als ob nichts gewesen wäre.

### Strategien

Es gibt zurzeit drei verschiedene Strategien zum Neustart, welche Supervisors benutzen können:

+ `:one_for_one` - Startet nur den abgestürzten Kindprozess neu.

+ `:one_for_all` - Startet alle Kindprozesse neu im Falle eines Fehlers.

+ `:rest_for_one` - Startet den abgestürzten Prozess und alle nach ihm gestarteten Prozesse neu.

## Kind-Spezfikation

Nachdem ein Supervisor gestartet ist, muss er wissen, wie er seine Kinder starten/stoppen/neustarten soll.
Jedes Kind-Modul sollte eine `child_spec/1` Funktion haben, die dieses Verhalten definiert.
Die Macros `use GenServer`, `use Supervisor`, und `use Agent` definieren diese Methode automatisch für uns (`SimpleQueue` hat `use Genserver`, also brauchen wir dieses Modul nicht anzupassen), aber wenn du sie selbst definieren musst, sollte `child_spec/1` eine Map von Optionen zurückgeben:

```elixir
def child_spec(opts) do
  %{
    id: SimpleQueue,
    start: {__MODULE__, :start_link, [opts]},
    shutdown: 5_000,
    restart: :permanent,
    type: :worker
  }
end
```

+ `id` - Notwendiger Key.
Vom Supervisor benutzt um die die Kind-Spezifikation zu identifizieren

+ `start` - Notwendiger Key.
Das Modul/die Funktion/Argumente, die beim Start vom Supervisor aufgerufen werden sollen

+ `shutdown` - Optionaler Key.
Definiert das Verhalten des Kindes während des Beendens
Die Optionen sind:

  + `:brutal_kill` - Kind wird sofort gestoppt

  + ein positiver Integer - Zeit in Millisekunden, die der Supervisor warten wird, bevor er den Kind-Prozess killt.
  Wenn der Prozess vom Typ `:worker` ist, ist dieser Wert standardmäßig 5000.

  + `:infinity` - Der Supervisor wird unednlich lange warten, bevor er den Prozess killt.
Standardwert für den Prozesstyp `:supervisor`.
Nicht empfohlen für den Typ `:worker`.

+ `restart` - Optionaler Key.
Es gibt mehrere Herangehensweisen, um abstürzende Kindprozesse zu verwalten:

  + `:permanent` - Kind wird immer neugestartet.
Standard für alle Prozesse

  + `:temporary` - Kindprozess wird niemals neugestartet.

  + `:transient` - Kindprozess wird nur neugestartet, falls er abnorm terminiert.

+ `type` - Optionaler Key.
Prozesse können entweder `:worker` oder `:supervisor` sein.
Standardwert ist `:worker`.

## DynamicSupervisor

Supervisors starten normalerweise mit einer Liste von Kindern, die sie starten, wenn die App startet.
Manchmal jedoch sind die beausichtigten Kinder beim App-Start nicht bekannt (zum Beispiel könnten wir eine Web-App haben, die einen neuen Prozess startet, wenn sich ein Nutzer mit unserer Webseite verbindet.)
Für diese Fälle brauchen wir eine Supervisor, der Kinder bei Bedarf starten kann.
In diesem Fall benutzen wir den DynamicSupervisor.

Da wir keine Kinder spezifizieren, müssen wir nur die Laufzeit-Optionen für den Supervisor bestimmen.
Der DynamicSupervisor unterstüzt nur die Supervison-Strategie `:one_for_one`:

```elixir
options = [
  name: SimpleQueue.Supervisor,
  strategy: :one_for_one
]

DynamicSupervisor.start_link(options)
```
Um eine neue SimpleQueue dynamisch zu starten, nutzen wir dann die Funktion `start_child/2`, welche einen Supervisor und eine Kind-Spezifikation als Argumente nimmt (`SimpleQueue` nutzt `use GenServer`, die Kind-Spezifikation ist daher schon definiert):

```elixir
{:ok, pid} = DynamicSupervisor.start_child(SimpleQueue.Supervisor, SimpleQueue)
```

## Task Supervisor

Tasks haben ihren eigenen spezialisierten Supervisor, `Task.Supervisor`. Dieser Supervisor wurde für dynamisch erstellte Tasks entworfen und benutzt `DynamicSupervisor` unter der Haube.

### Setup

`Task.Supervisor` zu benutzen ist nicht anders wie andere Supervisors:

```elixir
children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Der Hauptunterschied zwischen `Supervisor` und `Task.Supervisor` ist, dass die standardmäßige Strategie zum Neustart `:temporary` ist (Tasks würden nie neu gestartet werden).

### Supervised Tasks

Wenn der Supervisor gestartet ist, können wir die Funktion `start_child/2` benutzen, um einen supervised Task zu erstellen:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

Falls unser Task vorzeitig abstürzt, wird er für uns neu gestartet. Das kann besonders sinnvoll sein, wenn wir mit eingehenden Verbindungen arbeiten oder Hintergrundarbeit verrichten.
