---
version: 1.0.2
title: Mix
---

Elixirin derinliklerine girmeden önce Mix öğrenelim. Eğer daha önceden Ruby biliyorsanız Mix'i Bundeller, RubyGems ve Rake ile eşleştirin. Mix, Elixirin önemli bir parçası ve bu dersimizde sadece birkaç özelliğini öğreneceğiz. Mix'in sunduğu tüm özelliklerini görmek için `mix help` komutun çalıştırın.

Şimdiye kadar sınırlamalar içeren  `iex` ile çalıştık. Daha önemli şeyler İnşaat etmek için ve kodunuz etkili bir şekilde yönetmek için kodumuzu faklı dosyalar bölmemiz gerekir; İşte Mix bunu projelere yapmamıza izin verir.

{% include toc.html %}

## Yeni Proje

Yeni bir Elixir projesi oluşturmaya hazırsak ,Mix'in  `mix new` komutu ile kolayca oluşturabilirsiniz. Bu projenin klasör yapısını ve gerekli dosyaları oluşturur. Kullanımı oldukça basittir, haydi başlayalım:

```bash
$ mix new example
```

Çıktıda Mix'in hangi dizinleri ve dosyaları oluşturduğunu göre bilirisiniz:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

Bu derste `mix.exs`'e odaklanacağız. Burada projemizin bağımlılıklarını, ortamını ve sürümümüzü yapılandırıyoruz. .  Dosyayı favori editörünüzle açın, şöyle bir şeyle karışılacaksınız (açıklamalar kaldırılmıştır):

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

Bakacağımız ilk bölüm `project`. Burada uygulamamızın adını (`app`), sürümünü (`version`), Elixir versiyonunu (`elixir`), ve son olarak bağımlılıklarını tanımlıyoruz (`deps`).

`application` bölümü dosylarımızın oluşturulması sırasında kullanılır, bu bölümü sonra ele alacağız.

## İnteraktif


Uygulamamızı bazen `iex`'de kullanmamız gerekebilir.  Neyse ki Mix bunu kolaylaştırıyor.  Yeni bir  `iex` oturumu başlatabiliriz:

```bash
$ cd example
$ iex -S mix
```

 `iex`'i bu şekilde başlatmak uygulamamızı ve bağımlılılarını mevcut çalıştırma ortamına yükleyecektir.

## Derleme

Mix akıllıdır gerektiğinde değişikleri derleyecektir anaca yinde sizin projenizi derlemeniz gereke bilir.  bu bölümde nasıl derleme yapacağımızı ve neleri derleyeceğini öğreneceğiz.

Bir mix projesini derlemek için ana dizinde `mix compile` çalıştırmanız yeterlidir:

```bash
$ mix compile
```

projemizde çok bir şey yoktu bu yüzden verdiği çıktı pek heyecan verici değil:

```bash
Compiled lib/example.ex
Generated example app
```

Derlediğimiz Mix projemizde `_build` dizini oluşturacaktır. eğer `_build` dizinine bakarsak derlenmiş uygulamayı göreceğiz: `example.app`.

## Bağımlılık Yönetimi

Şunan için projemizde bağımlılık yok anacak kısa süre içinde olacak,  bu yüzden devam edip bağımlılıkları tanımlamayı anlatacağız.

Yeni bir bağımlılık eklemke için `mix.exs` doyasındaki  `deps` fonksiyonuna ekliyoruz.  Bağımlılık listemiz iki gerekli ve bir isteğe bağlı olan tuple içeri: paket adı atom, versiyon string  ve isteği bağlı seçenekler.

Örnek görmek için [phoenix_slim](https://github.com/doomspork/phoenix_slim) gibi bir projeye göz atalım:

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

Yukardaki bağımlılık tanımlarından da anladığımız gibi `cowboy` bağımlılığı yalnızca test ve geliştirme sırasında kullanılıyor.

Bağımlılıklarımızı tanımladığımıza göre bir adım daha atıyoruz: onları yüklüyoruz. Bu `bundle install`'a benzer:

```bash
$ mix deps.get
```

Bu kadar!  Bağımlılıklarımız ekledi ve yükledik. Artık zamanı geldiğinde bağımlılıkları eklemeye hazırız.

## Ortamlar

Mix, Bundler çok benzer ve farklı ortamları destekler. Üç ortam karışık olarak birlikte çalışır.:

+ `:dev` — Varsayılan ortam.
+ `:test` —  `mix test` tarafından kullanılır. Bir sonraki dersimizde inceleyeceğiz.
+ `:prod` — Uygulamamızı production aldığımızda kullanılır .

Geçerli ortama `Mix.env` kullanarak erişebiliriz. Beklendiği gibi `MIX_ENV` değişkeniyle ortam değiştirile bilinir:

```bash
$ MIX_ENV=prod mix compile
```
