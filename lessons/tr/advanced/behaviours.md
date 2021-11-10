%{
  version: "1.0.1",
  title: "Davranışlar",
  excerpt: """
  Önceki derste Typespec'leri öğrendik, burada bu özellikleri uygulamak için bir modülün nasıl kullanılabileceğini göreceğiz. Elixir'de, bu durum davranışlar olarak adlandırılır.
  """
}
---

## Kullanımları

Bazen modüllerin ortak bir API'yi paylaşmasını istersiniz, bunun için Elixir'deki çözüm davranışlardır. Davranışlar iki ana rol oynar:

+ Uygulanması gereken bir dizi fonksiyonu tanımlamak
+ Bu setin gerçekten uygulanıp uygulanmadığını kontrol etmek

Elixir, `GenServer` gibi birtakım davranışlar içerir, ancak bu derste bunu kullanmak yerine kendimiz bir adet yaratmaya odaklanacağız.

## Davranışı tanımlama

Davranışları daha iyi anlamak için bir işçi modülü için bir tane uygulayalım. Bu işçilerin iki fonksiyonu yerine getirmeleri beklenir: `init/1` ve `perform/2`

Bunu başarmak için, `@callback` direktifini, `@spec` ile benzer sözdizimiyle kullanacağız. Bu, __required__ fonksiyonunu tanımlar; `@macrocallback` kullanabiliriz. İşçilerimiz için `init/1` ve `perform/2` fonksiyonlarını belirleyelim:

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

Burada `init/1` değerini herhangi bir değeri kabul etmek ve `{: ok, state}` veya `{: error, reason}` demetini döndürmek olarak tanımladık.  `Perform / 2` fonksiyonumuz, başlattığımız durumla birlikte işçimiz için bazı argümanlar alacak, ve sonuçlandırmak için `{:ok, result, state}` veya `{:error, reason, state}` gibi durum demetlerini bekleyecek.

## Davranışları kullanma

Davranışlarımızı tanımladığımıza göre, hepsini aynı genel API'yi paylaşan çeşitli modüller oluşturmak için kullanabiliriz. Modülümüze bir davranış eklemek, `@behaviour` özniteliği ile kullanılır.

Yeni davranışımızı kullanarak, uzak bir dosyayı indirecek ve yerel olarak kaydedecek bir modül oluşturalım:

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Ya da bir dosya dizisini sıkıştıran bir işçi edinmeye çalışalım, Bu da mümkün:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Yapılan iş farklı olsa da, genele açık bir API bulunmuyor ve bu modülleri kullanan herhangi bir kod, beklendiği gibi yanıt vereceğini bilerek onlarla etkileşim kurabilir.

Bu bize, farklı görevleri yerine getiren genele açık API'sine uyan, herhangi bir sayıda işçi yaratma becerisi kazandırır.

Bir davranış ekleyeceğiz, ancak gerekli tüm fonksiyonları yerine getiremediğimizde, derleme zamanı uyarısı karşımıza çıkacak. Bu eylemi görmek için `init/1` satırını kaldırarak `Example.Compressor` kodumuzu değiştirelim:

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

Şimdi kodumuzu derlediğimizde aşağıdaki gibi bir uyarı görmeliyiz:

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

Bu kadar! Şimdi başkaları ile davranışlar paylaşmaya ve oluşturmaya hazırız.
