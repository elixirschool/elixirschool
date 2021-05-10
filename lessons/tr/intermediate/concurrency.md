%{
  version: "1.1.0",
  title: "Concurrency",
  excerpt: """
  Elixir'in önemli noktalarından biri de eşzamanlılık desteğidir. Erlang VM (BEAM) sayesinde, Elixir'deki eşzamanlılık beklenenden daha kolaydır. Eşzamanlılık modeli, mesaj geçişi yoluyla diğer süreçlerle iletişim kuran aktörlere dayanır.

Bu derste Elixir ile birlikte gelen eşzamanlılık modüllerine bakacağız. Takip eden bölümde, bunları uygulayan OTP davranışlarını ele alıyoruz.
  """
}
---

## Süreçler

Erlang VM'deki işlemler hafiftir ve tüm CPU'larda çalışır. Yerel ileti dizileri gibi görünseler de, daha basittirler ve bir Elixir uygulamasında binlerce eşzamanlı işlemin olması hiçte zor değildir.

Yeni bir süreç oluşturmanın en kolay yolu, adsız veya adlandırılmış bir fonksiyon alan `spawn`, Yeni bir süreç oluşturduğumuzda, kendi uygulamalarımızda benzersiz bir şekilde tanımlamak için bir _Process Identifier_ veya PID değerini döndürür.

Başlamak için bir modül oluşturacağız ve çalıştırmak istediğimiz bir fonksiyon tanımlayacağız:

```elixir
defmodule Example do
  def add(a, b) do
    IO.puts(a + b)
  end
end

iex> Example.add(2, 3)
5
:ok
```

Eş zamansız bir fonksiyon değerlendirmek için `spawn/3` kullanırız:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### İleti Geçişi

İletişim kurmak için süreçler iletilen iletilere güvenir. Bunun iki ana bileşeni var. Bunlar: `send/2` ve `receive`.

`send/2` fonksiyonu, PID'lere mesaj göndermemize izin verir. Mesajları dinleyebilmek için  `receive`'ı kullanın. Eşleşme bulunamazsa, yürütme kesintisiz olarak devam eder.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end

    listen
  end
end

iex> pid = spawn(Example, :listen, [])
#PID<0.108.0>

iex> send pid, {:ok, "hello"}
World
{:ok, "hello"}

iex> send pid, :ok
:ok
```

`listen/0` tekrarlı olduğunu fark edebilirsiniz, bu sayede sürecimizin birden çok mesajı ele almasını sağlayabiliriz. Yineleme olmadan, ilk mesajın işlenmesinden sonra işlemimiz kesilirdi.

### Süreç bağlantısı

`spawn` ile ilgili problem, işlemin ne zaman çökeceğini bilmektir. Bunun için süreçlerimizi `spawn_link` kullanarak bağlamamız gerekiyor.

One problem with `spawn` is knowing when a process crashes.  For that we need to link our processes using `spawn_link`. İki bağlantılı bir süreç birbirinden aşağıdaki örnektede görebileceğiniz gibi bir çıkış bildirimi alır:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Bazen bizim bağlantılı sürecimizin şu anki çöküşünü istemiyoruz. Bunun için `Process.flag/2` kullanarak çıkışları yakalamamız gerekiyor. `trap_exit` bayrağı için erlang'ın [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) fonksiyonunu kullanabiliriz. Çıkışları yakalarken (`trap_exit` değeri `true` olarak ayarlanır), çıkış sinyalleri bir demet mesajı olarak şu şekilde alınacaktır: `{: EXIT, from_pid, reason}`

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### Süreç İzleme

Ya iki süreci birbirine bağlamak istemiyorsak, yine de haberdar edilmek istiyorsak? Bunun için `spawn_monitor` ile süreci izleyebiliriz. Bir süreci izlediğimizde, sürecin çökmesi veya sürecin beklenmedik bir biçimde çökmesi ile bir ileti alırız.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    {pid, ref} = spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, ref, :process, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Ajanlar

Ajanlar durumları koruyan arka plan süreçleri etrafında uygulanan bir soyutlamadır. Uygulamalarımızdaki ve düğümümüzdeki diğer süreçlerden onlara erişebiliriz. Ajanımızın durumu, fonksiyonumuzun geri dönüş değerine ayarlanır:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Bir Ajan ismini verdiğimiz zaman, PID'in yerine buna başvurabiliriz:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Görevler

Görevler, arka planda bir fonksiyonu yürütmek ve daha sonra geri dönüş değerini almak için size bir yol sağlar. İşlem yükü çok olan durumları ele almamız gerekirse özellikle görevler oldukça işinize yarayacaktır.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{pid: #PID<0.111.0>, ref: #Reference<0.0.8.200>}

# Do some work

iex> Task.await(task)
4000
```
