%{
  version: "1.0.2",
  title: "Fonksiyonlar",
  excerpt: """
  Elixir ve bir çok fonksiyonel dilde fonksiyonlar birinci sınıf üyedir.   Elixir'de bulunan fonksiyon çeşitlerini, farklılıklarını ve nasıl kullanacaklarını öğreneceğiz.
  """
}
---

## Anonim Fonksiyonlar

Adından da anladığımız gibi bu fonksiyonlara bir ad tanımlanmaz. `Enum` dersinde de gördüğünüz gibi bu fonksiyonlar genellikle başka bir fonksiyona geçirilir. Elixir de anonim fonksiyon oluşturmak için `fn` ve `end` anahtar kelimelerine ihtiyacımız var. Bu anahtar kelimelerin içine `->` ile ayarlayarak herhangi bir sayıda parametre ve  fonksiyonun gövdesini tanımlaya biliriz.

Şimdi basit bir örneği inceleyelim:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### & İle Kısa Yazımı

Elixirde anonim fonksiyonlar yaygın olarak olarak kullanılır ve anonim fonksiyonları şu şekilde kolayca tanımlaya biliriz:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Sizin de tahmin ettiğiniz gibi yöntemde de parametreler `&1`, `&2`, `&3` şeklinde tanımlanır.

##  Desen (Pattern) Eşleme

Elixir'de desen eşleme değişkenlerle sınırlı değildir, göreceğiniz gibi bir fonksiyonun adına da uygulana bilinir.

Elixir karşılık gelen gövdeyi ve parametreleri bulmak için desen eşlemesi kullanır:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## Adlandırılmış Fonksiyonlar

Bu fonksiyonlara isim tanımlaya bilir ve daha sonra gerekli olduğunda kolayca çağıra biliriz.  Adlandırılmış bir fonksiyon tanımlamak için  `def` kullanılır . Şuan için adlandırılmış fonksiyonları ele alacağız, Modülleri bir sonraki ders inceleyeceğiz.

Bir modülde tanımlanmış fonksiyonlar başka modüller tarafında da kullanılır. Bu Elixir'in yararlı özelliklerinden birisidir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Eğer bir fonksiyonun gövdesi tek satırdan oluşuyor ise `do:` ile daha kısa şekilde yaza biliriz:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Desen Eşleme (Pattern Matching) bilgimizi ve adlandırılmış fonksiyonları kullanarak özyinelemeyi (recursion) keşfedelim:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Fonksiyon isimlendirme ve Argüman Sayısı

Daha öncede belirttiğimiz gibi fonksiyonlar adı ve argüman sayısı kombinasyonu ile isimlendirilirler. Buda size şunun gibi bir şey yapma imkanı sunar:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```
Fonksiyon isimleri yukarda sıralanmıştır.  İlk kullanımda herhangi bir argüman almadığından `hello/0` olarak bilinir. İkincisi ise bir argüman alır ve `hello/1` olarak bilir. İsimlendirme bu şekilde devam eder. Diğer dillerin aksine burada hepsi farklı fonksiyon olarak kabul edilir. (Pattern matching, described just a moment ago, applies only when multiple definitions are provided for function definitions with the _same_ number of arguments.)

### Özel Fonksiyonlar
Belli bir fonksiyona diğer modüller tarafından erişmesini istemiyorsak `defp` ile özel fonksiyonlarımız tanımlaya biliriz. Özel fonksiyonlar sadece kendi modülleri tarafında çağrıla bilinir.


```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Kontroller

Kontrolleri [Kontrol Yapıları](../control-structures) dersinde kısaca inceledik, şimdi adlandırılmış fonksiyonlarda nasıl kullanılacağını göreceğiz.   Elixir fonksiyonu bulduktan sonra kontrolleri test edecek.

Aşağıdaki örnekte aynı ada ve argüman sayısına ait iki fonksiyona sahibiz, hangisinin kullanılacağını belirlemek için kontrolleri kullanıyoruz:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Varsayılan Argümanlar Değeri

Eğer bir argüman için varsayılan değer tanımlanmak isteniyorsa  `argument \\ value` şeklinde tanımlanır:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

Fonksiyonlarda kontrolleri ve varsayılan değerleri birlikte kullanıldığında hata ile karşılaşırız. Nasıl göründüğüne bakalım:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir  birden fazla aynı isimde fonksiyon varsa varsayılan değerlerden hoşlanmaz ve hataya sebep olabilir. Bunu kullana bilmek için varsayılan değer ile bir fonksiyon başlığı tanımlıyoruz:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
