---
version: 0.9.1
title: Keserempakan
---

Salah satu faktor pelaris Elixir ialah sokongan kepada keserempakan(concurrency).  Terima kasih kepada Erlang VM (BEAM), keserempakan di dalam Elixir adalah lebih mudah dari yang dijangkakan.  Model keserempakan bergantung kepada Actor, satu proses yang berkomunikasi dengan proses-proses lain melalui pengagihan mesej.

Di dalam pelajaran ini kita akan lihat modul-modul keserempakan yang didatangkan dengan Elixir.  Di dalam bab seterusnya kita lihat kelakuan OTP yang melaksanakan mereka.

{% include toc.html %}

## Proses

Proses-proses di dalam Erlang VM adalah ringan dan memanafaatkan kesemua CPU apabila dijalankan.  Walaupun mereka nampak seperti 'native thread',  mereka sebenarnya adalah lebih ringkas dan ianya tidak janggal jika terdapat ribuan proses yang berjalan secara keserempakan di dalam aplikasi Elixir.

Cara paling mudah untuk membuat satu proses baru ialah menggunakan `spawn`, yang mengambil satu fungsi tanpa nama atau fungsi bernama.  Apabila kita membuat satu proses baru ia akan memulangkan satu _Process Identifier_, atau PID,  sebagai pengenalan unik untuk proses itu di dalam aplikasi kita.

Untuk bermula kita akan membuat satu modul dan takrifkan satu fungsi yang kita mahu jalankan:

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

Untuk menjalankan fungsi tersebut secara tak segerak(asynchronous) kita gunakan `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Pengagihan Mesej

Untuk berkomunikasi, proses-proses bergantung kepada pengagihan mesej.  Terdapat dua komponen penting di dalam pengagihan mesej, `send/2` dan `receive/2`.  Fungsi `send/2` mengupayakan kita untuk menghantar mesej kepada PID.  Untuk mengawasi penerimaan mesej, kita gunakan `receive`.  

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

### Perangkaian Proses

Fungsi `spawn` mempunyai satu masalah iaitu untuk mengetahui apabila sesatu proses itu runtuh(crash).  Untuk itu kita perlu untuk merangkaikan proses-proses kita dengan menggunakan `spawn_link`.  Dua proses yang dirangkaikan akan menerima 'exit notification' dari satu sama lain:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Kadang-kadang kita tidak mahu proses yang dirangkaikan meruntuhkan proses sedia ada.  Untuk itu kita perlu untk memerangkap 'exit' tersebut.  'Exit' yang diperangkap akan diterima sebagai satu mesej dalam bentuk tuple: `{:Exit, from_pid, reason}`.

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

### Pengawasan Proses

Bagaiana pula jika kita tidak mahu merangkaikan dua proses tetapi masih diberitahu mengenai keadaan semasa proses-proses tersebut?  Untuk itu kita boleh membuat pengawasan proses dengan menggunakan `spawn_monitor`.  Apabila mengawasi satu proses, kita akan mendapat satu mesej jika proses tersebut runtuh tanpa meruntuhkan sama proses semasa kita atau tanpa memerlukan 'exit' itu diperangkap.

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

Agent adalah sejenis peniskalaan(abstraction) proses-proses 'background' yang menyelenggara keadaan semasa(state).  Mereka boleh dicapai daripada proses-proses lain dari dalam aplikasi dan nod kita.  Keadaan semasa(state) Agent kita ditetapkan kepada nilai yang dipulangkan oleh fungsi-fungsi kita:  

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Apabila kita menamakan satu Agent, ia boleh dirujuk sebagai Agent dan tidak melalui PID-nya.

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Task

'Task' menyediakan satu cara untk menjalankan satu fungsi di 'background' dan menerima nilai yang dipulangkan kemudian.  Ianya amat berguna apabila menguruskan operasi-operasi yang berat tanpa merencatkan perjalanan aplikasi.

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
