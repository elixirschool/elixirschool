---
version: 0.9.1
title: OTP Supervisors
---

Supervisors sind besondere Prozesse mit einem Zweck: Andere Prozesse zu überwachen. Diese supervisors erlauben uns fehlertolerante Anwendungen zu erstellen, indem sie Kindprozesse automatisch neu starten, falls diese abbrechen.

{% include toc.html %}

## Konfiguration

Die Magie von supervisors liegt in der `Supervisor.start_link/2`-Funktion. Zusätzlich zum Starten unserer supervisor und Kinder erlaubt sie uns die Strategie zu bestimmen, mit der unser supervisor Kindprozesse verwaltet.

Kinder werden durch eine Liste und der `worker/3`-Funktion bestimmt, die wir von `Supervisor.Spec` importieren.  Die `worker/3`-Funktion nimmt ein Modul, Argumente und eine Liste an Optionen. Unter der Haube ruft `worker/3` während der Initialisierung `start_link/3` mit unseren Argumenten auf.

Die SimpleQueue aus der [OTP Concurrency](../../advanced/otp-concurrency)-Lektion benutzend lass uns loslegen:

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], name: SimpleQueue)
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Falls unser Prozess abstürzt oder sonstwie terminiert würde unser supervisor ihn automatisch neu starten, als ob nichts gewesen wäre.

### Strategien

Es gibt zurzeit 4 verschiedene Strategien zum Neustart, welche supervisors benutzen können:

+ `:one_for_one` - Startet nur den abgestürzten Kindprozess neu.

+ `:one_for_all` - Startet alle Kindprozesse neu im Falle eines Fehlers.

+ `:rest_for_one` - Startet alle abgestürzten Prozesse und alle danach gestarteten Prozesse neu.

+ `:simple_one_for_one` - Am besten geeignet für dynamisch angehängte Kindprozesse. Die supervisor-Spezifikation erlaubt nur ein Kind, aber dieses Kind kann öfters gestartet werden. Diese Strategie ist dafür ausgelegt, wenn du dynamisch gestartete und gestoppte Kindprozesse verwalten möchtest.

### Werte für Neustart

Es gibt mehrere Herangehensweisen, um abstürzende Kindprozesse zu verwalten:

+ `:permanent` - Kind wird immer neugestartet.

+ `:temporary` - Kindprozess wird niemals neugestartet.

+ `:transient` - Kindprozess wird nur neugestartet, falls er abnorm terminiert.

Es ist keine zwingende Option, der Standardwert ist `:permanent`.

### Verschachtelung

Neben worker processes können wir ebenso andere supervisors überwachen, um so einen supervisor-Baum zu erstellen. Der einzige Unterschied für uns ist der Austausch von `worker/3` mit `supervisor/3`:

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Task Supervisor

Tasks haben ihren eigenen spezialisierten supervisor, `Task.Supervisor`. Entworfen für dynamisch erstellte Tasks benutzt der supervisor `:simple_one_for_one` unter der Haube.

### Setup

`Task.Supervisor` zu benutzen ist nicht anders wie andere supervisors:

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor, restart: :transient]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Der Hauptunterschied zwischen `Supervisor` und `Task.Supervisor` ist, dass die standardmäßige Strategie zum Neustart `:temporary` ist (Tasks würden nie neu gestartet werden).

### Supervised Tasks

Wenn der supervisor gestartet ist, können wir die Funktion `start_child/2` benutzen, um einen supervised Task zu erstellen:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

Falls unser Task vorzeitig abstürzt wird er für uns neu gestartet. Das kann besonders sinnvoll sein, wenn wir mit eingehenden Verbindungen arbeiten oder Hintergrundarbeit verrichten.
