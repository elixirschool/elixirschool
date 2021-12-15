%{
  version: "1.2.2",
  title: "Zestawy zmian",
  excerpt: """
  W celu wstawienia danych do bazy, ich zmiany lub usunięcia, funkcje `Ecto.Repo.insert/2`, `update/2` i `delete/2` wymagają zestawu zmian — _changesetu_ — jako pierwszego parametru. Ale czym są changesety?

  Niemal każdy programista zna problem sprawdzania poprawności danych wejściowych pod kątem potencjalnych błędów — chcemy mieć pewność, że dane są poprawne, zanim spróbujemy ich użyć do naszych celów.

  Ecto dostarcza kompletne rozwiązanie do pracy ze zmianami danych — moduł i strukturę `Changeset`.
  W tej lekcji dowiemy się więcej na ten temat i nauczymy się, jak weryfikować integralność danych, zanim zapiszemy je do bazy.
  """
}
---

## Tworzenie zestawów zmian

Spójrzmy na pustą strukturę `%Changeset{}`:

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

Jak możesz zauważyć, ma ona kilka potencjalnie przydatnych pól, jednak wszystkie z nich są w tej chwili puste.

Aby changeset był naprawdę użyteczny, podczas jego tworzenia musimy przedstawić projekt tego, jak wyglądają dane, które chcemy zmodyfikować.
Cóż może być lepszym narzędziem do tego celu niż stworzone przez nas schematy, które definiują pola i ich typy?

Użyjmy naszego schematu `Friends.Person` z poprzedniej lekcji:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Aby utworzyć zestaw zmian dla schematu `Person` użyjemy funkcji `Ecto.Changeset.cast/3`:

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

Pierwszym parametrem są oryginalne dane — w tym przypadku początkowa struktura `%Friends.Person{}`.
Ecto jest wystarczająco mądre, by znaleźć schemat jedynie na podstawie samej struktury.
Drugie w kolejności są zmiany, których chcemy dokonać — w powyższym przypadku była to jedynie pusta mapa.
Trzecim parametrem jest to, co czyni funkcję `cast/3` wyjątkową: lista pól, które będą brane pod uwagę, co pozwala nam na kontrolowanie, które pola mogą być zmienione i jednocześnie na ochronę pozostałych z nich.

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [:name, :age])
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Jack"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>

iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

Możesz zauważyć, że nowe imię (pole `name`) zostało za drugim razem pominięte, gdyż jego zmiana nie była tam wprost dozwolona.

Alternatywą dla `cast/3` jest funkcja `change/2`, która jednak nie pozwala na filtrowanie zmian w taki sposób, jaki umożliwia nam `cast/3`.
Jest to użyteczne wtedy, gdy ufamy źródłu zmian, albo kiedy zmieniamy dane ręcznie.

Teraz możemy tworzyć zestawy zmian, jednak dopóki nie mamy żadnej walidacji, dowolne zmiany imienia osoby będą akceptowane, więc może się skończyć tak, że imię będzie pustą wartością:

```elixir
iex> Ecto.Changeset.change(%Friends.Person{name: "Bob"}, %{name: ""})
#Ecto.Changeset<
  action: nil,
  changes: %{name: ""},
  errors: [],
  data: #Friends.Person<>,
  valid?: true
>
```

Ecto mówi, że changeset jest poprawny, ale przecież nie chcemy dopuszczać pustych imion. Naprawmy to!

## Walidacja

Ecto ma wiele wbudowanych, bardzo pomocnych funkcji do walidacji danych.

Będziemy używać `Ecto.Changeset` w wielu miejscach, więc zaimportujmy go w module zdefiniowanym w `person.ex`, który zawiera również nasz schemat:

```elixir
defmodule Friends.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Teraz możemy używać funkcji `cast/3` bezpośrednio.

Powszechnym jest definiowanie jednej lub kilku funkcji tworzących zestawy zmian dla schematu. Stwórzmy taką — jej parametrami będą struktura i mapa ze zmianami, a zwracany będzie changeset:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

Teraz możemy rozszerzyć tę funkcję, by zagwarantować, że imię będzie zawsze obecne:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
end
```

Gdy wywołujemy funkcję `Friends.Person.changeset/2` i przekazujemy pustą wartość jako `name`, zestaw zmian nie będzie już poprawny, a na dodatek będzie zawierał pomocny komunikat błędu.
Uwaga: nie zapomnij wywołać funkcji `recompile()` podczas pracy w konsoli `iex`, w przeciwnym razie zmiany wprowadzone właśnie w kodzie nie będą załadowane.

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => ""})
%Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [name: {"can't be blank", [validation: :required]}],
  data: %Friends.Person<>,
  valid?: false
>
```

Jeśli spróbujesz wywołać `Repo.insert(changeset)` ze stworzonym wyżej changesetem, funkcja zwróci krotkę `{:error, changeset}` z tym samym błędem, więc nie musisz za każdym razem sprawdzać wartości `changeset.valid?`.
Łatwiej jest spróbować wstawić, zmodyfikować lub usunąć rekord, a następnie obsłużyć błąd, jeśli taki się pojawi.

Oprócz `validate_required/2`, mamy również do dyspozycji funkcję `validate_length/3`, która przyjmuje kilka dodatkowych opcji:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

Możesz spróbować zgadnąć, jaki byłby wynik, gdybyśmy przekazali imię składające się z tylko jednej litery!

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "A"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "A"},
  errors: [
    name: {"should be at least %{count} character(s)",
     [count: 2, validation: :length, kind: :min, type: :string]}
  ],
  data: %Friends.Person<>,
  valid?: false
>
```

Możesz być dla Ciebie zaskakujące, że komunikat błędu zawiera `%{count}` — pomaga to w tłumaczeniu na inne języki; jeśli chcesz pokazywać bezpośrednio błędy użytkownikowi, możesz je uczynić czytelnymi dla ludzi za pomocą funkcji [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) — spójrz na przykład w dokumentacji.

Niektóre spośród pozostałych walidatorów wbudowanych w `Ecto.Changeset` to:

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

Pełną listę ze szczegółową instrukcją ich użycia możesz znaleźć [tutaj](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary).

### Własne walidacje

Choć wbudowane walidatory pozwalają obsłużyć szeroką gamę przypadków użycia, i tak możesz potrzebować czegoś innego.

Każda z funkcji `validate_`, których dotąd używaliśmy, przyjmuje i zwraca `%Ecto.Changeset{}`, więc możemy łatwo podłączyć własny walidator.

Możemy na przykład akceptować jedynie imiona superbohaterów:

```elixir
@fictional_names ["Black Panther", "Wonder Woman", "Spiderman"]
def validate_fictional_name(changeset) do
  name = get_field(changeset, :name)

  if name in @fictional_names do
    changeset
  else
    add_error(changeset, :name, "is not a superhero")
  end
end
```

Powyżej wprowadziliśmy dwie nowe funkcje pomocnicze: [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) i [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4). Nazwy raczej dobrze opisują ich działanie, ale i tak zachęcam do zajrzenia do dokumentacji.

Dobrą praktyką jest, by zwracać zawszze `%Ecto.Changeset{}`, dzięki czemu można potem użyć operatora `|>` i ułatwić dodanie później kolejnych walidacji:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
  |> validate_fictional_name()
end
```

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "Bob"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Bob"},
  errors: [name: {"is not a superhero", []}],
  data: %Friends.Person<>,
  valid?: false
>
```

Great, it works! However, there was really no need to implement this function ourselves — the `validate_inclusion/4` function could be used instead; still, you can see how you can add your own errors which should come useful.

## Programowe dodawanie zmian

Czasem możesz chcieć wprowadzić ręcznie jakieś zmiany do changesetu. Funkcja pomocnicza `put_change/3` istnieje właśnie w tym celu.

Zamiast wymagać niepustej wartości pola `name`, pozwólmy użytkownikom rejestrować się bez podawania imienia i nazywajmy ich wtedy "Anonymous".
Funkcja, której potrzebujemy, może wyglądać znajomo — przyjmuje i zwraza zestaw zmian, tak jak `validate_fictional_name/1`, którą stworzyliśmy wcześniej:

```elixir
def set_name_if_anonymous(changeset) do
  name = get_field(changeset, :name)

  if is_nil(name) do
    put_change(changeset, :name, "Anonymous")
  else
    changeset
  end
end
```

Możemy chcieć przypisywać użytkownikom "Anonymous" jako imię jedynie w momencie, w którym rejestrują się w naszej aplikacji — aby to uczynić, stwórzmy nową funkcję tworzącą changeset:

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

Teraz nie jest konieczne podawanie imienia, a w razie jego braku wartość `Anonymous` będzie ustawiana automatycznie, tak jak tego oczekiwaliśmy:

```elixir
iex> Friends.Person.registration_changeset(%Friends.Person{}, %{})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Anonymous"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>
```

Oddzielne funkcje tworzące changesety dla różnych przypadków użycia (takie jak `registration_changeset/2`) nie są rzeczą rzadką — czasem potrzebna jest pewna elastyczność, by wykonywać jedynie określone walidacje czy filtorwać konkretne parametry.
Wymieniona wyżej funkcja może być użyta gdzieś indziej w funkcji `sign_up/1`:

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## Podsumowanie

Istnieje wiele przypadków użycia, o których nie powiedzieliśmy w tej lekcji, takich jak [zestawy zmian bez schematów](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets), których możesz użyć do walidacji _dowolnych_ danych, czy też obsługa efektów ubocznych w changesetach ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)), praca z asocjacjami i strukturami wbudowanymi. 
Możemy się tym zająć w przyszłości, w lekcji na poziomie zaawansowanym, a w międzyczasie zachęcamy do zapoznania się z [dokumentacją Ecto Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html), gdzie można znaleźć więcej informacji na ten temat.
