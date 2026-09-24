%{
  version: "1.0.4",
  title: "OTP Concurrency",
  excerpt: """
  Kita sudah lihat abstraksi Elixir untuk konkurensi, tapi kadang kita butuh kontrol yang lebih besar dan untuk itu kita beralih ke perilaku OTP yang menjadi dasar Elixir.
  
  Dalam pelajaran ini kita akan fokus pada bagian terbesar: GenServer
  """
}
---

## GenServer

Server OTP adalah modul dengan perilaku GenServer yang mengimplementasikan serangkaian callback.
Pada tingkat paling dasar, GenServer adalah proses tunggal yang menjalankan loop yang menangani satu pesan per iterasi meneruskan status yang diperbarui.

Untuk mendemonstrasikan API GenServer, kita akan mengimplementasikan antrian dasar untuk menyimpan dan mengambil nilai.

Untuk memulai GenServer kita, kita perlu memulainya dan menangani inisialisasinya. 
Dalam kebanyakan kasus, kita ingin menghubungkan proses, jadi kita menggunakan `GenServer.start_link/3`.
Kita meneruskan modul GenServer yang kita mulai, argumen awal, dan serangkaian opsi GenServer.
Argumen akan diteruskan ke `GenServer.init/1` yang mengatur status awal melalui nilai kembaliannya.
Dalam contoh kita, argumennya adalah status awal kita:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Start our queue and link it.
  This is a helper function
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

Seringkali kita perlu berinteraksi dengan GenServer secara sinkron, memanggil sebuah fungsi dan menunggu responnya.
Untuk menangani permintaan sinkron, kita perlu mengimplementasikan callback `GenServer.handle_call/3` yang menerima: permintaan, PID pemanggil, dan status yang ada; diharapkan akan membalas dengan mengembalikan tuple: `{:reply, response, state}`.

Dengan pencocokan pola, kita dapat mendefinisikan callback untuk berbagai permintaan dan status yang berbeda.
Daftar lengkap nilai kembalian yang diterima dapat ditemukan di dokumentasi [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3).

Untuk mendemonstrasikan permintaan sinkron, mari kita tambahkan kemampuan untuk menampilkan antrean kita saat ini dan untuk menghapus sebuah nilai:

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

Mari memulai SimpleQueue kita dan uji fungsionalitas dequeue baru kita:

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

### Fungsi Asinkron

Permintaan asinkron ditangani dengan callback `handle_cast/2`.
Ini bekerja hampir sama seperti `handle_call/3` tetapi tidak menerima pemanggil dan tidak diharapkan untuk membalas.

Kita akan mengimplementasikan fungsi enqueue kita secara asinkron, memperbarui antrean tetapi tidak memblokir eksekusi kita saat ini:

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

Mari kita manfaatkan fungsi baru kita:

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

Untuk informasi lebih lanjut, lihat dokumentasi resmi [GenServer](https://hexdocs.pm/elixir/GenServer.html#content).
