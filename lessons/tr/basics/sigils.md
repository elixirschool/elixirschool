%{
  version: "1.0.1",
  title: "İşaretler (Sigils)",
  excerpt: """
  İşaretlerle çalışma ve yeni işaretler oluşturma.
  """
}
---

## Genel Bilgi

Elixir provides an alternative syntax for representing and working with literals. İşaretler tilda'yıy `~` takip eden bir karakterden oluşur. Elixir bize bazı işaretleri hazır olarak sunar, bu işaretleri geliştirebiliriz ve gerektiğinde kendi dilimizi geliştirebiliriz.

Mevcut işaretlerin listesi:

  - `~C` Kaçış veya enterpolasyon **olmadan**  karakter listesi oluşturur
  - `~c` Kaçış veya enterpolasyon **ile**  karakter listesi oluşturur
  - `~R` Kaçış veya enterpolasyon **olmadan** düzenli ifade üretir
  - `~r` Kaçış veya enterpolasyon **ile** düzenli ifade üretir
  - `~S` Kaçış veya enterpolasyon **olmadan**  dizge üretir
  - `~s` Kaçış veya enterpolasyon **ile**  dizge üretir
  - `~W` Kaçış veya enterpolasyon **olmadan** kelime listesi oluşturur
  - `~w` Kaçış veya enterpolasyon **ile** kelime listesi oluşturur
  - `~N` `NaiveDateTime` yapısı üretir

Sınırlandırıcıların listesi:

  - `<...>` A pair of pointy brackets
  - `{...}` A pair of curly brackets
  - `[...]` A pair of square brackets
  - `(...)` A pair of parentheses
  - `|...|` A pair of pipes
  - `/.../` A pair of forward slashes
  - `"..."` A pair of double quotes
  - `'...'` A pair of single quotes

### Karakter Listesi

`~c` ve `~C` şaretleri yazılış sırasına göre karakter listesi oluşturur. Örneğin:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Küçük harfli işaret `~c` hesaplamayı yaparken, buna karşı büyük harfli `~C` işareti hesaplamıyor. Bu büyük / küçük dizisinin diğer işaretlerde yaygın olarak kullanıldığını göreceğiz.

### Düzenli İfadeler (Regular Expressions)

Düzenli ifadeler `~r` ve `~R` işaretleriyle ile ifade edilir. Düzenli ifade kullanım anında yada `Regex` fonksiyonu içinde kullanmak için oluşturulur. Örneğin:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

İlk basit denemede `Elixir` ifadesi ile düzenli ifade eşleşme sağlanamadı. Bunun sebebi ilk harfinin büyük olmasıdır. Elixir,  Perl Compatible Regular Expressions (PCRE) desteklediğinden, büyük/küçük harf duyarlılığını kapatmak için sona `i` ekleye biliriz.

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Elixir ayrıca Erlang [Regex](https://hexdocs.pm/elixir/Regex.html) API'sinide sağlar. Şimdi `Regex.split / 2` fonksiyonuna regex işaretlerini uygulayalım:
```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```
Gördüğümüz gibi, `` ~ r / _ / ` işareti sayesinde" "100_000_000" dizesi alt çizgi üzerinde bölünmüştür. `Regex.split` fonksiyonu bir liste döndürür.


### Dizi

`~s` ve `~S` işareti dizeler üretmek için kullanılır. Örneğin:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Arasındaki fark ne ? Aradaki fark, Daha önce incelediğimiz Karakter Listesinin işaretine benzer. Cevap, enterpolasyon ve kaçış dizilerinin kullanılmasıdır. Eğer başka bir örneğe bakarsak:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Kelime Listeleri

Kelime Listesi işareti zaman zaman kullanışlı olabilir. Hem zaman kazandırır,tuş vuruşlarını ve kod tabanındaki karmaşıklığı göreceli olarak azalttır. Basit bir örneğe bakalım:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Yazıların arasındaki boşluklardan ayırarak liste oluşturduğunu görebiliriz. bunula birlikte, bu iki örnek arasında pek bir fark yoktur.Yine, fark enterpolasyon ve kaçış dizelerinden gelmektedir.Bir örnekle devam edelim:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

[NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) saat dilimi olmadan hızlı bir şekilde `DateTime` öğesi oluşturmak için kullanılır.

Devamlı olarak doğrudan `NaiveDateTime` yapısı oluşturmaktan kaçınmalıyız. Bununla birlikte desen eşleme için oldukça  faydalıdır. Örneğin:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

## İşaretleri Oluşturma

Elixir hedeflerinden biride geliştirilebilir bir programlama dili olmasıdır. Kendinize özel işaretleri kolayca oluşturabileceğiniz sürpriz olmamalı. Bu örnekte küçük harfleri büyük harflere çevirmek için bir işaret tanımlayacağız. Bunu Elixir çekirdeğinde var olan (`String.upcase/1`) fonksiyonunu kullanarak yapacağız.

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

İlk olarak, `MySigils` adlı bir modül tanımladık ve bu modülde `sigil_u` adlı bir fonksiyon yarattık.
Mevcut işaretler arasında `~u` işareti yer almadığı için bunu kullanacağız.
`_u`, tilda işaretinden sonra karakter olarak `u`nu kullanmak istediğimizi gösterir.
Fonksiyon tanımı, bir girdi ve bir liste olmak üzere iki argüman almalıdır.
