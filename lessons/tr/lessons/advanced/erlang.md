%{
  version: "1.0.1",
  title: "Erlang'ın Çalışabilirliği",
  excerpt: """
  Erlang VM'nin (BEAM) üstüne inşa edilmenin getirdiği ek avantajlardan biriside, mevcut kütüphanelerinin bolluk içerisinde oluşudur. Çalışıla bilirlik, bu kütüphaneleri ve Erlang standart kütüphanelerini Elixir kodumuzda kullanmamızı sağlar. 

Bu dersimizde, üçüncü taraf Erlang paketleriyle birlikte standart kütüphanelerdeki fonksiyonlara nasıl erişeceğimize bakacağız.
  """
}
---

## Standart Kütüphaneler

Erlang'ın kapsamlı standart kütüphanelerine, uygulamamızdaki herhangi bir Elixir kodundan erişilebilir. Erlang modülleri, `:os` ve `:timer` gibi küçük atomlarla temsil edilir.

Belirli bir fonksiyonun çalışmasını zamanlamak için `: timer.tc` kullanalım:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

Mevcut modüllerin tam listesi için, [Erlang Referans Kılavuzu](http://erlang.org/doc/apps/stdlib/) 'na bakmanız sizin için daha iyi olacaktır.

## Erlang Paketleri

Önceki birkaç dersimizde Mix'i ve bağımlılarımızı yönetmeyi gördük. Erlang'da bulunan kütüphanelerde de aynı şekilde çalışır. Erlang kütüphanesi [Hex](https://hex.pm) 'e aktarılmamışsa, git depolarını kullanabilirsiniz:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Şimdi Erlang kütüphanemize erişebiliriz:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Önemli Farklar

Şimdi Erlang'ı nasıl kullanacağımızı biliyoruz, Erlang çalışabilirliğiyle gelen bazı tuhaflıklara da bakmamız gerekiyor. Bir takım değişiklikler olduğunu görebilirsiniz.

### Atomlar

Erlang atomları, Kolonsuz (`:`) Elixir muadillerine oldukça fazla benziyorlar. Bunlar küçük dizeleri ve alt çizgi ile temsil edilmektedir:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Dizeler(Strings)

Elixir'de dizeler hakkında konuştuğumuzda UTF-8 kodlu ikili dosyalardan bahsediyorduk. Erlang'da, dizeler hala çift tırnak ile kullanır ancak Char listelerine başvurur:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

Birçok eski Erlang kütüphanesinin ikili dosyaları desteklemeyebileceğini, dolayısıyla Elixir dizelerini direk olarak Char listelerine dönüştürmenüz gerektiğini sakın ha unutmayın. Neyse ki dönüştürme işlemlerini `to_charlist/1` fonksiyonu ile gerçekleştirmek oldukça kolay:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### Değişkenler

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

Bu kadar! Erlang'dan yararlanarak Elixir uygulamalarımıza eklemeler yaptık , bizim için mevcut olan kütüphanelerin sayısını kolay ve etkili bir şekilde iki katına çıkartmış oldu.
