%{
  version: "1.0.4",
  title: "Guardian (Podstawy)",
  excerpt: """
  [Guardian](https://github.com/ueberauth/guardian) jest szeroko używaną biblioteką do obsługi uwierzytelniania bazującą na [JWT](https://jwt.io/) (JSON Web Token).
  """
}
---

## JWT

JWT umożliwia użycie rozbudowanego tokenu uwierzytelniania.
W przeciwieństwie do innych systemów uwierzytelniania, które udostępniają jedynie dane o identyfikatorze podmiotu i zasobu, JWT udostępnia dodatkowo nastepujące informacje:

* kto wystąpił o token,
* dla kogo przeznaczony jest token,
* który system będzie używał token,
* kiedy zostało wysłane żądanie,
* kiedy token wygasa.

Dodatkowo Guardian udostępnia kilka innych pól, pozwalających na zdefiniowanie:

* jaki jest typ tokenu,
* jakie uprawnienia ma posiadacz.

To tylko podstawowe pola JWT.
Jeżeli twoja aplikacja wymaga dodatkowych informacji, można je dodać.
Pamiętaj jedynie, aby JWT był możliwie krótki, gdyż musi się on zmieścić w nagłówku HTTP.

Tak rozbudowana funkcjonalność pozwala na przekazywanie tokenów JWT w ramach całego systemu jako w pełni funkcjonalnych kontenerów na informacje o uwierzytelnieniu.

### Gdzie używać?

JWT token może być użyty do uwierzytelniania w dowolnym miejscu systemu i w dowolnej aplikacji.

* Aplikacje SPA
* Kontrolery (poprzez sesję przeglądarki)
* Kontrolery (poprzez nagłówki uwierzytelniające – API)
* Kanały frameworku Phoenix
* Żądania pomiędzy serwisami
* Procesy wewnętrzne aplikacji
* Zewnętrzne usługi uwierzytelniania np. OAuth
* Funkcja „zapamiętaj mnie”
* Inne interfejsy - czysty TCP, UDP, CLI, etc.

Tokeny JWT mogą zatem zostać użyte wszędzie tam, gdzie potrzebujemy weryfikacji uwierzytelniania.

### Czy potrzebuję bazy danych?

Nie ma potrzeby przechowywania JWT w bazie danych.
Na podstawie danych z tokena takich jak, żądający i data wygaśnięcia, można kontrolować udostępniane zasoby.
Zazwyczaj korzystamy z bazy danych, bo tam składowane są zasoby, ale samo JWT tego nie wymaga.

Na przykład, jeżeli chcemy użyć JWT do uwierzytelniania komunikacji po UDP, to nie będziemy używać bazy danych.
W zamian zapiszemy wszystkie informacje bezpośrednio w tokenie.
Po weryfikacji, zakładając, że jest on poprawnie podpisany, możemy już udostępnić zasoby.

Jeżeli jednak zdecydujesz się na użycie bazy danych do przechowywania JWT, to otrzymasz możliwość weryfikacji czy token jest nadal prawidłowy, a więc czy nie został on unieważniony.
Możesz też wykorzystać bazę danych, by przykładowo unieważnić wszystkie tokeny danego użytkownika.
W tym celu Guardian wykorzystuje [GuardianDB](https://github.com/hassox/guardian_db). Samo GuardianDb używa 'zaczepów' Guardian, by przeprowadzić walidację i zapisać lub usunąć dane z bazy.
Będziemy jeszcze o tym później mówić.

## Konfiguracja

Konfiguracja Guardiana jest rozbudowana i ma wiele opcji.
Zajmiemy się nimi za chwilę, ale najpierw przygotujmy coś prostego.

### Minimalna konfiguracja

Aby rozpocząć, musimy ustawić kilka rzeczy.

#### Konfiguracja środowiska

W pliku `mix.exs`:

```elixir
def application do
  [
    mod: {MyApp, []},
    applications: [:guardian, ...]
  ]
end

def deps do
  [
    {:guardian, "~> x.x"},
    ...
  ]
end
```

W pliku `config/config.exs`:

```elixir
# Nadpisz tę wartość w plikach konfiguracyjnych dla poszczególnych środowisk
config :guardian, Guardian,
  issuer: "MyAppId",
  secret_key: Mix.env(),
  serializer: MyApp.GuardianSerializer
```

Oto minimalna ilość informacji potrzebnych Guardianowi do działania.
Oczywiście nie powinniśmy podawać sekretnego klucza w głównym pliku konfiguracyjnym. Każde środowisko powinno mieć własny klucz.
O ile typowym jest używanie tego samego klucza w środowisku dev i test, to już środowisko produkcyjne powinno mieć własny, silny klucz (na przykład wygenerowany za pomocą polecenia `mix phoenix.gen.secret`).

`lib/my_app/guardian_serializer.ex`

```elixir
defmodule MyApp.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias MyApp.Repo
  alias MyApp.User

  def for_token(user = %User{}), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("User:" <> id), do: {:ok, Repo.get(User, id)}
  def from_token(_), do: {:error, "Unknown resource type"}
end
```

Twój serializer jest odpowiedzialny za odnalezienie zasobu, którego identyfikator znajduje się w polu `sub` (od _subject_).
Może on wykorzystać w tym celu bazę danych, zewnętrzne API, albo nawet ciąg znaków.
Jest on też odpowiedzialny za zapis identyfikatora do pola `sub`.

Tak wygląda minimalna konfiguracja.
Oczywiście można tu zrobić znacznie więcej, ale na początek wystarczy.

#### Użycie w aplikacji

Gdy mamy już naszą konfigurację na miejscu, musimy jakoś zintegrować Guardiana z aplikacją.
Jako że wykorzystujemy minimalną konfigurację, to zajmijmy się najpierw żądaniami HTTP.

## Żądania HTTP

Guardian udostępnia pewną ilość plugów, pozwalających na integrację z protokołem HTTP.
O plugach możesz poczytać [w lekcji im poświęconej](../../specifics/plug/).
Guardian nie wymaga Phoenixa, ale użyjemy go tutaj, gdyż dzięki temu przykłady będą łatwiejsze do pokazania.

Najprostszą metodą integracji jest użycie routera, ale ponieważ sam proces integracji opiera się o mechanizm plugów, można go użyć wszędzie tam, gdzie mają zastosowanie plugi.

Zasadniczo zasada działania plugu Guardiana jest następująca:

1. Znajdź token gdzieś w żądaniu: plugi `Verify*`.
2. Opcjonalnie załaduj identyfikator zasobu: plug `LoadResource`.
3. Sprawdź, czy token z żądania jest poprawny i jeżeli nie jest, zablokuj dostęp: plug `EnsureAuthenticated`.

By spełnić wszystkie wymagania programistów, Guardian implementuje powyższe fazy w oddzielnych plugach.
By znaleźć token używamy plugów `Verify*`.

Stwórzmy kilka potoków.

```elixir
pipeline :maybe_browser_auth do
  plug(Guardian.Plug.VerifySession)
  plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
  plug(Guardian.Plug.LoadResource)
end

pipeline :ensure_authed_access do
  plug(Guardian.Plug.EnsureAuthenticated, %{"typ" => "access", handler: MyApp.HttpErrorHandler})
end
```

Potoki te pozwalają na spełnienie różnych wymagań związanych z uwierzytelnianiem.
Pierwszy próbuje odnaleźć token w sesji, kolejny w nagłówku, a gdy token zostanie odnaleziony, to ładowane są odpowiednie zasoby.

Drugi z potoków wymaga obecności poprawnego, zweryfikowanego tokenu typu `access`.
By ich użyć, dodajmy je do naszej aplikacji.

```elixir
scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth])

  get("/login", LoginController, :new)
  post("/login", LoginController, :create)
  delete("/login", LoginController, :delete)
end

scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth, :ensure_authed_access])

  resource("/protected/things", ProtectedController)
end
```

Powyższa konfiguracja dla procesu logowania pozwala na uwierzytelnienie użytkownika, jeżeli tylko taki istnieje.
Druga z konfiguracji sprawdza, czy przesłano poprawny token.
Oczywiście nie _musimy_ używać potoków i zamiast nich dodać odpowiednie elementy bezpośrednio do kontrolerów, by uzyskać bardzo elastyczne do konfiguracji rozwiązanie, ale tu wybraliśmy najprostsze rozwiązanie.

Jak na razie kompletnie pominęliśmy jedną rzecz – obsługę błędów dodaną w plugu `EnsureAuthenticated`.
Jest to bardzo prosty moduł zawierający dwie funkcje:

* `unauthenticated/2`
* `unauthorized/2`

Obie te funkcje jako parametry otrzymują strukturę Plug.Conn i mapę parametrów żądania oraz powinny obsłużyć odpowiedni rodzaj błędów.
Innym rozwiązaniem jest użycie kontrolera z Phoenixa!

#### W kontrolerze

W kontrolerze mamy kilka różnych sposobów, by otrzymać informacje o aktualnie zalogowanym użytkowniku.
Zacznijmy od najprostszego.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller
  use Guardian.Phoenix.Controller

  def some_action(conn, params, user, claims) do
    # Działanie funkcji
  end
end
```

Używając modułu `Guardian.Phoenix.Controller`, możemy otrzymać dwa dodatkowe argumenty i wykorzystać dopasowanie wzorców.
Należy jednak pamiętać, że jeżeli nie używamy `EnsureAuthenticated`, to możemy otrzymać `nil` jako użytkownika.

Inną, bardziej elastyczną i bogatszą w informacje, metodą jest użycie kodu pomocniczego dla plugów.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller

  def some_action(conn, params) do
    if Guardian.Plug.authenticated?(conn) do
      user = Guardian.Plug.current_resource(conn)
    else
      # Brak użytkownika
    end
  end
end
```

#### Logowanie i wylogowywanie

Zalogowanie i wylogowanie z wykorzystaniem sesji przeglądarki jest banalnie proste.
Kod kontrolera służącego do zalogowania:

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      # Użyj tokenów 'access'.
      # Również inne tokeny mogą zostać użyte, takie jak :refresh itd.
      conn
      |> Guardian.Plug.sign_in(user, :access)
      |> respond_somehow()

    {:error, reason} ->
      nil
      # Obsłuż niepowodzenie weryfikacji danych użytkownika.
  end
end

def delete(conn, params) do
  conn
  |> Guardian.Plug.sign_out()
  |> respond_somehow()
end
```

Użycie login API jest trochę inne, ponieważ nie ma tam sesji i musimy samodzielnie odesłać token do użytkownika.
W tym celu login API używa nagłówka `Authorization`.
Metoda ta jest przydatna, gdy nie chcemy lub nie możemy wykorzystać mechanizmu sesji.

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      {:ok, jwt, _claims} = Guardian.encode_and_sign(user, :access)
      conn |> respond_somehow(%{token: jwt})

    {:error, reason} ->
      nil
      # Obsłuż niepowodzenie weryfikacji danych użytkownika.
  end
end

def delete(conn, params) do
  jwt = Guardian.Plug.current_token(conn)
  Guardian.revoke!(jwt)
  respond_somehow(conn)
end
```

Mechanizm sesji wykorzystuje pod spodem `encode_and_sign`, a tu robimy to samodzielnie.
