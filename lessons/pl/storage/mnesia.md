%{
  version: "0.9.0",
  title: "Mnesia",
  excerpt: """
  Mnesia to rozwiązanie „wagi ciężkiej” do zarządzania w czasie rzeczywistym rozproszonymi bazami danych.
  """
}
---

## Wstęp

Mnesia to system zarządzania bazą danych (ang. _Database Management System_ – DBMS) dostarczany razem ze środowiskiem Erlanga, który możemy oczywiście wykorzystać w Elixirze. Mnesia ma *relacyjno-obiektowy, hybrydowy model danych* co czyni ją odpowiednim narzędziem do tworzenia rozproszonych aplikacji w dowolnej skali.

## Kiedy używać

Kiedy powinniśmy użyć konkretnej technologi? To często bardzo kłopotliwe pytanie. Jeżeli odpowiedź na jedno z poniższych pytań brzmi „tak”, to znak, że warto zastanowić się nad użyciem Mnesii zamiast ETS lub DETS.

  - Czy potrzebujesz mieć możliwość wycofania transakcji?
  - Czy potrzebujesz prostej w użyciu składni do odczytu i zapisu danych?
  - Czy potrzebujesz przechowywać dane w wielu miejscach (węzłach) zamiast w jednym?
  - Czy chcesz mieć możliwość określenia gdzie, dysk lub RAM, dane będą przechowywane?

## Schemat

Ponieważ Mnesia jest częścią Erlanga, a nie Elixira, to odwołujemy się do niej z użyciem dwukropka (patrz: [Współpraca z Erlangiem](../../advanced/erlang/)):

```elixir

iex> :mnesia.create_schema([node()])

# jeżeli jednak preferujesz Elixira...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

W tej lekcji skupimy się na pracy z API Mnesii. `Mnesia.create_schema/1` tworzy nowy, pusty schemat i umieszcza go w liście węzłów. W naszym przypadku węzłem jest aktualna sesja IEx.

## Węzły

Gdy uruchamiamy `Mnesia.create_schema([node()])` poprzez IEx, powinniśmy zobaczyć folder **Mnesia.nonode@nohost**, lub podobny, w aktualnym katalogu. Możesz się zastanawiać, co oznacza katalog **nonode@nohost**, bo dotychczas się z nim nie spotkaliśmy. Zobaczmy zatem.

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

Kiedy wywołamy `--help` w IEx otrzymamy listę wszystkich możliwych opcji. Na liście są `--name` i `--sname` służące do konfigurowania informacji o węzłach. Węzeł to nic innego jak instancja maszyny wirtualnej Erlanga, która we własnym zakresie zarządza komunikacją, GC, zadaniami, pamięcią itd. Nazwa węzła **nonode@nohost** jest domyślną.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP 18 [erts-7.2.1] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Jak widzimy, uruchomiony przez nas węzeł nazywa się`:"learner@elixirschool.com"`. Jeżeli po raz kolejny wywołamy `Mnesia.create_schema([node()])`, to zobaczymy nowy folder o nazwie **Mnesia.learner@elixirschool.com**. Dzieje się to z prostej przyczyny. Węzły w Erlangu są używane do komunikacji pomiędzy maszynami wirtualnymi i współdzielenia (rozpraszania) informacji i zasobów. komunikacja ta nie jest ograniczona do jednej maszyny fizycznej (systemu operacyjnego), ale można komunikować się przez LAN lub internet.

## Uruchamianie Mnesii

Mamy już podstawową wiedzę i jesteśmy na dobrej drodze do uruchomienia bazy danych, uruchommy zatem Mnesia DBMS za pomocą polecenia `Mnesia.start/0`.

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

Musimy pamiętać, że jak pracujemy z systemem rozproszonym na dwóch lub więcej węzłach, to funkcja `Mnesia.start/1` musi byc wywołana na każdym z nich.

## Tworzenie tabel

Do tworzenia tabel w naszej bazie służy funkcja `Mnesia.create_table/2`. Poniżej tworzymy tabelę `Person` i przekazujemy listę asocjacyjną opisującą jej schemat.

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Kolumny definiujemy za pomocą atomów `:id`, `:name` i `:job`. Kiedy wywołamy `Mnesia.create_table/2`, otrzymamy jedną z poniższych odpowiedzi:

 - `{:atomic, :ok}` – jeżeli wszystko się udało,
 - `{:aborted, PRZYCZYNA}` – jeżeli funkcja napotkała błąd.
 
W szczególności, jeżeli tabela, to funkcja jako przyczynę zwróci `{:already_exists, table}`. Przykładowo, jeżeli spróbujemy powtórnie utworzyć tabelę, otrzymamy:  

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## „Niekoszerne” podejście 

Na początek rzućmy okiem na „niekoszerne” podejście do odczytu i zapisu danych do tabel. Zasadniczo powinno być ono unikane, ponieważ nie gwarantuje sukcesu operacji, ale pomoże nam w nauce i zapewni komfort w pracy z Mnesią. Dodajmy trochę danych do tabeli **Person**.

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...i odczytajmy je z użyciem `Mnesia.dirty_read/1`:

```elixir
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

Jeżeli spróbujemy pobrać nieistniejący rekord, Mnesia zwróci pustą listę.

## Transakcje

Tradycyjnie używamy **transakcji** do odizolowania odczytów i zapisów do bazy. Transakcje są bardzo istotnym elementem przy projektowaniu odpornych na błędy i silnie rozproszonych systemów. Dla Mnesii *transakcja jest mechanizmem pozwalającym na uruchomienie wielu operacji na danych w ramach jednego bloku funkcyjnego*. Najpierw stwórzmy anonimową funkcję, w tym przypadku `data_to_write` i przekażmy ją do `Mnesia.transaction`.

```elixir
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```
Bazując na informacji zwrotnej, możemy z satysfakcją stwierdzić, że zapisaliśmy dane do tabeli `Person`. Teraz użyjmy transakcji do odczytu danych. W tym celu użyjemy `Mnesia.read/1`, ale tak jak poprzednio w anonimowej funkcji.

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

Warto zwrócić uwagę, że jak chcemy zaktualizować rekord, wystarczy wywołać funkcję `Mnesia.write/1` przekazując klucz do istniejącego rekordu. Przykładowo, jeżeli chcemy zaktualizować rekord Hansa, wystarczy wywołać:
 
```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end)
```

## Indeksy

Mnesia pozwala na tworzenie indeksów dla kolumn, które nie są częścią klucza i tworzenie zapytań na podstawie tych indeksów. Dodajmy zatem indeks do kolumny `:job` w tabeli `Person`: 

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

Rezultat tej operacji ma strukturę podobną do `Mnesia.create_table/2`:

 - `{:atomic, :ok}` – jeżeli wszystko się udało, 
 - `{:aborted, PRZYCZYNA}` – jeżeli funkcja napotkała błąd. 
 
I podobnie jak w przypadku tworzenia tabeli, próba ponownego stworzenia indeksu spowoduje błąd `{:already_exists, table, attribute_index}`:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

Jak już indeks zostanie stworzony, możemy odpytać dane bazując na nowym indeksie:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## Dopasowania i wyszukiwanie

Mnesia pozwala na tworzenie złożonych zapytań za pomocą dopasowań i definiowanych ad-hoc funkcji wyszukujących.

Funkcja `Mnesia.match_object/1` zwraca wszystkie rekordy pasujące do podanego wzorca. Jeżeli jakakolwiek kolumna w tabeli posiada indeks, możemy go wykorzystać do stworzenia bardziej efektywnego zapytania. Dodatkowo specjalny atom `:_` służy do określenia, które kolumny nie powinny być brane pod uwagę w czasie dopasowania.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

Funkcja `Mnesia.select/2` pozwala na stworzenie zapytania z użyciem dowolnej funkcji istniejącej w Elixirze (oczywiście można użyć funkcji z Erlanga). Przyjrzyjmy się przykładowemu zapytaniu, które wyszuka rekordy, których klucz jest większy niż 3:
 
```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

Rozłóżmy ten kod na elementy pierwsze. Pierwszym parametrem jest nazwa tabeli, `Person`, drugim trójka `{match, [guard], [result]}`:

 - `match` – pełni tą samą rolę co dopasowanie w funkcji `Mnesia.match_object/2`, ale należy zwrócić tu szczególną uwagę na specjalne atomy `:"$n"`, które pełnią funkcję parametrów pozycyjnych i są przekazywane do kolejnych części zapytania,
 - `guard` – lista krotek, które definiują jakie funkcje zostaną użyte do dopasowania, w tym przypadku jest to standardowa funkcja `:>` (większy niż), która jako argumenty przyjmie wartość na pierwszej pozycji `:$1` oraz liczbę `3`,
 - `result` – lista pól, kolumn, które zostaną zwrócone. Za pomocą parametrów pozycyjnych możemy wyszczególnić konkretne kolumny i ich kolejność, zapis `[:"$1", :"$2"]` zwróci dwie pierwsze kolumny, albo za pomocą wartości `[:"$$"]` zwrócić wszystkie.
     
Więcej informacji, w języku angielskim, znajdziesz [w dokumentacji Erlang Mnesia do funkcji select/2](http://erlang.org/doc/man/mnesia.html#select-2).   
  
## Dane początkowe i migracja danych

W każdej trakcie życia każdej aplikacji nadchodzi moment, gdy musimy zaktualizować model przechowywanych danych. Przykładowo, tworząc drugą wersję naszej aplikacji, chcemy dodać kolumnę `:age` do naszej tabeli `Person`. Nie możemy raz jeszcze utworzyć tabeli `Person`, ale możemy ją transformować. W tym celu musimy wiedzieć jakie transformacje możemy zastosować przy tworzeniu tabeli. Możemy użyć funkcji `Mnesia.table_info/2` by otrzymać informację o aktualnej strukturze tabeli, a następnie funkcji `Mnesia.transform_table/3` by dokonać transformacji tabeli.
    
Kod będzie działał zgodnie z poniższym algorytmem:

* Utwórz drugą wersję (dalej v2) tabeli z kolumnami: `[:id, :name, :job, :age]`,
* Obsłuż wyniki operacji w następujący sposób:
    * `{:atomic, :ok}` – dodaj indeksy do kolumn `:job` i `:age`
    * `{:aborted, {:already_exists, Person}}` – sprawdź, które kolumny już istnieją i następnie:
        * Jeżeli tabela zawiera tylko kolumny z pierwotnej wersji (`[:id, :name, :job]`), transformują ją do v2 dodając kolumnę `:age` z wartością domyślną 21 i indeksem, 
        * Jeżeli tabela jest już w nowej wersji, nic nie rób,
        * W innym przypadku zwróć błąd.
        
Funkcja `Mnesia.transform_table/3` jako argumenty przyjmuje nazwę tabeli, funkcję transformującą pomiędzy starym a nowym formatem danych, oraz listę nowych kolumn.

```elixir
iex> case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
...>   {:atomic, :ok} ->
...>     Mnesia.add_table_index(Person, :job)
...>     Mnesia.add_table_index(Person, :age)
...>   {:aborted, {:already_exists, Person}} ->
...>     case Mnesia.table_info(Person, :attributes) do
...>       [:id, :name, :job] ->
...>         Mnesia.transform_table(
...>           Person,
...>           fn ({Person, id, name, job}) ->
...>             {Person, id, name, job, 21}
...>           end,
...>           [:id, :name, :job, :age]
...>           )
...>         Mnesia.add_table_index(Person, :age)
...>       [:id, :name, :job, :age] ->
...>         :ok
...>       other ->
...>         {:error, other}
...>     end
...> end
```
         
