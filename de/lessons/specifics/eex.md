---
version: 0.9.1
title: Embedded Elixir (EEx)
---

So wie Ruby ERB und Java JSPs hat, hat Elixir EEx. EEx steht für "Embedded Elixir". Mit EEx können wir Elixir-Ausdrücke innerhalb von Strings einbetten und auswerten.

{% include toc.html %}

## API

Die EEx API erlaubt uns mit Strings und Dateien zu arbeiten. Die API ist in drei Hauptkomponenten unterteilt: Einfache Auswertung, Funktionsdefinitionen und Kompilierung von ASTs.

### Auswertung

Mit `eval_string/3` und `eval_file/2` können wir Strings oder Dateiinhalte direkt auswerten. Dies ist die einfachste, aber auch die langsamste API, da Code direkt ausgewertet und nicht zuerst kompiliert wird.

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### Funktionsdefinitionen

Die schnellste (und bevorzugte) Möglichkeit EEx zu nutzen besteht darin, unser Template in ein Modul einzubetten, damit es kompiliert werden kann. Hierfür benötigen wir zur Kompilierzeit unser Template, sowie die Makros `function_from_string/5` und `function_from_file/5`.

Wir verschieben unser Beispiel in eine eigene Datei und erstellen eine Funktion für das Template:

```elixir
# greeting.eex
Hi, <%= name %>

defmodule Example do
  require EEx
  EEx.function_from_file(:def, :greeting, "greeting.eex", [:name])
end

iex> Example.greeting("Sean")
"Hi, Sean"
```

### Kompilierung

Darüber hinaus stellt uns EEx die Möglichkeit zur Verfügung, mit `compile_string/2` oder `compile_file/2` Elixir ASTs aus Strings bzw. Dateien zu generieren. Diese API wird intern von den vorher genannten APIs genutzt, kann aber auch direkt genutzt werden, falls wir eine eigene Lösung zum Umgang mit EEx schreiben möchten.


## Tags

Standardmäßig gibt es vier von EEx unterstützte Tags:

```elixir
<% Elixir Ausdruck - wird inline ausgewertet %>
<%= Elixir Ausdruck - das Ergebnis des Ausdrucks wird im String eingebettet %>
<%% EEx Zitat - der Code wird nicht ausgewertet, sondern zitiert im String wiedergegeben %>
<%# Kommentar- wird einfach verworfen %>
```

Alle Ausdrücke die ausgewertet werden sollen, __müssen__ das Gleichheitszeichen (`=`) nutzen. Zu beachten ist, dass Elixir z.B. auch Konstrukte wie `if` nicht anders behandelt als andere Ausdrücke. Ohne `=` keine Ausgabe: 

```elixir
<%= if true do %>
  Eine Wahre Aussage
<% else %>
  Eine Unwahre Aussage
<% end %>
```

## Engine

In Elixir ist die `EEx.SmartEngine` voreingestellt, diese beinhaltet Unterstützung für Zuweisungen (wie z.B. `@name`):

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```
Die `EEx.SmartEngine`-Zuweisungen sind nützlich da sie geändert werden können ohne erneute Kompilierung des Templates zu erfordern.

Willst du deine eigene Engine schreiben? Schau dir das Behaviour [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html) an, um zu sehen was du dafür benötigst.
