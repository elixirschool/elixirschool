%{
  version: "1.2.1",
  title: "Zapytania",
  excerpt: """
  """
}
---

W tej lekcji będziemy kontynuować budowanie aplikacji `Friends` i modułu do katalogowania filmów, nad którym pracowaliśmy w [poprzedniej lekcji](/pl/lessons/ecto/associations).

## Pobieranie rekordów przy pomocy Ecto.Repo

Jak być może pamiętasz, „repozytorium” w Ecto jest interfejsem do miejsca, w którym trzymamy dane, takiego jak nasza baza danych Postgres.
Cała komunikacja z bazą danych będzie dokonywana za pośrednictwem repozytorium.

Jest kilka funkcji, dzięki którym możemy wykonać proste zapytania bezpośrednio do `Friends.Repo`.

### Pobieranie rekordów na podstawie ID

Możemy użyć funkcji `Repo.get/3`, aby pobrać z bazy danych rekord o danym ID. Funkcja ta wymaga dwóch argumentów: "odpytywalnej” struktury danych i ID rekordu, który chcemy znaleźć w bazie. Zwraca strukturę opisującą znaleziony rekord (jeśli ów istnieje), a gdy takiego nie znajdzie, zwraca `nil`.

Spójrzmy na poniższy przykład. Pobierzemy film, którego ID to `1`:

```elixir
iex> alias Friends.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Zauważ, że pierwszym argumentem, który przekazujemy do `Repo.get/3` jest nasz moduł `Movie`. `Movie` jest „odpytywalny”, gdyż używa modułu `Ecto.Schema` i definiuje schemat swojej struktury danych. To daje modułowi `Movie` dostęp do protokołu `Ecto.Queryable`, który konwertuje strukturę danych do `Ecto.Query`. Zapytania Ecto są używane do pozyskiwania danych z bazy — ale o nich później.

### Pobieranie rekordów na podstawie atrybutu

Rekordy spełniające zadane kryteria możemy pobierać również za pomocą funkcji `Repo.get_by/3`. Wymaga ona dwóch argumentów: „odpytywalnej” struktury danych i warunku, który będzie użyty w zapytaniu. `Repo.get_by/3` zwraca pojedynczy wynik z repozytorium. Spójrzmy na przykład:

```elixir
iex> Repo.get_by(Movie, title: "Ready Player One")
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Jeśli chcemy napisać bardziej skomplikowane zapytania czy też zwrócić _wszystkie_ rekordy spełniające dany warunek, będziemy potrzebować modułu `Ecto.Query`.

## Pisanie zapytań z Ecto.Query

Moduł `Ecto.Query` dostarcza nam język zapytań, który możemy wykorzystać do tworzenia zapytań i pozyskiwania danych z repozytorium aplikacji.

### Zapytania oparte o słowa kluczowe z Ecto.Query.from/2

Możemy tworzyć zapytania przy pomocy makra `Ecto.Query.from/2`. Przyjmuje ono dwa argumenty: wyrażenie i opcjonalną listę asocjacyjną (listę typu klucz-wartość). Stwórzmy najprostsze zapytanie, aby wybrać wszystkie filmy z naszego repozytorium:

```elixir
iex> import Ecto.Query
iex> query = from(Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

Aby wykonać nasze zapytanie, użyjemy funkcji `Repo.all/2`. Wymaganym argumentem przez nią przyjmowanym jest zapytanie Ecto, zwracana jest natomiast lista wszystkich rekordów spełniających warunki tego zapytania.

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### Zapytania bez przypisań z użyciem makra from

W przedstawionym wyżej przykładzie brakuje najciekawszych elementów zapytań SQL. Często chcemy odpytać bazę jedynie o konkretne pola bądź przefiltrować rekordy na podstawie jakiegoś warunku. Pobierzmy wartości `title` i `tagline` wszystkich filmów o tytule `"Ready Player One"`:

```elixir
iex> query = from(Movie, where: [title: "Ready Player One"], select: [:title, :tagline])
#Ecto.Query<from m0 in Friends.Movie, where: m0.title == "Ready Player One",
 select: [:title, :tagline]>

iex> Repo.all(query)
SELECT m0."title", m0."tagline" FROM "movies" AS m0 WHERE (m0."title" = 'Ready Player One') []
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    id: nil,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Zauważ, że zwrócona struktura ma niepuste wartości jedynie dla pól `tagline` i `title` — jest to efektem wyrażenia `select:` w naszym zapytaniu.

Zapytania takie jak to nazywane są _zapytaniami bez przypisań_, gdyż są na tyle proste, że nie wymagają przypisań.

#### Przypisania w zapytaniach

Jak dotąd używaliśmy modułu implementującego protokół `Ecto.Queryable` (tj. `Movie`) jako pierwszego argumentu dla makra `from`. Możemy jednak użyć również wyrażenia `in`, jak w tym przykładzie:

```elixir
iex> query = from(m in Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

W tym przypadku `m` nazywamy _przypisaniem_ (ang. _binding_). Przypisania są niezwykle przydatne, ponieważ pozwalają nam odnosić się do danego modułu w innych częściach zapytania. Pobierzmy teraz z bazy wszystkie filmy, które mają ID mniejsze od `2`:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
#Ecto.Query<from m0 in Friends.Movie, where: m0.id < 2, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

Bardzo istotne jest, jak zmieniła się tu wartość wyjściowa zapytania. Użycie _wyrażenia_ z przypisaniem w części `select:` pozwala nam na dokładne wskazanie, w jakiej formie mają być zwrócone wybrane pola. Możemy na przykład chcieć, by zapytanie zwracało krotki, jak w tym przykładzie:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})

iex> Repo.all(query)
[{"Ready Player One"}]
```

Dobrym pomysłem jest, aby zaczynać zawsze z prostymi zapytaniami bez przypisań, a przypisania wprowadzać wtedy, kiedy faktycznie potrzebujemy odnieść się do struktury danych. Więcej na ten temat możesz znaleźć w [dokumentacji Ecto](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions).

### Zapytania oparte o makra

W pokazanych wyżej przykładach używaliśmy słów kluczowych `select:` i `where:` w makrze `from`, aby zbudować zapytanie — są to tak zwane _zapytania oparte o słowa kluczowe_. Jest jednak również inny sposób tworzenia zapytań — zapytania oparte o makra. Ecto dostarcza makra dla każdego ze słów kluczowych, jak na przykład `select/3` lub `where/3`. Każde z makr przyjmuje _odpytywalną_ wartość, listę konkretnych przypisań i takie samo wyrażenie, jakie podalibyśmy w analogicznym zapytaniu ze słowami kluczowymi:

```elixir
iex> query = select(Movie, [m], m.title)
#Ecto.Query<from m0 in Friends.Movie, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

Niewątpliwą zaletą makr jest to, że bardzo dobrze działają z potokami funkcji:

```elixir
iex> Movie \
...>  |> where([m], m.id < 2) \
...>  |> select([m], {m.title}) \
...>  |> Repo.all
[{"Ready Player One"}]
```

Zwróć uwagę na to, że aby kontynuować pisanie zapytania po znaku nowej linii, użyliśmy ukośnika wstecznego — `\`.

### Użycie where z interpolacją wartości

Aby użyć interpolowanych wartości lub Elixirowych wyrażeń w naszych klauzulach `where`, musimy użyć operatora przypięcia — `^`. Pozwala nam to _przypiąć_ wartość do zmiennej i odnosić się do tejże przypiętej wartości, zamiast zmieniać wartość przypisaną tej zmiennej.

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)
%Ecto.Query<from m in Friends.Movie, where: m.title == ^"Ready Player One",
 select: m.tagline>
iex> Repo.all(query)

15:21:46.809 [debug] QUERY OK source="movies" db=3.8ms
["Something about video games"]
```

### Pobieranie pierwszych i ostatnich rekordów

Możemy pobrać pierwszy lub ostatni rekord z naszego repozytorium odpowiednio za pomocą funkcji `Ecto.Query.first/2` i `Ecto.Query.last/2`.

Najpierw stwórzmy wyrażenie zapytania, używając funkcji `first/2`:

```elixir
iex> first(Movie)
#Ecto.Query<from m0 in Friends.Movie, order_by: [asc: m0.id], limit: 1>
```

Następnie możemy przekazać nasze zapytanie do funkcji `Repo.one/2`, aby pobrać wynik:

```elixir
iex> Movie |> first() |> Repo.one()

SELECT m0."id", m0."title", m0."tagline" FROM "movies" AS m0 ORDER BY m0."id" LIMIT 1 []
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Funkcji `Ecto.Query.last/2` używa się w dokładnie taki sam sposób:

```elixir
iex> Movie |> last() |> Repo.one()
```

## Zapytania o powiązane dane

### Ładowanie powiązanych rekordów

Aby mieć dostęp do powiązanych rekordów, które udostępniają nam makra `belongs_to`, `has_many` i `has_one`, musimy _załadować_ odpowiednie schematy.

Spójrzmy najpierw, co się stanie, jeśli spróbujemy dostać się do rekordów aktorów związanych z danym filmem:

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

_Nie mamy_ dostępu do tych danych, dopóki ich nie załadujemy. Istnieje kilka sposobów na ładowanie takich danych w Ecto.

#### Ładowanie z dwoma zapytaniami

Poniższe zapytanie załaduje powiązane dane w _oddzielnym_ zapytaniu.

```elixir
iex> Repo.all(from m in Movie, preload: [:actors])

13:17:28.354 [debug] QUERY OK source="movies" db=2.3ms queue=0.1ms
13:17:28.357 [debug] QUERY OK source="actors" db=2.4ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Możesz zauważyć, że powyższa linia kodu uruchomiła _dwa_ zapytania do bazy danych — pierwsze dla wszystkich filmów, a drugie dla wszystkich aktorów powiązanych z filmem o danym ID.

#### Ładowanie z jednym zapytaniem

Możemy ograniczyć liczbę zapytań do bazy w następujący sposób:

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)

13:18:52.053 [debug] QUERY OK source="movies" db=3.7ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Pozwala to na wykonanie tylko jednego zapytania zamiast dwóch. Opcja ta ma też inną zaletę — możemy dzięki niej wybierać pola i filtrować według wartości nie tylko filmy, ale i aktorów w tym samym zapytaniu. Przykładowo, to podejście umożliwia nam odpytanie bazy o wszystkie filmy powiazane z aktorami spełniającymi odpowiednie warunki za pomocą wyrażenia `join`, jak poniżej:

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne",
  preload: [actors: a]
```

Więcej o wyrażeniach `join` powiemy nieco później.

#### Ładowanie danych dla pobranych wcześniej rekordów

Możemy również załadować powiązane schematy dla pobranych już rekordów:

```elixir
iex> movie = Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>, # aktorzy NIE SĄ ZAŁADOWANI!!!
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    },
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # aktorzy SĄ ZAŁADOWANI!!!
  characters: [],
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Teraz możemy odpytać film o aktorów:

```elixir
iex> movie.actors
[
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Tyler Sheridan"
  },
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Wyrażenia join

Możemy wykonywać zapytania zawierające wyrażenia `join` dzięki funkcji `Ecto.Query.join/5`.

```elixir
iex> alias Friends.Character
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Wade Watts",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Wade Watts"}]
```

Wyrażenie `on` może przyjąć jako argument również listę asocjacyjną:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # lista asocjacyjna
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

W powyższym przykładzie dokonujemy łączenia ze schematem Ecto, `m in Movie`. Możemy też używać łączeń do zapytań Ecto. Powiedzmy, że nasza tabela z filmami ma kolumnę `stars`, gdzie przechowujemy ocenę filmu w postaci liczby „gwiazdek”, będącą liczbą od 1 do 5.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # lista asocjacyjna
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

Język zapytań Ecto jest potężnym narzędziem, dostarczającym nam wszystkiego, czego potrzebujemy, by tworzyć nawet bardzo złożone zapytania. W tym wprowadzeniu pokazaliśmy kilka podstawowych elementów, dzięki którym możesz zacząć komponowanie własnych zapytań.
