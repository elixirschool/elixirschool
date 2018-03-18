---
version: 0.9.1
title: OTP Concurrency
---

Kita sudah melihat abstraksi Elixir untuk konkurensi tapi terkadang kita butuh kendali lebih dan untuk itu kita beralih ke perilaku OTP yang mana Elixir dibangun di atasnya.

Dalam pelajaran ini kita akan fokus pada dua bagian penting: Genserver dan GenEvent.

{% include toc.html %}

## GenServer

Sebuah OTP server adalah sebuah modul dengan perilaku GenServer yang mengimplementasikan sekumpulan callback.  Pada tingkat paling mendasarnya sebuah GenServer adalah sebuah loop yang menangani sebuah request per iterasi dan melewatkan sebuah state yang sudah diperbaharui (updated).

Untuk mendemonstasikan API GenServer kita akan menimplementasikan sebuah antrian (queue) sederhana untuk menyimpan dan menerima value.

Untuk memulai GenServer kita, kita perlu memulainya dan menangani inisialisasinya. Dalam kebanyakan kasus kita akan ingin mengkaitkan (link) proses jadi kita menggunakan `GenServer.start_link/3`. Kita memasukkan modul GenServer yang kita mulai, argumen awal, dan sejumlah opsi GenServer.  Argumen-argumen itu akan diteruskan ke `GenServer.init/1` yang menset state awal melalui value yang dikembalikannya.  Dalam contoh kita ini argumennya adalah state awal (initial state) kita:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Start our queue and link it.  This is a helper function
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}
end
```

### Fungsi Sinkron

Seringkali kita perlu berinteraksi dengan GenServer dengan cara yang sinkron, memanggil fungsi dan menunggu jawabannya.  Untuk menangani permintaan (request) yang sinkron kita perlu mengimplementasikan callback `GenServer.handle_call/3` yang menerima parameter: permintaan tersebut (request), PID pemanggil, dan state yang sedang ada; yang dikembalikan adalah sebuah tuple: `{:reply, response, state}`.

Dengan pencocokan pola kita bisa mendefinisikan callback untuk banyak request dan state. Daftar lengkap value pengembalian (return value) yang dapat diterima bisa dilihat di dokumentasi [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3).

Untuk mendemonstrasikan request yang sinkron, mari kita tambahkan kemampuan untuk menampilkan antrian kita saat ini dan untuk mengeluarkan sebuah entri:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Mari memulai SimpleQueue kita dan mencoba fungsi dequeue kita yang baru:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.90.0>}
iex> SimpleQueue.dequeue
1
iex> SimpleQueue.dequeue
2
iex> SimpleQueue.queue
[3]
```

### Fungsi Taksinkron

Request yang taksinkron (asynchronous) ditangani dengan callback `handle_cast/2`.  Callback ini bekerja mirip dengan `handle_call/3` tetapi tidak menerima pemanggilnya dan tidak perlu ada balasan (mengembalikan sesuatu).

Kita akan mengimplementasikan fungsi enqueue kita secara taksinkron, mengubah antrian kita tetapi tidak memblok eksekusi kita yang sedang berjalan:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Mari kita gunakan fungsionalitas kita yang baru:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.100.0>}
iex> SimpleQueue.queue
[1, 2, 3]
iex> SimpleQueue.enqueue(20)
:ok
iex> SimpleQueue.queue
[1, 2, 3, 20]
```

Untuk informasi lebih lanjut kunjungi dokumentasi resmi [GenServer](https://hexdocs.pm/elixir/GenServer.html#content).

## GenEvent

Kita sudah belajar bahwa GenServer adalah proses yang dapat menyimpan state dan menangani request sinkron maupun taksinkron.  Lantas, apa itu GenEvent?  GenEvent adalah pengatur event yang generik yang menerima event yang datang dan memberitahu (notify) konsumer yang mendaftarkan diri untuk diinfokan (subscribed consumer).  GenEvent memberi mekanisme untuk menambah dan menghapus handler terhadap aliran event.

### Menangani event

Callback yang paling penting dalam GenEven yang bisa dibayangkan adalah `handle_event/2`.  Callback ini menerima event dan state saat ini dari handlernya, dan mengembalikan sebuah tuple: `{:ok, state}`.

Untuk mendemonstrasikan fungsionalitas GenEvent mari mulai dengan membuat dua handler, satu untuk mencatat log dari pesan (message), dan yang satunya untuk menyimpan (persist) pesan tersebut (secara teoritis):

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts("Logging new message: #{msg}")
    {:ok, [msg | messages]}
  end
end

defmodule PersistenceHandler do
  use GenEvent

  def handle_event({:msg, msg}, state) do
    IO.puts("Persisting log message: #{msg}")

    # Save message

    {:ok, state}
  end
end
```

### Memanggil Handler

Selain `handle_event/2` GenEvent juga mendukung, antara lain, callback `handle_call/2`. Dengan `handle_call/2` kita bisa menangani pesan sinkron yang spesifik dengan handler kita.

Mari ubah `LoggerHandler` kita untuk melibatkan sebuah method untuk mengambil log pesan terbaru:

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts("Logging new message: #{msg}")
    {:ok, [msg | messages]}
  end

  def handle_call(:messages, messages) do
    {:ok, Enum.reverse(messages), messages}
  end
end
```

### Menggunakan GenEvent

Dengan handler kita sudah siap kita perlu membiasakan diri dengan beberapa fungsi GenEvent.  Tiga fungsi yang paling penting adalah: `add_handler/3`, `notify/2`, dan `call/4`.  Ketiga fungsi ini masing-masing memungkinkan kita menambahkan handler, menginformasikan adanya pesan baru, dan memanggil fungsi handler yang spesifik.

Jika kita masukkan semua, kita bisa melihat bagaimana handler kita bekerja:

```elixir
iex> {:ok, pid} = GenEvent.start_link([])
iex> GenEvent.add_handler(pid, LoggerHandler, [])
iex> GenEvent.add_handler(pid, PersistenceHandler, [])

iex> GenEvent.notify(pid, {:msg, "Hello World"})
Logging new message: Hello World
Persisting log message: Hello World

iex> GenEvent.call(pid, LoggerHandler, :messages)
["Hello World"]
```

Lihat dokumentasi resmi [GenEvent](https://hexdocs.pm/elixir/GenEvent.html#content) untuk daftar lengkap callback dan fungsionalitas GenEvent.
