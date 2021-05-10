%{
  version: "1.1.1",
  title: "Stringler (Dizeler)",
  excerpt: """
  Stringler, Karakter Listeleri, Graphemes ve Codepoints.
  """
}
---

## Strinler

Elixir stringleri, bir dizi bayttan başka bir şey değil. Şimdi bir örneğe bakalım:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

Stringimizi `0` baytı ile birleştirirsek , IEx artık geçersiz bir dizi olduğu için stringin içinde bulunan baytları bize gösterir.
Bu yol ile herhangi bir stringin içindeki baytları göre biliriz.

>NOT: << >> söz dizimini kullanarak derleyiciye bu semboller içindeki elemanların bayt olduğunu belirtiyoruz.

## Karakter Listeleri

Dahili olarak Elixir de stringler karakter dizisinden ziyade bayt dizi olarak temsil edilir. Elixir de ayrıca char list (karakter listesi) veri tipine sahiptir. Elixir stringleri çift tırnak kullanırken, karakter listeleri tek tırnak kullanır.

Peki arasındaki fark nedir ? Karakter listelerinde her bir değer Unicode olarak kodlanırken, stringler UTF-8 kodlanır. Hadi inceleyelim:

```elixir
iex(5)> 'hełło'
[104, 101, 322, 322, 111]
iex(6)> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

ł için Unicode kod noktası `322` iken, UTF-8 için iki bayt `197`, `130` olarak kodlanmıştır.

Elixir de kod yazarken genellik stringleri kullanırız. Bazı erlang modülleri için gerekli olduğundan charlist destek verilmiştir.

Daha fazla destek için resmi [`Başlangıç Kılavuzu'na`] bakınız.(http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## Graphemes ve Codepoints

Codepoints, UTF-8 kodlamasına bağlı olarak bir veya daha fazla bayt tarafından temsil edilen basit Unicode karakterleridir. ABD ASCII karakter kümesinin dışındaki karakterler her zaman birden fazla bayt olarak kodlanır. Örneğin, tilde veya aksan (`á, ñ, è`) Latin karakterleri genellikle iki bayt olarak kodlanır.Asya dillerinden karakterler genellikle üç veya dört bayt olarak kodlanır. Graphemeler tek bir karakter olarak işlenen çoklu kod noktalarından oluşur.

String modülü, bunları sağlamak için iki işlev daha sunmaktadır: "graphemes / 1" ve "codepoints / 1". Bir örneğe bakalım:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## String Fonksiyonları

String modülünün kullanışlı bazı fonksiyonlarını inceleyelim. Bu derste mevcut fonksiyonların bir kısmını kapsayacaktır. Fonksiyonların tam listesini görmek için resmi  [`String`](https://hexdocs.pm/elixir/String.html) dokümanlarına bakın.

### `length/1`

Stringlerin içinde Graphemes sayını döner.

```elixir
iex> String.length "Hello"
5
```

### `replace/3`

Belirtilen desenle eşleşenleri belirtilen string ile  değiştirip yeni bir dize döndürür.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

N kere tekrarlanan yeni bir string döndürür.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

Bir desene göre bölünmüş stringlerin bir listesini döndürür.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Egzersiz

Strinleri anladığımızdan emin olmak için basit bir egzersiz yapalım.

### Anagramlar

A ve B yi eşit hale getirmek için A veya B nin yeniden düzenlemenin bir yolu varsa bu anagram olarak kabul edilir. Örneğin:

+ A = super
+ B = perus

Eğer A stringini yeniden sıralarsak B  stringini elde ede biliriz yada tam tersi.

Peki, Elixir de iki stringin anagram oluşturup oluşturmayacağını nasıl öğrenebiliriz ?  En kolay yolu her iki stringdeki  graphemeleri alfabetik olarak sıralamak ve her iki stringin eşit olup olmadığını kontrol etmektir. Hadi deneyelim:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Önce `anagrams?/2` izleyelim. Aldığımız parametrelerin binary olup olmadığını kontrol edelim. Elixirde para metrenin string olup olmadığı bu şekilde kontrol edilmektedir.

Daha sonra 2 stringi alfabetik olarak sıralayan bir fonksiyon çağırıyoruz. Bu fonksiyonda, önce strinleri küçük harfe çeviriyoruz ve ardından graphemeslerin bir listesini almak için `String.graphemes/1` kullanıyoruz. Son olarak da `Enum.sort/1` içine aktarıyoruz. oldukça basit, değil mi ? 

iex üzerindeki çıktıyı kontrol edelim:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```
Gördüğünüz gibi, `anagrams?` a yapılan son çağrı bir FunctionClauseError'a neden oldu. Bu hata bize, modülümüz de ikili olmayan argümanı alma desenini karşılayan hiçbir fonksiyonun olmadığını anlatıyor. Sadece iki stringi alan fonksiyonun olduğunu  ve başka bir şey olmadığını söylüyor.