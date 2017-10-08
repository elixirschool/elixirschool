---
version: 1.2.1
title: Kolleksiyonlar
redirect_from:
  - /lessons/basics/collections/
---

Listeler (List), Demetler (Tuples), Anahtar Kelimeler (keywords), Haritalar (maps) ve islevsel baglaclar.

{% include toc.html %}

## Listeler (Lists)

Listeler degerlerin tutuldugu basit koleksiyonlardir ve birden fazla tip icerebilirler; ve listeler tekil olmayan (non-unique) degerler icerebilirler:

```elixir
iex> [3.14, :kek, "Elma"]
[3.14, :kek, "Elma"]
```

Elixir listeleri baglantili liste (linked list) olarak isler. Bu da demektir ki liste uzunluga ulasmak bir `O(n)` islemidir. Bu nedenle tipik olarak yeni liste elemanini one eklemek, sona eklemekten daha hizlidir.


```elixir
iex> liste = [3.14, :kek, "Elma"]
[3.14, :kek, "Elma"]
iex> ["π"] ++ liste
["π", 3.14, :kek, "Elma"]
iex> liste ++ ["Kiraz"]
[3.14, :kek, "Elma", "Kiraz"]
```


### Liste Birlestirme Islemi

Liste birlestirme islemi `++/2` operatorunu kullanir:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

Yukaridaki (`++/2`) kullanimini aciklamak gerekirse; Elixir'de (ve Erlang'ta, Elixir Erlan uzerine gelistirilmistir), bir fonksiyon veya operatorun iki bileseni vardir. Birincisi verdiginiz isim (burada operator `++`) ve aldigi parametrelerin sayisi (_arity_). Islem icin alinan parametrelerin sayidir ve Elixir icin ana ozelliklerden birisidir. Verilen isim ve parametre sayilari bolme isareti (/) ile birlestirilir, `++/2` gibi. Bundan ileride bahsedecegiz; simdilik bu kadarini anlamaniz yeterlidir.


### Liste Ayristirma/Cikarma Islemi

Ayirma/cikarma islemi `--/2` operatoru ile saglanir; listede olmayan bir degeri cikarmak dahi probleme yol acmayacaktir:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Birden fazla ayni degerin oldugu kosullara dikkat edilmesi gerekir. Cikarma isleminin sagindaki her bir deger icin, cikarma isleminin solundaki listeden sadece ilk uyusan deger cikartilir.


```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Not:** Bu islemde [kati kiyaslama (strict comparison)](../basics/#comparison) kullanilir. Oyle ki bu isleme gore 2 ile 2.0 degeri ayni degildir.

```elixir
iex> [1,2.0,2.0,3,2.0,3] -- [1,2,3,2]
[2.0, 2.0, 2.0, 3]
```

### Bas / Kuyruk (Head / Tail)

Listeleri kullanirken genelde listenin basiyla ve/veya kuyruguyla degisiklik yapilabilmektedir. Bas listenin ilk degeri iken, kuyruk kismi geri kalan tum kismidir. Elixir bunlarla oynamak icin iki yardimci yontem sunmaktadir, `hd` ve `tl`


```elixir
iex> hd [3.14, :kek, "Elma"]
3.14
iex> tl [3.14, :kek, "Elma"]
[:kek, "Elma"]
```

Bunlara ek olarak, listeyi bas ve kuyruk olarak ayirmak icin, [Ornegini Bulma - Pattern Matching](../pattern-matching/) ve cubuk `|` operatoru kullanilabilir. Bunlari ileride daha detayli inceleyecegiz.

```elixir
iex> [h|t] = [3.14, :kek, "Elma"]
[3.14, :kek, "Elma"]
iex> h
3.14
iex> t
[:kek, "Elma"]
```

## Demetler (Tuples)

Demetler de listeler gibidir ve hafizada bitisik olarak saklandigi icin uzunlugunu olcmek cok hizlidir fakat degisiklik yapmak masraflidir, bu islem icin yeni demet tumuyle hafizaya kopyalanmalidir. Demetler suslu parantezler `{` `}` ile tanimlanir.

```elixir
iex> {3.14, :kek, "Elma"}
{3.14, :kek, "Elma"}
```


Demetlerin fonksiyonlardan ek bilgi dondurme mekanizmasi olarak kullanilmasi yaygindir; bunun faydalarini [Ornegini Bulma - Pattern Matching](../pattern-matching/) konusunda inceleyecegiz.

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```


## Anahtar Kelime Listeleri (Keyword lists)

Elixir'de Anahtar Kelimeler (keywords) ve haritalar (maps) ilisikli koleksiyonlardir. Yani kendi iclerinde degere ulasmak icin anahtar bulundururlar. Elixir'de anahtar kelime listesi ozel bir demet (tuple) listesidir ve ilk degeri bir atomdur (:foo gibi, kendi degerini tasiyan bir sembol diyelim)


```elixir
iex> [foo: "bar", merhaba: "dunya"]
[foo: "bar", merhaba: "dunya"]
iex> [{:foo, "bar"}, {:merhaba, "dunya"}]
[foo: "bar", merhaba: "dunya"]
```

Anahtar listelerinin onemini belli eden 3 ana ozelligi vardir:

+ Anahtarlar bir atomdur.
+ Anahtarlar siralidir.
+ Anahtarlar tekil/essiz degildir.

Bu nedenle anahtar listeleri genelde fonksiyonlarin secenekleri icin kullanilir.


## Haritalar (Maps)

Haritalar Elixir'de bir diger anahtar-deger eslesmesinin oldugu yerlerdir. Anahtar listelerine nazaran herhangibir tipte anahtari kabul ederler ve anahtarlar sirali degildir.
Haritalar `%{}` sozdizimi ile tanimlanir.


```elixir
iex> map = %{:foo => "bar", "merhaba" => :dunya}
%{:foo => "bar", "merhaba" => :dunya}
iex> map[:foo]
"bar"
iex> map["merhaba"]
:dunya
```

Elixir 1.2 ile birlikte degiskenlerin harita anahtarlari olarak kullanilmasina olanak saglanmistir.

```elixir
iex> key = "merhaba"
"merhaba"
iex> %{key => "dunya"}
%{"merhaba" => "dunya"}
```

Eger ayni deger haritaya eklenirse, eskisinin yerine gecer.

```elixir
iex> %{:foo => "bar", :foo => "merhaba dunya"}
%{foo: "merhaba dunya"}
```

Yukarida goruldugu gibi haritalarin sadece atom anahtarlari icerdigi ozel bir sozdimizi vardir.

```elixir
iex> %{foo: "bar", merhaba: "dunya"}
%{foo: "bar", merhaba: "dunya"}

iex> %{foo: "bar", merhaba: "dunya"} == %{:foo => "bar", :merhaba => "dunya"}
true
```

Haritalarin bir diger ilginc ozelligi de atom anahtarlarinin ulasilmasi/degismesi icin kendi ozel sozdizimlerini saglamalaridir.

```elixir
iex> map = %{foo: "bar", merhaba: "dunya"}
%{foo: "bar", merhaba: "dunya"}
iex> %{map | foo: "baz"}
%{foo: "baz", merhaba: "dunya"}
iex> map.merhaba
"dunya"
```
