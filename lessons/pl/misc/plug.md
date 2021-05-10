%{
  version: "0.10.0",
  title: "Plug",
  excerpt: """
  Jeżeli masz doświadczenie z Ruby to Plug może być czymś w rodzaju Racka z domieszką Sinatry. Definiuje on specyfikację dla aplikacji webowych oraz adapterów dla serwerów. Choć nie jest częścią biblioteki standardowej, to Plug jest oficjalnym projektem zespołu odpowiedzialnego za Elixira.
  """
}
---

## Instalacja

Instalacja z użyciem mix jest bardzo prosta. By zainstalować Plug musimy zmodyfikować plik `mix.exs`.  Pierwszą rzeczą do zrobienia jest dodanie Pluga oraz serwera web (wybraliśmy Cowboy) do pliku z zależnościami:

```elixir
defp deps do
  [{:cowboy, "~> 1.1.2"}, {:plug, "~> 1.3.4"}]
end
```

Następnie wystarczy tylko dodać serwer web oraz Plug do naszej aplikacji OTP:

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## Specyfikacja

By tworzyć własne plugi musimy zapoznać się ze specyfikacją. Na całe szczęście istotne są tylko dwie funkcje: `init/1` i `call/2`.

Funkcja `init/1` służy do inicjalizacji opcji pluga, które zostaną przekazane jako drugi argument funkcji `call/2`.  Dodatkowo w pierwszym argumencie funkcja `call/2` otrzymuje `%Plug.Conn` oraz musi zwrócić połączenie.

Oto prosty Plug zwracający "Hello World!":

```elixir
defmodule HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!")
  end
end
```

## Tworzenie Pluga

W tym przykładzie stworzymy plug, który będzie sprawdzał czy żądanie zawiera wymagane parametry. Implementując własną walidację w plugu będziemy mieć pewność, że tylko poprawne żądania dotrą do aplikacji. Nasz plug będzie zainicjowany z dwiema opcjami: `:paths` i `:fields`. Będą one reprezentować ścieżkę żądania oraz pola wymagane dla tej ścieżki.

_Uwaga_: Plugi są wykonywane dla wszystkich żądań dlatego też będziemy musieli samodzielnie obsłużyć filtrowanie i wywoływać naszą logikę tylko w niektórych przypadkach. By zignorować żądanie wystarczy zwrócić połączenie.

Przyjrzyjmy się zatem naszemu gotowemu plugowi i zobaczmy jak on działa.  Stworzyliśmy go w pliku `lib/example/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  import Plug.Conn

  defmodule IncompleteRequestError do
    @moduledoc """
    Error raised when a required field is missing.
    """

    defexception message: "", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.body_params, opts[:fields])
    conn
  end

  defp verify_request!(body_params, fields) do
    verified =
      body_params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

Na początku definiujemy nowy wyjątek `IncompleteRequestError` który ma opcję `:plug_status`.  Opcja ta jest używana przez Plug by ustawić odpowiedni kod statusu w odpowiedzi HTTP gdy wystąpi wyjątek.

Drugim elementem naszego pluga jest metoda `call/2`. To w niej decydujemy czy wykonana zostanie weryfikacja czy też pominiemy tę logikę. Tylko w przypadku gdy ścieżka żądania znajduje się w opcji `:paths` wywołamy `verify_request!/2`.

Ostatnim elementem jest prywatna funkcja `verify_request!/2`, która sprawdza czy żądanie zawiera wszystkie pola wymienione w `:fields`. Jeżeli jakieś pole nie istnieje wyrzuca wyjątek `IncompleteRequestError`.

## Użycie Plug.Router

Teraz gdy mamy nasz plug `VerifyRequest`, możemy przejść do routera. Jak zaraz zobaczymy nie potrzebujemy dodatkowego narzędzia jak Sinatra, ponieważ w Elixirze mamy dostępny Plug.

Na początku stwórzmy plik `lib/plug/router.ex` i skopiujmy do niego następujący kod:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

Jest to minimalna konfiguracja lecz dzięki temu bardzo dobrze widać co się dzieje. Najpierw dołączyliśmy makro `use Plug.Router` i następnie dwa wbudowane plugi: `:match` i `:dispatch`. Obsługujemy dwie ścieżki. Pierwsza to żądanie GET do strony głównej, a druga to wszystkie inne żądania, które zwrócą kod HTTP 404 z odpowiednią wiadomością

Dodajmy nasz plug do routera:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias Example.Plug.VerifyRequest

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(
    VerifyRequest,
    fields: ["content", "mimetype"],
    paths: ["/upload"]
  )

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  post("/upload", do: send_resp(conn, 201, "Uploaded"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

I oto jest! Skonfigurowaliśmy nasz plug by obsługiwał żądania tak by dla ścieżki `/upload` wymagane były pola `"content"` i `"mimetype"`.  Tylko wtedy zostanie wykonany kod routera.

Na chwilę obecną adres `/upload` nie jest specjalnie użyteczny, ale wiemy już jak stworzyć i włączyć nasz plug.

## Uruchomienie aplikacji web

Zanim uruchomimy naszą aplikację web musimy skonfigurować serwer, w tym przypadku będzie to Cowboy. Będzie to konfiguracja minimum która pozwoli nam na uruchomienie aplikacji, szczegółami zajmiemy się w kolejnych lekcjach.

Rozpocznijmy od aktualizacji sekcji `application` w pliku `mix.exs` tak by wskazać Elixirowi naszą aplikację i ustawić jej zmienne środowiskowe. Po tych zmianach nasz plik powinien wyglądać mniej więcej tak:

```elixir
def application do
  [applications: [:cowboy, :plug], mod: {Example, []}, env: [cowboy_port: 8080]]
end
```

Następnie zaktualizujmy plik `lib/example.ex` by uruchomić superwizora Cowboy:

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Plug.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

I teraz by uruchomić naszą aplikację wystarczy wpisać:

```shell
$ mix run --no-halt
```

## Testowanie Plugów

Testowanie plugów jest znacznie ułatwione dzięki modułowi `Plug.Test`. Dostarcza on wiele przydatnych funkcji, które ułatwiają tworzenie testów.

Przyjrzyjmy się jak można przetestować nasz router:

```elixir
defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Plug.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn =
      conn(:get, "/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      conn(:get, "/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

## Dostępne Plugi

Wiele plugów jest dostępnych od ręki w repozytorium.  Kompletną listę można znaleźć w [dokumentacji Pluga](https://github.com/elixir-lang/plug#available-plugs).
