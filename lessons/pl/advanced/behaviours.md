---
version: 1.0.1
title: Zachowania
---

W poprzedniej lekcji poznaliśmy specyfikacje i typy. W tej dowiemy się jak wymusić na module ich implementację. W Elixirze funkcjonalność ta nosi nazwę zachowań.

{% include toc.html %}

## Zastosowania

Czasami chcemy, by moduły współdzieliły publiczne API, rozwiązaniem tego problemu w Elixirze są zachowania. Zachowania pełną dwie role:

+ Definiują zestaw funkcji, które muszą być zaimplementowane w module,
+ Sprawdzają, czy rzeczywiście zaimplementowano wymagane funkcje. 

Elixir zawiera pewną ilość zachowań jak na przykład GenServer, ale w tej lekcji skupimy się na tworzeniu własnych.

## Definiowanie zachowania

W celu lepszego zrozumienia zachowań definiujmy je w module `Worker`. Wszystkie implementacje będą musiały zawierać dwie funkcje `init/1` i `perform/2`.

Aby to osiągnąć, użyjemy dyrektywy `@callback`, która ma składnię zbliżoną do `@spec` i definiuje __wymagane__ metody; w przypadku makr należy użyć `@macrocallback`. Zdefiniujmy metody `init/1` i `perform/2`: 

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

Nasze zachowanie określa `init/1` jako funkcję przyjmującą jako parametr dowolną wartość i zwracającą krotkę `{:ok, state}` albo `{:error, reason}`, jest to standardowa inicjacja modułu. Nasza funkcja `perform/2` będzie otrzymywać jako parametry pewne argumenty wraz ze stanem, który zainicjował nasz moduł. Spodziewamy się, że funkcja ta zwróci `{:ok, result, state}` albo `{:error, reason, state}`, podobnie jak GenServer. 

## Użycie zachowań

Teraz gdy zdefiniowaliśmy nasze zachowanie, możemy użyć go przy tworzeniu różnych modułów, które będą współdzielić publiczne API. Dodanie zachowania do modułu jest proste i polega na wykorzystaniu dyrektywy `@behaviour`.

Użyjmy naszego zachowania do stworzenia modułu, obsługującego zadanie pobrania pliku i zapisania do na dysku:

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

A co z zadaniem kompresji tablicy plików? To też jest możliwe!

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Wykonywane zadania są różne, ale publiczne API nie, tym samym każdy moduł wykorzystujący ten kod może, to robić wiedząc jakich odpowiedzi można się spodziewać. To daje nam możliwość stworzenia wielu różnych zadań, które mają spójne API.

Jeżeli dodamy do naszego modułu zachowanie, ale pominiemy implementację wymaganych funkcji, to w trakcie kompilacji otrzymamy ostrzeżenie. Usuńmy metodę `init/1` z modułu `Example.Compressor` i zobaczmy, co się stanie:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Teraz gdy uruchomimy kompilację to powinniśmy otrzymać ostrzeżenie:

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

I to wszystko! Jesteśmy gotowi by tworzyć zachowania i współdzielić je pomiędzy modułami.