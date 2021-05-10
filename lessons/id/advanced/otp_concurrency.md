%{
  version: "1.0.0",
  title: "OTP Concurrency",
  excerpt: """
  Kita sudah melihat abstraksi Elixir untuk konkurensi tapi terkadang kita butuh kendali lebih dan untuk itu kita beralih ke perilaku OTP yang mana Elixir dibangun di atasnya.

Dalam pelajaran ini kita hanya akan fokus pada bagian yang paling penting yaitu Genserver.
  """
}
---

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
