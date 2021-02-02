%{
  version: "1.2.4",
  title: "Koleksiyonlar",
  excerpt: """
  Listeler (List), Demetler (Tuples), Anahtar Kelimeler (keywords), Haritalar (maps) ve işlevsel bağlaçlar.
  """
}
---

## Listeler (Lists)

Listeler değerlerin tutulduğu basit koleksiyonlardir ve birden fazla tip içerebilirler; ve listeler tekil olmayan (non-unique) değerler içerebilirler:

```elixir
iex> [3.14, :kek, "Elma"]
[3.14, :kek, "Elma"]
```

Elixir listeleri bağlantılı liste (linked list) olarak işler. Bu da demektir ki liste uzunluğuna ulaşmak bir `O(n)` işlemidir. Bu nedenle tipik olarak yeni liste elemanini başa eklemek, sona eklemekten daha hızlıdır.

```elixir
iex> liste = [3.14, :kek, "Elma"]
[3.14, :kek, "Elma"]
iex> ["π" | liste]
["π", 3.14, :kek, "Elma"]
iex> liste ++ ["Kiraz"]
[3.14, :kek, "Elma", "Kiraz"]
```

### Liste Birleştirme

Liste birleştirme işlemi `++/2` operatörunu kullanır:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Yukarıdaki (`++/2`) kullanımını açiklamak gerekirse; Elixir'de (ve Erlang'ta; çünkü Elixir, Erlang üzerinde geliştirilmiştir), bir fonksiyon veya operatörun iki bileşeni vardir. Birincisi verdiğiniz isim (burada operatör `++`), ve aldiğı parametrelerin sayisi (_arity_). İşlem için alınan parametreler bir sayıdır ve Elixir için ana özelliklerden birisidir. Verilen isim ve parametre sayilari bolme isareti (/) ile birleştirilir, `++/2` gibi. Bundan ileride bahsedecegiz; simdilik bu kadarini anlamaniz yeterlidir.


### Liste Ayrıştırma/Çıkarma

Ayırma/çıkarma işlemi `--/2` operatöru ile sağlanır; listede olmayan bir değeri çıkarmak dahi bir probleme yol açmayacaktır:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Birden fazla aynı değerin oldugu koşullara dikkat edilmesi gerekir. Çıkarma işleminin sağındaki her değer için, çıkarma işleminin solundaki listeden sadece ilk uyuşan değer çıkartılır.

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Not:** Bu işlemde [katı kıyaslama (strict comparison)](../basics/#comparison) kullanılır. Örneğin

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Baş / Kuyruk (Head / Tail)

Listeleri kullanırken genelde listenin başıyla veya kuyruğuyla değişiklik yapılabilmektedir. Baş, listenin ilk değeri iken, kuyruk kısmı geriye kalan tüm kısımdır. Elixir bunlarla oynamak için iki yardımcı yöntem sunmaktadir, `hd` ve `tl`:

```elixir
iex> hd [3.14, :kek, "Elma"]
3.14
iex> tl [3.14, :kek, "Elma"]
[:kek, "Elma"]
```

Bunlara ek olarak, listeyi baş ve kuyruk olarak ayırmak icin, [desen eşleştirmesi (Pattern Matching)](../pattern-matching/) ve `|` operatöru kullanılabilir. Bunları ileride daha detayli bir şekilde inceleyeceğiz.

```elixir
iex> [h|t] = [3.14, :kek, "Elma"]
[3.14, :kek, "Elma"]
iex> h
3.14
iex> t
[:kek, "Elma"]
```

## Demetler (Tuples)

Demetler de listeler gibidir, fakat hafızada bitişik olarak saklanılırlar. Bu, onun uzunluğunu ölçmesini hızlı yapar fakat degisiklik yapmak zordur; yeni bir işlem için hafızadan tamamen kopyalanmalıdır. Demetler süslü parantezler ile tanımlanır.

```elixir
iex> {3.14, :kek, "Elma"}
{3.14, :kek, "Elma"}
```

Demetlerin fonksiyonlardan ek bilgi döndürme mekanizmasi olarak kullanılması yaygındır; bunun faydalarını [desen eşleştirmesi - Pattern Matching](../pattern-matching/) konusunda inceleyeceğiz.

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Anahtar Kelime Listeleri (Keyword lists)

Elixir'de anahtar kelimeler (keywords) ve listeler (lists) ilişkili koleksiyonlardır. Elixirde, bir anahtar kelime listesi özel bir 2 elemanlı demet listesi ki onun ilk elemanı bir atom; onlar listelerle aynı performansı paylaşırlar:

```elixir
iex> [foo: "bar", merhaba: "dunya"]
[foo: "bar", merhaba: "dunya"]
iex> [{:foo, "bar"}, {:merhaba, "dunya"}]
[foo: "bar", merhaba: "dunya"]
```

Anahtar listelerinin önemini belli eden 3 ana özelliği vardır:

+ Anahtarlar bir atomdur.
+ Anahtarlar sıralıdır.
+ Anahtarlar tekil/eşsiz değildir.

Bu nedenle anahtar listeleri genellikle fonksiyonların argümanları olarak verilmek için kullanilir.

## Haritalar (Maps)

Haritalar Elixir'de bir diger anahtar-değer eşleşmesinin olduğu yerlerdir. Anahtar kelime olarak herhangi bir tipi kabul eder, ve onlar sıralı değildir. Haritaları `%{}` sözdizimi ile tanımlayabilirsiniz.

```elixir
iex> map = %{:foo => "bar", "merhaba" => :dunya}
%{:foo => "bar", "merhaba" => :dunya}
iex> map[:foo]
"bar"
iex> map["merhaba"]
:dunya
```

Elixir 1.2 ile birlikte değişkenlerin harita anahtarı olarak kullanılmasına olanak sağlanmıştır:

```elixir
iex> key = "merhaba"
"merhaba"
iex> %{key => "dunya"}
%{"merhaba" => "dunya"}
```

Eğer aynı değer haritaya eklenirse, eski değerin yerine geçer:

```elixir
iex> %{:foo => "bar", :foo => "merhaba dunya"}
%{foo: "merhaba dunya"}
```

Yukarıdaki çıktıdan görüldüğü kadarıyla, sadece anahtarları atom olan haritalar için özel bir sözdizimi vardır:

```elixir
iex> %{foo: "bar", merhaba: "dunya"}
%{foo: "bar", merhaba: "dunya"}

iex> %{foo: "bar", merhaba: "dunya"} == %{:foo => "bar", :merhaba => "dunya"}
true
```

Ayrıca, atom anahtarlara ulaşmak için özel bir sözdizimi vardır:

```elixir
iex> map = %{foo: "bar", merhaba: "world"}
%{foo: "bar", merhaba: "world"}
iex> map.merhaba
"world"
```

Haritaların bir diğer özelliği ise onların değiştirilmesinin için olanak sağlamasıdır:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```
