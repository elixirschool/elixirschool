%{
  version: "1.0.1",
  title: "Yürütüle bilirlik",
  excerpt: """
  Elixir'de yürütülebilir dosyalar oluşturmak için `eskript` kullanıyor olacağız. Escript, Erlang yüklü herhangi bir sistemde çalıştırılabilen bir yürütülebilir dosya üretir.
  """
}
---

## Başlarken

Eskript ile bir yürütülebilir dosya oluşturmak için yapmamız gereken sadece ufak bir dosyayı oluşturup çalıştırmaktır: `main/1` fonksiyonunu uygulayın ve Mixfile'ınızı güncelleyin.

Uygulanabilirliğimize giriş yapabilmek için bir modül oluşturarak başlayacağız. Ve bu, ana `main/1` ’i uygulayacağımız yer şu şekilde örnek ile gösterilebilir:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

Daha sonra, projemiz için `:main_module` atomunu belirtmekle birlikte `:escript` seçeneğini dahil etmek için Mixfile dosyanızı güncellemelisiniz:

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Arg'ları Ayrıştırma

Uygulama kurulumumuzla, komut satırı argümanlarını ayrıştırmaya devam edebiliriz. Bunu yapmak için, değerin boolean olduğunu belirtmek gerekir ve Elixir' için `OptionParser.parse / 2` fonksiyonunu `: switch` seçeneği ile birlikte kullanacağız:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Oluşturma

Uygulamanızı eskript kullanmak için yapılandırdıktan hemen sonra, bizim çalıştırılabilir programımızı Mix ile birlikte aşağıdaki gibi kullanacağız.

```elixir
$ mix escript.build
```

Hadi bir örnek ile yaptıklarımıza bakalım.

```elixir
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

Bu kadar. İlk çalışmamızı eskript kullanarak Elixir'de oluşturmuş olduk.
