%{
  version: "1.0.3",
  title: "Belgelendirme",
  excerpt: """
  Elixir kodunun belgelendirilmesi.
  """
}
---

## Bilgi Notu

Nekadar yorum yapmamız ve belgeyi kaliteli yapan şeyler programlama dünyasının tartışmalı konularıdır. Bunula birlikte belgelendirme kendimiz ve kodlarımız ile çalışsanlar için önemli olduğunu kabul etmeliyiz.

Elixir belgelere *birinci sınıf vatandaş* olarak davranıyor ve projeleriniz belgelendirmeniz ve belgelere ulaşmanız için çeşitli fonksiyonlar sunuyor. Şimdi bunun 3 yolunu inceleyelim:


  - `#` - Satır içi belgelendirme için.
  - `@moduledoc` - Modül seviyesinde belgelendirme yapmak için.
  - `@doc` - Fonksiyon seviyesinde belgelendirme yapmak için.

### Satır İçi Belgelendirme

Muhtemlen kodunuzu yorumlamanın en kolay yolu satır içi  yorumlamadır.  Elixirde de satır içi yorumlar Python veya Ruby'e benzer şekilde `#` *diyez*, *pound*, veya *hash* (Dünya üzerinde bulunduğunuz yeregöre değişiklik gösterecektir) kullanılarak yapılır.

Şu Elixir Scriptini ele alalım (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

Elixir bu betiği çalıştırırken `#` den başlayarak satır sonuna kadar olan her şeyi kod olarak kabul etmez. Yorumlarınız kodun çalışması sırasında bir performans sorunu yaratmaz anaca diğer programcılar için anlaşılır olacak şekilde yazılmalıdır.Tek satır yorumları kötüye kullanmamaya dikkat edin! Kodunuzdaki çöp yığını kabus haline gelebilir.Ölçülü kullanmaya dikkat edin.

### Modülleri Belgelendirme

`@moduledoc` modül düzeyinde satır içi belgelendirmeye izin verir. Genellikle `defmodule` tanımın hemen altında bulunur. Aşağıdaki örnekte `@moduledoc` dekoretörüyle bir satırlık yorum görülmektedir.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Biz veya diğer insanlar IEx içinde  `h` yardımcı fonksiyonu ile bu modül belgelerine erişe bilirler.

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### Fonksiyon Belgelendirme

Bu arada modüllere benzer bir belgelendirme yöntemi söz konusu . `@doc` fonksiyonlarda satır için belgelendirmeye izin verir. `@doc`dekoratörü açıklamanın hemen önünde bulunur.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Tekrar IEx'e dönersek yardımcı komut (`h`) modül içindeki fonksiyon için şöyle kullanılır :

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Belgelendirmelerimizde noktalma işaretlerini nasıl kullanacağımız ve bunları terminalin nasıl yorumladığını fark ettiniz mi? Apart from really being cool and a novel addition to Elixir's vast ecosystem, it gets much more interesting when we look at ExDoc to generate HTML documentation on the fly.

**Not:**  `@spec` veri tiplerinin statik tanımları için kullanılır. Daha fazla bilgi almak istiyorsanız [Specifications and types](../../advanced/typespec) dersine göz atın.

## ExDoc

ExDoc projesi [GitHub'da](https://github.com/elixir-lang/ex_doc) bulunan resmi bir Elixir prjesidir. Elixir projeleri için  **HTML (HyperText Markup Language) ve çevrim içi**  belgeler oluşturur. Öncelikle bir Mix projesi oluşturalım:

```bash
$ mix new greet_everyone

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Şimdi önceki `@doc` dersindeki kodu  `lib/greeter.ex` adlı dosyaya kopyalayıp yapıştırın ve her şeyin halen çalışır durumda olduğunda emin olun . Artık bir Mix projesinden çalışıyoruz, IEx'i `iex -S mix` komutunu kullanarak biraz farklı bir şekilde başlatıyoruz:

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Kurulum

Herşey doğru ise yukardakine benzer bir çıktı alıyoruz, şimdi ExDoc kurmaya hazırız. Başlangıç için  `mix.exs` dosyasına bağımlılıklarımız ekleyelim: `:earmark` ve `:ex_doc`.

```elixir
  def deps do
    [{:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
```

Bu bağımlılıkları üretim ortamında (production environment) kurmamak için  `only: :dev` anahtar/değer çiftini ekleyin. Peki neden Earmark? Earmark, ExDoc'un `@moduledoc` ve `@doc` içindeki belgelerimizi güzel görünümlü HTML'ye çevirmek için kullandığı Elixir programlama dili için bir Markdown ayrıştırıcısıdır (parser). 

Bu noktada Earmark kullanmak zorunda olmadığımız belirtmekte fayda var. Pandoc, Hoedown, or Cmark gibi başkalarıyla değiştire bilirsiniz; [Burada](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool) okuyacağınız birkaç küçük konfigrasyonu daha yapmanız gerekecek. Biz Earmark kullanmaya devam edeceğiz.

### Belgelerin Oluşturulması

Devam ediyoruz, hala açık olan terminalde aşağıdaki iki komutu çalıştırın:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

eğer her şey planlandığı gibi olduysa, yukarıdaki gibi bir çıktı alacaksınız. Artık projemizde  **doc/** adında yeni bir dizin olduğunu görmeliyiz. Üretilen belgelerimiz buranın içindedir. Eğer dizine taracımız ile ziyaret edersek aşağıdakiler gibi bir sayfa karşılayacak bizi:

![ExDoc Screenshot 1]({% asset documentation_1.png @path %})

Earmark'ın belgelerimizden Markdown oluşturduğunu ve ExDoc'un bunu daha okunabilir olarak olarak gösterdiğini görüyoruz.

![ExDoc Screenshot 2]({% asset documentation_2.png @path %})

Artık bunu GitHu'da, kendi sitemizde veya [HexDocs'da](https://hexdocs.pm/) yayınlaya biliriz.

## En iyi Uygulama

Belgelendirme dilin kurallarına göre yapılmalıdır. Elixir oldukça genç bir dil olduğundan, ekosistem büyüdükçe yeni standartlar keşfedilmeye devam edecektir. Bununla birlikte topluluk en iyi kullanım metodlarını belirlemeye çalıştı. TDaha fazla bilgi için [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide) göz atın.

  - Her zaman modülleri belgelendirin.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Eğer bir modülü belgelendirmeyi düşünmüyorsanız, boş **bırakmıyın** . Modüle `false` ile yorum bırakın , tıpkı şöyle:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Modül belgelerinde fonksiyonlara atıfta bulunmak isterseniz şu  şekilde ters tırnak kullanın:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 -  `@moduledoc` altındaki kodları bir satır ile ayırın:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Dokümanlarınız da Markdown kullanın. Bu IEx veya ExDoc aracılığı ile belgelerinizi okumanızı kolaylaştıracaktır.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Belgelerinize bazı kod örnekleri eklemeye çalışın. Bu da modüle, fonksiyona veya bir makroda bulunan kod örneklerinde [ExUnit.DocTest][] ile otomatik testler oluşturmamıza olanak sağlar. Bunu yapmak için, `doctest / 1` makrosunu çağırmanız ve örnekleriniz [ExUnit.DocTest] [resmi belgelerinde] ayrıntılı olarak belirtilen bazı yönergelere göre yazmanız gerekir.
[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
