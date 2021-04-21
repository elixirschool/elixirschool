%{
  version: "1.1.1",
  title: "Test Yapmak",
  excerpt: """
  Test, yazılım geliştirmenin önemli bir parçasıdır. Bu derste `ExUnit` ile Elixir kodumuzu nasıl test edeceğimize bakacağız ve bu konuda bazı ipuçları vereceğiz.
  """
}
---

## ExUnit

Elixir'in yerleşik olarak gelen test framework'u ExUnit'tir ve kodumuzu iyice test etmek için ihtiyacımız olan her şeyi içerir. Devam etmeden önce testlerin Elixir betikleri üzerinde çalıştığını unutmamak gerekiyor. `.exs` dosya uzantısını kullanmaya özen gösterelim. Testlerimizi yapabilmemiz için önce ExUnit'i `ExUnit.start()` ile başlatmamız gerekiyor, bu genellikle test / test_helper.exs`de yapılır.

Örnek projemizi önceki derste oluşturduğumuz zaman, mix bizim için basit bir test oluşturacak kadar yardımcı olmuştu, `test/example_test.exs` bakacak olursak:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

Projemizin testlerini `mix test` ile çalıştırabiliriz. Bunu şimdi yaparsak şuna benzer bir çıktı görmeliyiz:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

Çıktıda neden iki test sonucu var? Şimdi `lib/example.ex` 'e bakalım. Mix bizim için başka bir test oluşturdu, bazı doctest'ler vs.

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### assert

Daha önce testler yazdıysanız, `assert` ile tanışıyorsunuz demektir; bazı frameworklerde `assert` yerine `should` yada `expect` kullanıyor.

İfadenin doğru olduğunu test etmek için `assert` kullanıyoruz. Kullanmadığımız takdirde, bir hata ortaya çıkacağından dolayı testlerimiz başarısız olur. Bir hatayı test etmek için, örneğimizi değiştirelim ve ardından tekrar `mix test` 'i çalıştıralım:


```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

Şimdi çıktının farklı bir çeşidini görmeliyiz:

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

ExUnit bize, başarısız olduğumuz olayın tam olarak nerede olduğunu, beklenen değerin tam olarak ne olduğunu ve gerçek değerin ne olduğunu söyleyecektir.

### refute

`refute`, `assert` yapmak  “değilse” ifadesi ise “iddi” anlamına gelir. Bir ifadenin her zaman yanlış olmasını sağlamak istediğinizde `refute` ü kullanın.

`refute` is to `assert` as `unless` is to `if`. 

### assert_raise

Bazen bir hata oluşturmamız gerekebilir. Bunu `assert_raise` ile yapabiliriz. Bir sonraki derste `assert_raise` örneğini göreceğiz.

### assert_receive

Elixir'de, uygulamalar birbirlerine mesaj gönderen aktörlerden/süreçlerden oluşur, bu yüzden genellikle gönderilen mesajları test etmek istersiniz. ExUnit kendi işleminde çalıştığı için, herhangi bir başka süreç gibi mesaj/mesajlar alabilir ve `assert_received` ile bunu yapabilirsiniz:

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received`, mesajları beklemez, `assert_received` ile bir zaman aşımı belirtebilirsiniz.

### capture_io and capture_log

Bir uygulamanın çıktısını almak, orijinal uygulamayı değiştirmeden `ExUnit.CaptureIO` ile mümkündür. Sadece çıktıyı üretecek olan işlevi iletin:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog`, ` Logger` için çıktı yakalama eşdeğeridir.

## Test Kurulumu

Bazı durumlarda, testlerimizden önce kurulum yapmamız gerekebilir. Bunu başarmak için `setup` ve `setup_all` kullanabiliriz.

`setup` ile `setup_all` komutlarının arasında ki fark: setup_all sadece 1 kez çalışır, setup ise her testten önce çalışır. `{: Ok, state}` demetini döndürmesi bekleniyor.

Örneğin, `setup_all` işlevini kullanmak için kodumuzu değiştireceğiz:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## Mocking

Elixir’de Mocking yapmanın en basit hali Mocking yapmamaktır. İç güdüsel olarak Mocking yapmak isteyebilirsiniz ancak Elixir topluluğu makul sebepler ile kullanılmasını önermiyor.

Daha uzun bir tartışma için şu şekilde [mükemmel bir makale](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/) var, test için bağımlılıkları Mock etmek yerine (bir *fiil* ile Mock etmek), Uygulamanız dışındaki kodlar için açık bir şekilde arayüzleri tanımlamanın avantajını göreceksiniz.

Uygulama kodunu, uygulama kodunuzda değiştirmek için tercih edilen yol, modülü argüman olarak iletmek ve bir varsayılan değer kullanmaktır. Bu işe yaramazsa, yerleşik yapılandırma mekanizmasını kullanın. Bu kısmi uygulamaları oluşturmak için özel bir mocking kütüphanesine, sadece davranışlara ve geri çağrılara(callbacks) ihtiyacınız yoktur.
