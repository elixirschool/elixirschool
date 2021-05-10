%{
  version: "1.0.1",
  title: "Özel Mix Görevleri",
  excerpt: """
  Elixir projeleriniz için özel Mix görevleri oluşturma.
  """
}
---

## Giriş

Özel Mix görevlerini ekleyerek Elixir uygulamalarınızın işlevselliğini genişletmek genellikle kullanılan bir özelliktir.
Projelerimiz için özel Mix görevlerinin nasıl oluşturulacağını öğrenmeden önce hali hazırda var olan bir projeye bakalım:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Yukarıdaki kabuk komutundan da görebileceğimiz gibi, Phoenix Framework'ünün yeni bir proje oluşturmak için özel bir Mix görevi vardır. Ya biz kendi projemiz için benzer bir şey oluşturmak istersek? İyi haber, Elixir bunu bizim için kolaylaştırıyor.

## Kurulum

Şimdi basit bir Mix projesi oluşturalım.

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Şimdi, Bizim için Mix tarafından oluşturulan  **lib/hello.ex** dosyaya, basit "Hello, World!" çıktısı veren bir fonksiyon oluşturalım.

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Özel Mix Görevi

Şimdi özel Mix görevimizi oluşturalım. Yeni bir dizin ve dosya oluşturalım **hello/lib/mix/tasks/hello.ex**. Bu dosyaya 7 satırlık Elixir kodumuzu ekleyelim.

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Defmodule fonksiyonunu `Mix.Tasks` ve komut satırından çağırmak  istediğimiz isim ile başlattığımıza dikkat edin.İkinci satırda `Mix.Tasks` davranışını ad alanına getiren `use Mix.Task` işlevini tanımlıyoruz. Daha sonra, şu an için herhangi bir argüman almayan `run` fonksiyonunu oluşturuyoruz. Bu fonksiyonun içine de `Hello` modülünü ve `say` fonksiyonunu çağırıyoruz.


## Mix Görevlerini Çalıştırmak

Şimdi Mix görevlerimizi kontrol edelim. Proje dizininde olduğumuz sürece çalışmaları gerekiyor. Komut satırından `mix hello` komutunu çağırdığımızda aşağıdaki çıktıyı görmemiz gerekiyor:

```shell
$ mix hello
Hello, World!
```

Mix kullanımı oldukça kolaydır. Herkes tarafından yazım hatası yapabildiği için (fuzzy) bulanık string eşleşme ile bize önerilerde bulunur :

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Yeni bir özellik kullandığımızı fark ettiniz mi, `@shortdoc`? Bu uygulamamızı dağıttığımızda kullanıcılara kolaylık sağlar. Terminalde `mix help` komutunu çalıştırdığımızda komutlar hakkında kısa açıklamalar sunar.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
