---
version: 1.0.3
title: Specyfikacje i typy
---

W tej lekcji przyjrzymy się składni `@spec` i `@type`. Pierwszy służy jako dodatek do składni, który pozwala na analizę kodu przez automatyczne narzędzia. Drugi pozwala na pisanie kodu, który jest bardziej czytelny i prostszy w zrozumieniu.

{% include toc.html %}

## Wstęp 

Nie jest niczym niezwykłym, chęć określenia interfejsu funkcji. Można oczywiście użyć [adnotacji @doc](../../basics/documentation), ale jest to jedynie informacja dla innych programistów, która nie jest weryfikowana w czasie kompilacji. W tym celu Elixir ma adnotację `@spec`, która pozwala na opisanie specyfikacji funkcji w sposób zrozumiały dla kompilatora.

Jednakże w niektórych przypadkach specyfikacje mogą być dość złożone. Jeżeli chcemy zredukować tę złożoność, to możemy zdefiniować własny typ. Adnotacja `@type` służy w tym właśnie celu. Z drugiej strony, Elixir pozostaje językiem dynamicznym, co oznacza, że wszystkie informacje o typach zostaną zignorowane przez kompilator. Mogą być jednak one użyte przez inne narzędzia.  

## Specyfikacje

Jeżeli masz doświadczenie w innych językach, jak Java, to możesz rozumieć specyfikacje jak interfejsy. Specyfikacja określa, jaki jest typ parametrów i wartości zwracanej. 

By zdefiniować typy wejściowe i wyjściowe, musimy umieścić dyrektywę `@spec` tuż przed definicją funkcji. Jako parametry przyjmuje ona nazwę funkcji, listę typów parametrów i po `::` typ wartości zwracanej. 

Przyjrzyjmy się temu na poniższym przykładzie:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

Wszystko wygląda poprawnie i gdy wywołamy funkcję, to otrzymamy wynik, ale funkcja `Enum.sum` zwraca `number`, a nie `integer` jak określiliśmy w specyfikacji. To może być źródłem błędów! Możemy zatem wykorzystać narzędzia, takie jak Dialyzer, by odszukać tego typu błędy. O narzędziach porozmawiamy w innej lekcji. 
 
## Własne typy

Tworzenie specyfikacji jest fajne, ale czasami nasze funkcje używają bardziej skomplikowanych struktur danych niż liczby czy kolekcje. W takich przypadkach informacje zdefiniowane w `@spec` będą trudne to zrozumienia i zmiany przez innych programistów. Czasami funkcja przyjmuje wiele parametrów albo zwraca złożoną strukturę. Długa lista parametrów jest też przykładem złego zapachu w kodzie. W językach obiektowych jak Ruby czy Java możemy z łatwością zdefiniować klasę, która opakuje nam dane i pomoże rozwiązać problem. W Elixirze nie ma klas, ale że jest on łatwy do rozszerzenia, to możemy zdefiniować własny typ.
  
Elixir ma zdefiniowane pewne podstawowe typu jak `integer` czy `pid`. Ich pełna lista jest dostępna w [dokumentacji](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax).
 
### Definiowanie typu
  
Zmodyfikujmy naszą funkcję `sum_times` wprowadzając kilka dodatkowych parametrów:

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Użyliśmy tu struktury z modułu `Examples`, która zawiera dwa pola `first` i `last`. Jest to uproszczona wersja struktury z modułu `Range`. Będziemy jeszcze mówić o strukturach przy okazji lekcji o [modułach](../../basics/modules/#structs). Załóżmy, że potrzebujemy specyfikacji używającej `Examples` w wielu miejscach. Oznacza to dużo pisania, a w dodatku łatwo o błąd. Rozwiązaniem jest użycie `@type`. 
 
Elixir ma trzy dyrektywy opisujące typ:

  - `@type` – najprostszy, publiczny typ. Jego wewnętrzna struktura jest też publiczna.
  - `@typep` – typ jest prywatny i może być użyty tylko w module, w którym został zdefiniowany. 
  - `@opaque` – typ jest publiczny, ale jego wewnętrzna struktura jest prywatna. 

Zdefiniujmy zatem nasz typ:

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

Zdefiniowaliśmy typ `t(first, last)`, który reprezentuje strukturę `%Examples{first: first, last: last}`. Jak widać typ może być sparametryzowany i dlatego zdefiniowaliśmy też typ `t`, który reprezentuje strukturę `%Examples{first: integer, last: integer}`.   

Na czym polega różnica? Pierwszy z nich opisuje strukturę `Examples`, w której klucze mogą być dowolnego typu. Drugi określa, że klucze mają typ `integers`. Co oznacza, że kod:
  
```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

Jest równoważny:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### Dokumentowanie typów

Ostatnią rzeczą, o którą należy omówić, jest sposób dokumentowania typów. Jak wiemy z lekcji o [dokumentacji](../../basics/documentation), mamy do dyspozycji adnotacje `@doc` i `@moduledoc` służące do tworzenia dokumentacji dla funkcji i modułów. Aby dokumentować typ, używamy `@typedoc`:

```elixir
defmodule Examples do
  @typedoc """
      Type that represents Examples struct with :first as integer and :last as integer.
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

Dyrektywa `@typedoc` działa na tej samej zasadzie co `@doc` i `@moduledoc`.
