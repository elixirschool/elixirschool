%{
  version: "1.0.1",
  title: "Hata işleme",
  excerpt: """
  `{:error, reason}` demet'inin kullanımı daha yaygın olmasına rağmen, Elixir bir takım istisnaları'da desteklemektedir. Bu derste bahsettiğimiz istisnaların neler olduğuna  göz atacağız.

Bu ders ile standart kullanım dışında kalan hata yakalamalarına değineceğiz.
  """
}
---

## Hata işleme

Hataları işleyebilmemiz için bu hataları oluşturmamız gerekiyor ve bunu yapmanın en basit yolu `raise/1` fonksiyonudur:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Eğer tipi ve mesajı belirtmek istiyorsak `raise/2` fonksiyonunu kullanmalıyız:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Bir hatanın meydana gelebileceğini bildiğimiz zaman, `try/rescue` ve desen eşleştirmesi(pattern matching) ile neler olup bittiğine bakabilirsiz:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Tek bir `rescue` ile birden fazla hatayı yakalayabilmek mümkündür:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

Bazen, hatadan bağımsız olarak `try/rescue` fonksiyonumuzdan sonra bir miktar işlem yapmamız gerekebilir. İşte bunun için `try/after` var.  Ruby'ye aşina iseniz, bu, `begin/rescue/ensure` ya da Java'da ki `try/catch/finally` türevlerine benzer:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Bu, kapatılması gereken dosyalarda ve/veya bağlantılarda kullanılır:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## New Errors

Elixir yerleşik olarak, `RuntimeError` gibi bir çok hata türünü içeriyor olsa da, belirli bir şeye ihtiyacımız varsa, kendi hata yakalama durumumuzu belirtmemiz gerekir. Varsayılan hata mesajını ayarlamak için `:message` seçeneğini rahatça kabul eden `defexception/1` fonksiyonu ile yeni bir hata mesajı oluşturmak aşağıdaki gibidir ve kolaydır:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Şimdi oluşturduğumuz bu yeni hatamızı kullanalım.

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throws

Elixir'deki hatalarla çalışmak için başka bir mekanizma olarak da `throw` ve `catch` kullanabilirsiniz. Pratikte, bunlar daha yeni Elixir kodlarında kullanılır ve çok seyrek görülür, fakat yine de bunları bilmek ve gerekti zaman kullanmak işlerinizi oldukça kolaylaştıracaktır.

`throw/1` fonksiyonu bize, `catch` yapabileceğimiz ve kullanabileceğimiz belirli bir değerle yürütmeden çıkma yeteneği verir:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Bahsedildiği gibi, `throw/catch` oldukça nadir kullanılır ve kütüphaneler yeterli API'ları sağlamada başarısız olduklarında stopgaps(geçici) olarak bulunurlar.

## Exiting

Elixir'in bize sağladığı son hata mekanizması `exit`. Çıkış sinyalleri, bir süreç sonlandığında ortaya çıkar ve Elixir'in hata toleransının önemli bir parçasını oluşturur.

Açıkça çıkmak istediğinizi belirtmek için `exit/1` kullanabilirsiniz:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

`try/catch` ile çıkış yapmak mümkün olsa da, kullanımı _oldukça_ nadirdir. Hemen hemen her durumda, denetim otoritesinin süreç çıkışını ele alması avantajlıdır:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
