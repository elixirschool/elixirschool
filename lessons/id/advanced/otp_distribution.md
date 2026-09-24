%{
  version: "1.1.0",
  title: "Distribusi OTP",
  excerpt: """
  Kita dapat menjalankan aplikasi Elixir kita pada sekumpulan node berbeda yang didistribusikan di satu host atau di beberapa host.
  Elixir memungkinkan kita untuk berkomunikasi antar node ini melalui beberapa mekanisme berbeda yang akan kita uraikan dalam pelajaran ini.
  """
}
---

## Komunikasi Antar Node

Elixir berjalan di atas VM Erlang, yang berarti ia memiliki akses ke [fungsi distribusi](http://erlang.org/doc/reference_manual/distributed.html) Erlang yang canggih.

> Sistem Erlang terdistribusi terdiri dari sejumlah sistem runtime Erlang yang saling berkomunikasi.
Setiap sistem runtime tersebut disebut node.

Node adalah sistem runtime Erlang apa pun yang telah diberi nama.
Kita dapat memulai sebuah node dengan membuka sesi `iex` dan memberinya nama:

```bash
iex --sname alex@localhost
iex(alex@localhost)>
```

Let's open up another node in another terminal window:

```bash
iex --sname kate@localhost
iex(kate@localhost)>
```

Kedua node ini dapat saling mengirim pesan menggunakan `Node.spawn_link/2`.

### Berkomunikasi dengan Node.spawn_link/2

Fungsi ini menerima dua argumen:

* Nama node yang ingin Anda hubungkan
* Fungsi yang akan dieksekusi oleh proses jarak jauh yang berjalan di node tersebut

Fungsi ini membangun koneksi ke node jarak jauh dan mengeksekusi fungsi yang diberikan pada node tersebut, mengembalikan PID dari proses yang terhubung.

Mari kita definisikan sebuah modul, `Kate`, di node `kate` yang mengetahui cara memperkenalkan Kate, orang tersebut:

```elixir
iex(kate@localhost)> defmodule Kate do
...(kate@localhost)>   def say_name do
...(kate@localhost)>     IO.puts "Hi, my name is Kate"
...(kate@localhost)>   end
...(kate@localhost)> end
```

#### Sending Messages

Sekarang, kita dapat menggunakan [`Node.spawn_link/2`](https://hexdocs.pm/elixir/Node.html#spawn_link/2) agar node `alex` meminta node `kate` untuk memanggil fungsi `say_name/0`:

```elixir
iex(alex@localhost)> Node.spawn_link(:kate@localhost, fn -> Kate.say_name end)
Hi, my name is Kate
#PID<10507.132.0>
```

#### Catatan tentang I/O dan Node

Perhatikan bahwa, meskipun `Kate.say_name/0` dieksekusi pada node jarak jauh, node lokal, atau node pemanggil, yang menerima output `IO.puts`.
Itu karena node lokal adalah **pemimpin grup**.
VM Erlang mengelola I/O melalui proses.
Ini memungkinkan kita untuk mengeksekusi tugas I/O, seperti `IO.puts`, di seluruh node terdistribusi.
Proses terdistribusi ini dikelola oleh pemimpin grup proses I/O.
Pemimpin grup selalu merupakan node yang memunculkan proses tersebut.
Jadi, karena node `alex` kita adalah node tempat kita memanggil `spawn_link/2`, node tersebut adalah pemimpin grup dan output dari `IO.puts` akan diarahkan ke aliran output standar node tersebut.

#### Menanggapi Pesan

Bagaimana jika kita ingin node yang menerima pesan mengirimkan *respons* kembali ke pengirim? Kita dapat menggunakan pengaturan `receive/1` dan [`send/3`](https://hexdocs.pm/elixir/Process.html#send/3) sederhana untuk mencapai hal tersebut.

Node `alex` akan membuat tautan ke node `kate` dan memberikan fungsi anonim kepada node `kate` untuk dieksekusi.
Fungsi anonim tersebut akan mendengarkan penerimaan tuple tertentu yang menjelaskan pesan dan PID dari node `alex`.
Fungsi tersebut akan menanggapi pesan tersebut dengan mengirimkan pesan kembali ke PID dari node `alex`:

```elixir
iex(alex@localhost)> pid = Node.spawn_link :kate@localhost, fn ->
...(alex@localhost)>   receive do
...(alex@localhost)>     {:hi, alex_node_pid} -> send alex_node_pid, :sup?
...(alex@localhost)>   end
...(alex@localhost)> end
#PID<10467.112.0>
iex(alex@localhost)> pid
#PID<10467.112.0>
iex(alex@localhost)> send(pid, {:hi, self()})
{:hi, #PID<0.106.0>}
iex(alex@localhost)> flush()
:sup?
:ok
```

#### Catatan Tentang Komunikasi Antar Node di Jaringan yang Berbeda

Jika Anda ingin mengirim pesan antar node di jaringan yang berbeda, kita perlu memulai node yang diberi nama dengan cookie bersama:

```bash
iex --sname alex@localhost --cookie secret_token
```

```bash
iex --sname kate@localhost --cookie secret_token
```

Hanya node yang dimulai dengan `cookie` yang sama yang dapat terhubung satu sama lain dengan sukses.

#### Keterbatasan Node.spawn_link/2

Meskipun `Node.spawn_link/2` mengilustrasikan hubungan antar node dan cara kita dapat mengirim pesan di antara mereka, ini *bukan* pilihan yang tepat untuk aplikasi yang akan berjalan di seluruh node terdistribusi.
`Node.spawn_link/2` menjalankan proses secara terisolasi, yaitu proses yang tidak diawasi.
Andai saja ada cara untuk menjalankan proses asinkron yang diawasi *di seluruh node*...

## Tugas Terdistribusi

[Tugas terdistribusi](https://hexdocs.pm/elixir/Task.html#module-distributed-tasks) memungkinkan kita untuk menjalankan task yang diawasi di seluruh node.
Kita akan membangun aplikasi pengawas sederhana yang memanfaatkan tugas terdistribusi untuk memungkinkan pengguna mengobrol satu sama lain melalui sesi `iex`, di seluruh node terdistribusi.

### Mendefinisikan Aplikasi Supervisor

Buat aplikasi Anda:

```shell
mix new chat --sup
```

### Menambahkan Supervisor Tugas ke Pohon Supervisi

Supervisor Task secara dinamis mengawasi tugas.
Supervisor ini dimulai tanpa anak, seringkali *di bawah* supervisornya sendiri, dan dapat digunakan kemudian untuk mengawasi sejumlah tugas.

Kita akan menambahkan Supervisor Task ke pohon supervisi aplikasi kita dan menamainya `Chat.TaskSupervisor`

```elixir
# lib/chat/application.ex
defmodule Chat.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Chat.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Sekarang kita tahu bahwa di mana pun aplikasi kita dijalankan pada node tertentu, `Chat.Supervisor` sedang berjalan dan siap untuk mengawasi tugas.

### Mengirim Pesan dengan Tugas yang Diawasi

Kita akan memulai tugas yang diawasi dengan fungsi [`Task.Supervisor.async/5`](https://hexdocs.pm/elixir/Task.Supervisor.html#async/5).

Fungsi ini harus menerima empat argumen:

* Supervisor yang ingin kita gunakan untuk mengawasi tugas.
Ini dapat diberikan sebagai tuple `{SupervisorName, remote_node_name}` untuk mengawasi tugas pada node jarak jauh.
* Nama modul tempat kita ingin menjalankan fungsi
* Nama fungsi yang ingin kita jalankan
* Argumen apa pun yang perlu diberikan ke fungsi tersebut

Anda dapat memberikan argumen kelima, opsional, yang menjelaskan opsi penutupan.
Kita tidak akan membahasnya di sini.

Aplikasi Chat kita cukup sederhana.
Ia mengirimkan pesan ke node jarak jauh dan node jarak jauh merespons pesan tersebut dengan mengirimkan outputnya ke STDOUT node jarak jauh menggunakan `IO.puts`.

Pertama, mari kita definisikan sebuah fungsi, `Chat.receive_message/1`, yang ingin kita jalankan pada node jarak jauh.

```elixir
# lib/chat.ex
defmodule Chat do
  def receive_message(message) do
    IO.puts message
  end
end
```

Selanjutnya, mari kita ajarkan modul `Chat` cara mengirim pesan ke node jarak jauh menggunakan tugas yang diawasi.
Kita akan mendefinisikan metode `Chat.send_message/2` yang akan menjalankan proses ini:

```elixir
# lib/chat.ex
defmodule Chat do
  ...

  def send_message(recipient, message) do
    spawn_task(__MODULE__, :receive_message, recipient, [message])
  end

  def spawn_task(module, fun, recipient, args) do
    recipient
    |> remote_supervisor()
    |> Task.Supervisor.async(module, fun, args)
    |> Task.await()
  end

  defp remote_supervisor(recipient) do
    {Chat.TaskSupervisor, recipient}
  end
end
```

Mari kita lihat cara kerjanya.

Di satu jendela terminal, jalankan aplikasi chat kita dalam sesi bernama `iex`.

```bash
iex --sname alex@localhost -S mix
```

Buka jendela terminal lain untuk menjalankan aplikasi pada node bernama yang berbeda:

```bash
iex --sname kate@localhost -S mix
```

Sekarang, dari node `alex`, kita dapat mengirim pesan ke node `kate`:

```elixir
iex(alex@localhost)> Chat.send_message(:kate@localhost, "hi")
:ok
```

Beralihlah ke jendela `kate` dan Anda akan melihat pesan berikut:

```elixir
iex(kate@localhost)> hi
```

Node `kate` dapat memberikan respons kembali ke node `alex`:

```elixir
iex(kate@localhost)> hi
Chat.send_message(:alex@localhost, "how are you?")
:ok
iex(kate@localhost)>
```

Dan itu akan muncul di sesi `iex` node `alex`:

```elixir
iex(alex@localhost)> how are you?
```

Mari kita tinjau kembali kode kita dan uraikan apa yang terjadi di sini.

Kita memiliki fungsi `Chat.send_message/2` yang menerima nama node jarak jauh tempat kita ingin menjalankan tugas yang diawasi dan pesan yang ingin kita kirim ke node tersebut.

Fungsi tersebut memanggil fungsi `spawn_task/4` kita yang memulai tugas asinkron yang berjalan pada node jarak jauh dengan nama yang diberikan, diawasi oleh `Chat.TaskSupervisor` pada node jarak jauh tersebut.
Kita tahu bahwa Task Supervisor dengan nama `Chat.TaskSupervisor` berjalan pada node tersebut karena node tersebut *juga* menjalankan instance aplikasi Chat kita dan `Chat.TaskSupervisor` dijalankan sebagai bagian dari pohon pengawasan aplikasi Chat.

Kita memberi tahu `Chat.TaskSupervisor` untuk mengawasi tugas yang mengeksekusi fungsi `Chat.receive_message` dengan argumen berupa pesan apa pun yang diteruskan ke `spawn_task/4` dari `send_message/2`.

Jadi, `Chat.receive_message("hi")` dipanggil pada node jarak jauh, `kate`, yang menyebabkan pesan `"hi"` dikeluarkan ke aliran STDOUT node tersebut.
Dalam hal ini, karena tugas diawasi pada node jarak jauh, node tersebut adalah pengelola grup untuk proses I/O ini.

### Menanggapi Pesan dari Node Jarak Jauh

Mari kita buat aplikasi Chat kita sedikit lebih pintar.
Sejauh ini, sejumlah pengguna dapat menjalankan aplikasi dalam sesi `iex` bernama dan mulai mengobrol.
Tetapi katakanlah ada seekor anjing putih berukuran sedang bernama Moebi yang tidak ingin ketinggalan.
Moebi ingin diikutsertakan dalam aplikasi Chat tetapi sayangnya dia tidak tahu cara mengetik, karena dia adalah seekor anjing.
Jadi, kita akan mengajari modul `Chat` kita untuk menanggapi pesan apa pun yang dikirim ke node bernama `moebi@localhost` atas nama Moebi.
Tidak peduli apa yang Anda katakan kepada Moebi, dia akan menjawab dengan "chicken?", karena satu-satunya keinginan sejatinya adalah makan ayam.

Kita akan mendefinisikan versi lain dari fungsi `send_message/2` kita yang mencocokkan pola pada argumen `recipient`.
Jika penerimanya adalah `:moebi@locahost`, kita akan:

* Mengambil nama node saat ini menggunakan `Node.self()`
* Memberikan nama node saat ini, yaitu pengirim, ke fungsi baru `receive_message_for_moebi/2`, sehingga kita dapat mengirim pesan *kembali* ke node tersebut.

```elixir
# lib/chat.ex
...
def send_message(:moebi@localhost, message) do
  spawn_task(__MODULE__, :receive_message_for_moebi, :moebi@localhost, [message, Node.self()])
end
```

Selanjutnya, kita akan mendefinisikan fungsi `receive_message_for_moebi/2` yang `IO.puts` mengeluarkan pesan ke aliran STDOUT node `moebi` *dan* mengirimkan pesan kembali ke pengirim:

```elixir
# lib/chat.ex
...
def receive_message_for_moebi(message, from) do
  IO.puts message
  send_message(from, "chicken?")
end
```

Dengan memanggil `send_message/2` dengan nama node yang mengirim pesan asli ("node pengirim"), kita memberi tahu node *jarak jauh* untuk menjalankan tugas yang diawasi kembali pada node pengirim tersebut.

Mari kita lihat cara kerjanya.
Di tiga jendela terminal yang berbeda, buka tiga node bernama yang berbeda:

```bash
iex --sname alex@localhost -S mix
```

```bash
iex --sname kate@localhost -S mix
```

```bash
iex --sname moebi@localhost -S mix
```

Mari kita minta `alex` mengirim pesan ke `moebi`:

```elixir
iex(alex@localhost)> Chat.send_message(:moebi@localhost, "hi")
chicken?
:ok
```

Kita dapat melihat bahwa node `alex` menerima respons, `"chicken?"`.
Jika kita membuka node `kate`, kita akan melihat bahwa tidak ada pesan yang diterima, karena baik `alex` maupun `moebi` tidak mengirimkan pesan kepadanya (maaf `kate`).
Dan jika kita membuka jendela terminal node `moebi`, kita akan melihat pesan yang dikirim oleh node `alex`:

```elixir
iex(moebi@localhost)> hi
```

## Pengujian Kode Terdistribusi

Mari kita mulai dengan menulis tes sederhana untuk fungsi `send_message` kita.

```elixir
# test/chat_test.exs
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

Jika kita menjalankan tes kita melalui `mix test`, kita akan melihatnya gagal dengan kesalahan berikut:

```elixir
** (exit) exited in: GenServer.call({Chat.TaskSupervisor, :moebi@localhost}, {:start_task, [#PID<0.158.0>, :monitor, {:sophie@localhost, #PID<0.158.0>}, {Chat, :receive_message_for_moebi, ["hi", :sophie@localhost]}], :temporary, nil}, :infinity)
         ** (EXIT) no connection to moebi@localhost
```

Kesalahan ini sangat masuk akal--kita tidak dapat terhubung ke node bernama `moebi@localhost` karena tidak ada node seperti itu yang berjalan.

Kita dapat membuat pengujian ini berhasil dengan melakukan beberapa langkah:

* Buka jendela terminal lain dan jalankan node bernama tersebut: `iex --sname moebi@localhost -S mix`
* Jalankan pengujian di terminal pertama melalui node bernama yang menjalankan pengujian mix dalam sesi `iex`: `iex --sname sophie@localhost -S mix test`

Ini membutuhkan banyak pekerjaan dan jelas tidak akan dianggap sebagai proses pengujian otomatis.

Ada dua pendekatan berbeda yang dapat kita ambil di sini:

1. Secara kondisional mengecualikan pengujian yang membutuhkan node terdistribusi, jika node yang diperlukan tidak berjalan.
2. Konfigurasi aplikasi kita untuk menghindari menjalankan tugas pada node jarak jauh di environment pengujian.

Mari kita lihat pendekatan pertama.

### Pengecualian Bersyarat untuk Tes dengan Tag

Kita akan menambahkan tag `ExUnit` ke tes ini:

```elixir
# test/chat_test.exs
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  @tag :distributed
  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

Dan kita akan menambahkan beberapa logika kondisional ke helper pengujian untuk mengecualikan pengujian dengan tag tersebut jika pengujian tersebut *tidak* berjalan pada node bernama.

```elixir
# test/test_helper.exs
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
```

Kita periksa apakah node tersebut aktif, seperti
apakah node tersebut merupakan bagian dari sistem terdistribusi dengan [`Node.alive?`](https://hexdocs.pm/elixir/Node.html#alive?/0).
Jika tidak, kita dapat memberi tahu `ExUnit` untuk melewati semua pengujian dengan tag `distributed: true`.
Jika aktif, kita akan memberi tahu agar tidak mengecualikan pengujian apa pun.

Sekarang, jika kita menjalankan `mix test` biasa, kita akan melihat:

```bash
mix test
Excluding tags: [distributed: true]

Finished in 0.02 seconds
1 test, 0 failures, 1 excluded
```

Dan jika kita ingin menjalankan pengujian terdistribusi kita, kita hanya perlu mengikuti langkah-langkah yang diuraikan di bagian sebelumnya: jalankan node `moebi@localhost` *dan* jalankan pengujian di node bernama melalui `iex`.

Mari kita lihat pendekatan pengujian kita yang lain—mengonfigurasi aplikasi agar berperilaku berbeda di environment yang berbeda.

### Konfigurasi Aplikasi Spesifik Environment Tertentu

Bagian kode kita yang memberi tahu `Task.Supervisor` untuk memulai tugas yang diawasi pada node jarak jauh ada di sini:

```elixir
# lib/chat.ex
def spawn_task(module, fun, recipient, args) do
  recipient
  |> remote_supervisor()
  |> Task.Supervisor.async(module, fun, args)
  |> Task.await()
end

defp remote_supervisor(recipient) do
  {Chat.TaskSupervisor, recipient}
end
```

`Task.Supervisor.async/5` menerima argumen pertama berupa supervisor yang ingin kita gunakan.
Jika kita memberikan tuple `{SupervisorName, location}`, maka supervisor yang diberikan akan dijalankan pada node jarak jauh yang diberikan.
Namun, jika kita memberikan argumen pertama berupa nama supervisor ke `Task.Supervisor`, maka supervisor tersebut akan digunakan untuk mengawasi tugas secara lokal.

Mari kita buat fungsi `remote_supervisor/1` dapat dikonfigurasi berdasarkan environment.
Di environment pengembangan, fungsi ini akan mengembalikan `{Chat.TaskSupervisor, recipient}` dan di environment pengujian akan mengembalikan `Chat.TaskSupervisor`.

Kita akan melakukan ini melalui variabel aplikasi.

Buat file, `config/dev.exs`, dan tambahkan:

```elixir
# config/dev.exs
import Config
config :chat, remote_supervisor: fn(recipient) -> {Chat.TaskSupervisor, recipient} end
```

Buat file bernama `config/test.exs` dan tambahkan:

```elixir
# config/test.exs
import Config
config :chat, remote_supervisor: fn(_recipient) -> Chat.TaskSupervisor end
```

Ingat untuk menghapus tanda komentar pada baris ini di `config/config.exs`:

```elixir
import Config
import_config "#{config_env()}.exs"
```

Terakhir, kita akan memperbarui fungsi `Chat.remote_supervisor/1` kita untuk mencari dan menggunakan fungsi yang tersimpan dalam variabel aplikasi baru kita:

```elixir
# lib/chat.ex
defp remote_supervisor(recipient) do
  Application.get_env(:chat, :remote_supervisor).(recipient)
end
```

## Kesimpulan

Kemampuan distribusi bawaan Elixir, yang dimilikinya berkat kekuatan VM Erlang, adalah salah satu fitur yang menjadikannya alat yang sangat ampuh.
Kita dapat membayangkan memanfaatkan kemampuan Elixir untuk menangani komputasi terdistribusi untuk menjalankan pekerjaan latar belakang secara bersamaan, untuk mendukung aplikasi berkinerja tinggi, untuk menjalankan operasi yang mahal--dan masih banyak lagi.

Pelajaran ini memberi kita pengantar dasar tentang konsep distribusi di Elixir dan memberi Anda alat yang Anda butuhkan untuk mulai membangun aplikasi terdistribusi.
Dengan menggunakan tugas yang diawasi, Anda dapat mengirim pesan di berbagai node aplikasi terdistribusi.
