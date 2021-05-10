%{
  version: "1.1.0",
  title: "Comprehensions(Kavramlar)",
  excerpt: """
  Liste anlama kavramları, Elixir'deki numaralandırılmış metinler aracılığıyla döngü yapmak için syntactic sugar(sözdizimsel guzellik) bulunmaktadır. Bu dersimizde, iteration ve generation için bazı kavramaları nasıl kullanabildiğimizi inceleyeceğiz.
  """
}
---

## Temeller

Genellikle zaman kavramaları, 'Enum' ve 'Stream' yinelemesi için daha özlü ifadeler üretmek amacı ile kullanılabilir. Basit bir örneğe bakarak anlamaya çalışalım:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

Fark ettiğimiz ilk şey `for` ve bir generator kullanılmasıdır.  Peki generator nedir? Generator, liste kavramalarında bulunan `x <- [1, 2, 3, 4]` deyimidir. Bir sonraki değeri üretmekle sorumludur.

Neyseki bu konuda şanslıyız, generator'lar listelerle sınırlı değildir; Aslında, sayılabilir herhangi bir sayı ile çalışabileceklerdir:

```elixir
# Keyword Lists
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Elixir'deki birçok şey gibi, generator'ler de giriş kümesini sol taraf değişkeniyle karşılaştırmak için örüntü eşleştirme(pattern matching) kullanır. Bir eşleşme bulunmadığında, değer yok sayılır:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

İç içe döngüler gibi çok sayıda generator kullanmak da mümkündür:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Oluşan döngüyü daha iyi açıklamak için, üretilen iki değeri görüntülemek adına `IO.puts` komutunu kullanalım:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

Liste anlama kavramları syntactic sugar(sözdizimsel guzellik) yalnızca uygun olduğunda kullanılmalıdır.

## Filtreler

Filtreleri bir çeşit koruyucu olarak düşünebilirsiniz. Filtrelenmiş bir değer `false` veya `nil` döndürdüğünde, listeden çıkarılır. Bir aralık üzerinde duralım ve sadece sayıları düşünelim. Bir değerin eşit olup olmadığını kontrol etmek için tamsayı(Integer) modülündeki `is_even/1` fonksiyonunu kullanacağız.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

generator'lar gibi, çoklu filtreleri de kullanabiliriz. Aralığı genişletip yalnızca 3 ve 3'e eşit olarak bölünebilen değerler için filtre uygulayabiliriz.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## `:into` Kullanımı

Listeden başka bir şey üretmek istiyorsak ne yapacağız? `:Into` seçeneğini göz önüne alırsak yapabiliriz, Genel bir kural olarak, `:into`, `Collectable` protokolünü uygulayan herhangi bir yapıyı kabul edecektir.

`:into` kullanımı, haydi anahtar kelimeler için bir harita(map) oluşturalım:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

İkili dosyalar koleksiyondan oluştuğundan, Liste anlama kavramları ve `:into` dizeleri oluşturmak için kullanabilirsiniz:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

Hepsi bu kadar!
