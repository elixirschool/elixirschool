%{
  version: "1.1.1",
  title: "Concurrency",
  excerpt: """
  Salah satu daya tarik Elixir adalah dukungannya terhadap konkurensi.
  Berkat Erlang VM (BEAM), konkurensi di Elixir lebih mudah dari yang diperkirakan.
  Model konkurensi bergantung pada Aktor, sebuah proses terisolasi yang berkomunikasi dengan proses lain melalui pengiriman pesan.
  
  Dalam pelajaran ini kita akan melihat modul konkurensi yang disertakan dengan Elixir.
  
  Pada bab selanjutnya kita akan membahas perilaku OTP yang mengimplementasikannya.
  """
}
---

## Proses

Proses dalam VM Erlang ringan dan berjalan di semua CPU.
Meskipun tampak seperti thread asli, proses lebih sederhana dan tidak jarang terdapat ribuan proses konkuren dalam aplikasi Elixir.

Cara termudah untuk membuat proses baru adalah dengan `spawn`, yang menerima fungsi anonim atau bernama.
Saat kita membuat proses baru, ia mengembalikan _Pengidentifikasi Proses_, atau PID, untuk mengidentifikasinya secara unik dalam aplikasi kita.

Untuk memulai, kita akan membuat modul dan mendefinisikan fungsi yang ingin kita jalankan:

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

Untuk berkomunikasi, proses bergantung pada pengiriman pesan.
Ada dua komponen utama dalam hal ini: `send/2` dan `receive`.
Fungsi `send/2` mengijinkan kita untuk mengirim pesan ke PID.
Untuk mendengarkan, kita menggunakan `receive` untuk mencocokkan pesan.
Jika tidak ada kecocokan eksekusi berjalan terus.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end

    listen()
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

Anda mungkin memperhatikan bahwa fungsi `listen/0` bersifat rekursif, ini memungkinkan proses kita untuk menangani beberapa pesan.
Tanpa rekursi, proses kita akan keluar setelah menangani pesan pertama.

### Penautan Proses

Satu masalah dengan `spawn` adalah cara mengetahui kapan suatu proses mengalami crash.
Untuk itu, kita perlu menautkan proses kita menggunakan `spawn_link`.
Dua proses yang ditautkan akan saling menerima notifikasi *exit*:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Terkadang kita tidak ingin proses yang tertaut menyebabkan proses yang sedang berjalan mengalami crash.
Untuk itu, kita perlu menangkap sinyal *exit* menggunakan `Process.flag/2`.
Ini menggunakan fungsi `[process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2)` dari Erlang untuk flag `trap_exit`. Saat menangkap sinyal keluar (`trap_exit` diatur ke `true`), sinyal keluar akan diterima sebagai pesan tuple: `{:EXIT, from_pid, reason}`.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### Pemantauan Proses

Bagaimana jika kita tidak ingin menautkan dua proses tetapi tetap ingin mendapatkan informasi? Untuk itu kita dapat menggunakan pemantauan proses dengan `spawn_monitor`.
Saat kita memantau suatu proses, kita akan mendapatkan pesan jika proses tersebut mengalami crash, tanpa proses kita saat ini mengalami crash atau perlu secara eksplisit menjebak exit.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, _ref, :process, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Agent

Agent adalah abstraksi di sekitar proses latar belakang yang menjaga status (state).
Kita bisa mengakses Agent dari proses lain di dalam aplikasi dan node kita.
State dari Agent kita diset ke return value fungsi kita:

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

Task menyediakan cara untuk mengeksekusi fungsi di latar belakang dan mengambil nilai kembaliannya nanti.
Task bisa sangat berguna saat menangani operasi yang memakan banyak sumber daya tanpa memblokir eksekusi aplikasi.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{
  owner: #PID<0.105.0>,
  pid: #PID<0.114.0>,
  ref: #Reference<0.2418076177.4129030147.64217>
}

# Do some work

iex> Task.await(task)
4000
```
