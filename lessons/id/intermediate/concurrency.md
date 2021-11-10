%{
  version: "0.9.1",
  title: "Concurrency",
  excerpt: """
  Satu poin yang menjual dari Elixir adalah dukungannya terhadap konkurensi. Berkat Erlang VM (BEAM), konkurensi dalam Elixir sangat mudah.  Model konkurensinya berdasar pada Actor, sebuah proses terlindung (contained) yang berkomunikasi dengan proses lain lewat pengiriman pesan (message passing).

  Dalam pelajaran ini kita akan melihat pada modul-modul konkurensi yang diluncurkan bersama Elixir.  Dalam bab selanjutnya kita membahas perilaku OTP yang mengimplementasikannya.
  """
}
---

## Proses

Proses (process) dalam VM Erlang adalah ringan dan dijalankan lintas CPU.  Walau proses mungkin tampak sebagai native thread, proses sebetulnya lebih sederhana dan bukannya jarang memiliki ribuan proses yang konkuren dalam sebuah aplikasi Elixir.

Cara termudah untuk membuat sebuah proses baru adalah `spawn`, yang menggunakan sebuah fungsi yang bernama maupun yang anonim.  Ketika kita membuat sebuah proses baru, `spawn` mengembalikan sebuah _Process Identifier_, atau PID, untuk mengidentifikasikannya secara unik di dalam aplikasi kita.

Untuk memulai kita akan membuat sebuah modul dan mendefinisikan sebuah fungsi yang kita ingin jalankan:

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

Untuk mengevaluasi fungsi tersebut secara asinkron kita gunakan `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Pengiriman Pesan

Untuk berkomunikasi, proses-proses bergantung pada pengiriman pesan (message passing).  Ada dua komponen utama: `send/2` and `receive`.  Fungsi `send/2` mengijinkan kita mengirim pesan ke PID.  Untuk mendengarkan kita gunakan `receive` untuk mencocokkan pesan.  Jika tidak ada kecocokan eksekusi berjalan terus.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end
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

### Process Linking

Satu masalah dengan `spawn` adalah cara mengetahui ketika sebuah proses crash.  Untuk itu kita perlu mengkaitkan (link) proses-proses kita menggunakan `spawn_link`.  Dua proses yang terkait akan saling menerima notifikasi exit:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Terkadang kita tidak ingin proses kita yang terkait untuk mengakibatkan proses yang sekarang ada ikut crash.  Untuk itu kita perlu menjebak (trap) exit.  Ketika menjebak exit proses akan menerima sebagai sebuah pesan tuple: `{:EXIT, from_pid, reason}`.

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

### Process Monitoring

Bagaimana jika kita tidak ingin mengkaitkan dua proses tetapi tetap ingin menerima informasi? Untuk itu kita bisa menggunakan pemantauan proses (process monitoring) dengan `spawn_monitor`. Ketika kita memantau sebuah proses keta menerima sebuah pesan jika proses tersebut crash, tanpa akibatkan proses kita yang sedang berjalan ikut crash atau perlu secara eksplisit menjebak exit.

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

## Agent

Agent adalah sebuah abstraksi yang melingkupi background process yang menjaga state.  Kita bisa mengakses Agent dari proses lain di dalam aplikasi dan node kita.  State dari Agent kita diset ke return value fungsi kita:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Jika kita memberi nama sebuah Agent kita bisa merujuknya menggunakan nama tersebut dan bukannya PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Task

Task memberikan cara untuk mengeksekusi sebuah fungsi di background dan menerima hasilnya belakangan.  Task bisa berguna terutama ketika menangani operasi yang mahal (makan waktu lama) tanpa memblok eksekusi aplikasi kita.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{pid: #PID<0.111.0>, ref: #Reference<0.0.8.200>}

# Lanjutkan kerjakan hal lain

iex> Task.await(task)
4000
```
