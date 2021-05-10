%{
  version: "1.2.1",
  title: "Modüller",
  excerpt: """
  Bu zaman kadar ki derslerimiz de fonksiyonları aynı dosya ve alanda tanımladık. In this lesson we're going to cover how to group functions and define a specialized map in a struct in order to organize our code more efficiently.
  """
}
---

## Modüller

Modüller, fonksiyonları bir isim namespace da organize etmemizi sağlar. Bunlara ek olarak [fonksiyonlar dersinde](../functions/).  adlandırılmış ve özel fonksiyonları tanımlamamıza izin verir.

Basit bir örneğe bakalım:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Elixir'de kodunuzu modüllerin içine eklemeniz namespacesinizi daha efektif kullanmanızı sağlar.
Elixir
```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### Modül Nitelikleri (Attributes)

Elixir'de nitelikleri sıklıkla kullanılır. Basit bir örneğe bakalım:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Elixir'de bazı niteliklerin özel olarak ayrıldığını belirmekte fayda var.  En yaygın 3 tanesi:

+ `moduledoc` — Geçerli modüle ait dokümanlar.
+ `doc` — Fonksiyon ve makrolar için dokümanlar
+ `behaviour` — OTP veya kullanıcı tanımlı davranış için kullanma.

## Yapılarlar (Structs)

Yapılar anahtar kelime ve varsayılan değerlerinden oluşan özel haritalardır. Yapının adını alacağı bir modül içne tanımlanmalıdır.  Modül içinde yapı tek başına tanımlanması yaygın bir kullanımdır.

Yapı tanımlamak için  `defstruct`  ile birlikte anahtar kelime listesi ve varsayılan değerleri ile birlikte kullanırız :

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Yapılar yaratalım:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Yapıyı tıpkı bir harita gibi güncelleyebiliriz:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

En önemlisi haritalarla yapılara erişebilirsiniz:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

## Birleştirme (Composition)

Artık modülleri ve ve yapıları nasıl oluşturacağımız biliyoruz, Birleştirme yolu ile farklı fonksiyonellikleri nasıl ekleyeceğimizi öğrenelim.  Elixir diğer modüllerle etkileşime girmek için farklı yöntemler sunar.

### `alias`

Modülere takma adlar tanımlamamıza izin veriri ve bu Elixir'de sıkça kullanılır:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Takma ad olmadan

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Mükerrer takma ad varsa veya tamamen farklı bir ad verilmek isteniyorsa `:as` seçeneği kullanıla bilinir:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Aynı anda birden fazla modüle takma ad vermekte de mümkündür:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

If we want to import functions and macros rather than aliasing the module we can use `import/`:
Eğer takma ad kullanmak yerine fonksiyon ve makroları eklemek isterseniz `import/` kullana biliriniz:
```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtreleme

Varsayılana olarak tüm fonksiyon ve makrolar içeri aktarılır anacak  `:only` ve `:except` kullanarak filtreleye bilirsiniz.

Belirli fonksiyonları ve makroları aktarmak için `:only` ve `:except` kullanırken name/arity (argüman sayısın) kullanmamız gerekiyor.  Şimdi `last/1` fonksiyonunu içe aktararak başlayalım:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Eğer `last/1` dışında her şeyi eklemek istiyorsak:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Name/arity'e ek olarak sadece fonksiyon yada makroları çağırmak için 2 adet `:functions` ve `:macros` atomları bulunmaktadır:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

`require/2` çok sık kullanılmasada önemlidir. Bir modül gerekirse onun derlenmesini ve yüklenmesini sağlar. Bir modülün makrolarına erişmeye çalışıtığımızda kolaylık sağlar:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Henüz yüklenmemiş bir makro çağırmaya kalkarsak, Elixir hata mesajı verir.

### `use`

`use` makrosu ile başka bir modülün mevcut modül tanımımızı değiştirmesini sağlayabiliriz.
Kodumuzdaki `use` fonksiyonunu çağırdığımızda, sağlanan bu modül tarafından tanımlanan  `__using__/1`  callback gerçekleştirilir.
`__using__/1` makrosunun sonucu modülün tanımının bir parçası haline gelir.

Bunun nasıl işlediğini daha iyi anlamak için örneğe göz atalım:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Burada bir `hello/1`  fonksiyonu tanımladığımızda `__using__/1` bize callback tanımlayan bir `Hello` modülü oluşturduk.
Şimdi kodumuzu denemek için yeni bir kod oluşturalım:

```elixir
defmodule Example do
  use Hello
end
```

Kodumuzu IEx'de denersek, `hello/1` öğesinin `Example` modülünde mevcut olduğunu göreceğiz:

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```
Burada ise, `Hello` modülü üzerinde  `__using__/1` callback yaptığını görebiliriz ve sonuçta oluşan kod modülize edilmiş olur.
Basit bir örnek gösterdik, `__using __ / 1`’in seçenekleri nasıl desteklediğine bakmak için kodumuzu güncelleyelim.
Bunu greeting seçeneği ekleyerek uygulayacağız:

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

`Example` modülünü `greeting` seçeneğini içerecek şekilde güncelleyelim:


```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

IEx komut satırın `greeting` kullanırsak komut aşağıdaki gibi değişiklik gösterir :

```
iex> Example.hello("Sean")
"Hola, Sean"
```

Bu gösterilenler, kullanımın nasıl çalıştığını gösteren en basit örneklerdir, ancak `use` Elixir araç kutusundaki en güçlü araçlardan biridir.
Elixir'i öğrenmeye devam ederken `use` modülüne göz kulak olun, öğrenmeye devam ederken mutlaka göreceğiniz örneklerden biride `use ExUnit.Case, async: true`

**Not**: [Meta programalmada](../../advanced/metaprogramming) kullanılan makrolar : `quote`, `alias`, `use`, `require` .
