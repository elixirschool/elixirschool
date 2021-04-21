---
version: 1.4.0
title: Enum
---

Koleksiyonlarin numaralandirilmasi icin kullanilan sabit degerler algoritmalari.

{% include toc.html %}

## Enum

`Enum` modulu 70'ten fazla fonksiyon icerir. Bunlar daha once inceledigimiz [koleksiyonlar](../collections/) ile calismak icin kullanilir.

Bu ders mevcut olan fonksiyonlarin sadece bir kismini icerecektir fakat bunlari asagidaki method ile inceleyebiliriz.
Gelin interaktif elixir modunda (IEx) bir deneme yapalim.


```elixir
iex
iex> Enum.__info__(:functions) |> Enum.each(fn({function, arity}) ->
...>   IO.puts "#{function}/#{arity}"
...> end)
all?/1
all?/2
any?/1
any?/2
at/2
at/3
...
```

Yukaridaki methodu IEx'te calistirdiginizda, yukarida bir kismini gordugunuz enum fonksiyonlarinin listesini,
muazzam bir sekilde organize edilmis, fonksiyonel methodlari goreceksiniz. Bunun bir nedeni mevcut, o da numaralandirmanin (enumaration)
fonksiyonel programlamanin cekirdegini olusturmasi ve inanilmaz derece kullanisli olmasidir.

Elixir'in de avantajlari ile birlesip gelistiricilere inanilmaz bir guc vermektedir.

Tum fonksiyon listesi icin resmi dokumana [`Enum`](http://elixir-lang.org/docs/stable/elixir/Enum.html) goz atabilirsiniz.
Lazy enumeration icin bu [`Stream`](http://elixir-lang.org/docs/stable/elixir/Stream.html) sayfaya goz atabilirsiniz.


### all?

Diger bircok `Enum` fonksiyonunda oldugu gibi `all?/2` kullanirken de, tum koleksiyonu bir fonksiyon baglariz.  
`all?/2` kullanildiginda, tum koleksiyon elemanlarini kosula uydugunda dogru `true`, uymuyorsa yanlis `false` donecektir.


```elixir
iex> Enum.all?(["pire", "deve", "merhaba"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["pire", "deve", "merhaba"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Yukaridakinin aksine, `any?/2` herhangibir deger kosula uyuyorsa `true` donecektir

```elixir
iex> Enum.any?(["pire", "deve", "merhaba"], fn(s) -> String.length(s) == 7 end)
true
```

### chunk_every

Eger koleksiyonu kucuk parcalara bolmek isterseniz, `chunk_every/2` yardiminiza yetisecektir:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

`chunk_every/4` icin birkac farkli ozellik daha var fakat onlari incelemeyecegiz, buradan inceleyebilirsiniz [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4).

### chunk_by

Eger koleksiyonu buyukluk olarak degilde baska bir sekilde gruplamak istersek, `chunk_by/2` methodu kullanilabilir.
Bu metod verilen degerleri ve fonksiyonu alir, ve fonksiyonun dondurdugu deger degistinde yeni grup yaratip bir digerinin olusturulmasina gecer.

Asagida "bir" ve "iki"nin karakter uzunlugu (string.length) 3 iken, "uc"un uzunlugu 2dir, boylece ilk iki sayi bir grup olusturken, ucuncusu yeni bir grup olusturur.
Yine "dort", "uc"un uzunlugundan farkli oldugu icin, yeni bir gruptadir...

```elixir
iex> Enum.chunk_by(["bir", "iki", "uc", "dort", "bes"], fn(x) -> String.length(x) end)
[["bir", "iki"], ["uc"], ["dort"], ["bes"]]
iex> Enum.chunk_by(["bir", "iki", "uc", "dort", "bes", "alti"], fn(x) -> String.length(x) end)
[["bir", "iki"], ["uc"], ["dort"], ["bes"], ["alti"]]
```

### map_every

Bazen koleksiyonu kucuk parcalara basitce ayirmak isimize yaramayabilir. Bu durumda `map_every/3` her `n inci` degeri yakalamak icin
secici bir yontemdir ve kullanisli olabilir. Asagida her ucuncu (ikinci parametre) degere 1000 ekliyoruz.

```elixir
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

Bazen de koleksiyondaki tum degerlere yeni bir deger olusturmadan ulasmak istenir; bu durumda `each/2` kullanilir.


```elixir
iex> Enum.each(["bir", "iki", "uc"], fn(s) -> IO.puts(s) end)
bir
iki
uc
:ok
```

__Not__: `each/2` methodu sonda `:ok` atomu da donmektedir.

### map

Herbir degere bir fonksiyon uygulamak icin `map/2` fonksiyonunu kullaniriz.

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` koleksiyondaki en kucuk `min` degerini bulur:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` de ayni isi yapar, fakat bize bir fonksiyon ile en kucuk degere ulasmamiza izin verir;

```elixir
iex> Enum.min([], fn -> :pire end)
:pire
```

### max

`max/1` koleksiyondaki en buyuk `max` degerini bulur:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` de ayni isi yapar, `min/2` gibi, fakat bize bir fonksiyon ile en kucuk degere ulasmamiza izin verir;

```elixir
Enum.max([], fn -> :deve end)
:deve
```

### reduce

`reduce/3` ile koleksiyondaki degerler teke indirilir. Bunu yapmak icin fonksiyona gonderilecek, tercihe bagli bir deger verilir (ilk ornekte 10 verilmis);
eger bu deger verilmezse, koleksiyondaki ilk deger kullanilir.


```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Koleksiyonlari siralamaya `sort` yardimci olan bir degil iki adet siralama fonksiyonu vardir.
`sort/1` Erlang'in terim siralamasini kullanarak siralamayi olusturur.

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:pire, "deve", Enum, -1, 4])
[-1, 4, Enum, :pire, "deve"]
```

Diger secenek `sort/2` siralama icin fonksiyon kullanmamizi saglar:

```elixir
# fonksiyonla
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# fonksiyonsuz
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

`uniq_by/2` metodu koleksiyonda birden fazla tekrarlanan degerleri cikarmak icin kullanilir:

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```
