%{
  version: "0.9.1",
  title: "Embedded Elixir (EEx)",
  excerpt: """
  Tak jak w Ruby mamy ERB, a w Javie istnieje JSP, tak i Elixir ma EEx - Embedded Elixir. Dzięki EEx możemy osadzać kod Elixira w ciągach znaków.
  """
}
---

## API

API EEx pozwala na pracę zarówno z ciągami znaków jak i plikami. Jest ono podzielone na trzy główne komponenty: prostą ewaluację, definiowanie funkcji i kompilację do AST Elixira.

### Ewaluacja

Używając funkcji `eval_string/3` i `eval_file/2` możemy ewaluować ciągi znaków jak i pliki. Jest to najprostsze podejście, ale też najwolniejsze ponieważ kod jest tylko interpretowany, a nie kompilowany.

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### Definiowanie funkcji

Najszybszą, i preferowaną, metodą użycia EEx jest osadzenie szablonu w module dzięki czemu można go skompilować. By to zrobić potrzebujemy w czasie kompilacji modułu pliku z szablonem oraz makr `function_from_string/5` i `function_from_file/5`.

Przenieśmy nasze powitanie do osobnego pliku, szablonu, i zdefiniujmy dla niego funkcję w module: 

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

### Kompilacja

W końcu, EEx pozwala nam na bezpośrednie stworzenie AST Elixira z ciągu znaków lub z pliku za pomocą funkcji, odpowiednio `compile_string/2` i `compile_file/2`.  Funkcje  te są przede wszystkim używane przez wyżej opisane API, ale są też dostępne jeżeli chcemy stworzyć własną obsługę wbudowanego Elixira.

## Znaczniki

Domyślnie EEx wspiera cztery znaczniki:

```elixir
<% Wyrażenie Elixir - wywołanie zwracające wartość %>
<%= Wyrażenie Elixir - zamieniane na rezultat wyrażenia %>
<%% Wyrażenie EEx - wartość po ewaluowacji wyrażenia %>
<%# Komentarz - usuwany ze źródła %>
```

Wszystkie wyrażenia, które coś zwracają __muszą__ używać znaku równości (`=`).  Ważną rzeczą jest to, że w przeciwieństwie do innych języków szablonów EEx nie traktuje wyrażeń w rodzaju `if` w specjalny sposób.  Bez znaku `=` nic nie zostanie wyświetlone:

```elixir
<%= if true do %>
  jeżeli prawda
<% else %>
  jeżeli fałsz
<% end %>
```

## Silnik

Domyślnie Elixir używa silnika `EEx.SmartEngine`, który zawiera wsparcie dla przypisywania zmiennych (na przykład `@name`):

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

Przypisania obecne w `EEx.SmartEngine` są bardzo przydatne ponieważ pozwalają wprowadzać zmiany bez konieczności rekompilacji szablonu.

Zainteresowany stworzeniem własnego silnika? Sprawdź jak działa [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html) by zobaczyć co jest wymagane. 
