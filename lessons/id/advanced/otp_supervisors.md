%{
  version: "1.1.2",
  title: "OTP Supervisors",
  excerpt: """
  Supervisor adalah proses khusus dengan satu tujuan: memantau proses lain.
  Supervisor ini memungkinkan kita untuk membuat aplikasi yang tahan terhadap kesalahan dengan secara otomatis memulai ulang proses anak ketika proses tersebut gagal.
  """
}
---

## Konfigurasi

Keajaiban Supervisor terletak pada fungsi `Supervisor.start_link/2`.
Selain memulai supervisor dan proses anak, fungsi ini memungkinkan kita untuk mendefinisikan strategi yang digunakan supervisor untuk mengelola proses anak.

Menggunakan `SimpleQueue` dari pelajaran [OTP Concurrency](/id/lessons/advanced/otp_concurrency), mari kita mulai:

Buat proyek baru menggunakan `mix new simple_queue --sup` untuk membuat proyek baru dengan pohon supervisor.
Kode untuk modul `SimpleQueue` harus ditempatkan di `lib/simple_queue.ex` dan kode supervisor yang akan kita tambahkan akan ditempatkan di `lib/simple_queue/application.ex`

Proses anak didefinisikan menggunakan daftar, baik daftar nama modul:

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      SimpleQueue
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

atau daftar tuple jika Anda ingin menyertakan opsi konfigurasi:

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleQueue, [1, 2, 3]}
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Jika kita menjalankan `iex -S mix`, kita akan melihat bahwa `SimpleQueue` kita secara otomatis dimulai:

```elixir
iex> SimpleQueue.queue
[1, 2, 3]
```

Jika proses `SimpleQueue` kita mengalami kegagalan atau dihentikan, Supervisor kita akan secara otomatis memulai ulang proses tersebut seolah-olah tidak terjadi apa-apa.

### Strategi

Saat ini tersedia tiga strategi pengawasan berbeda untuk supervisor:

+ `:one_for_one` - Hanya memulai ulang proses anak yang gagal.
 
+ `:one_for_all` - Memulai ulang semua proses anak jika terjadi kegagalan.
 
+ `:rest_for_one` - Memulai ulang proses yang gagal dan semua proses yang dimulai setelahnya.

## Spesifikasi Anak

Setelah supervisor dimulai, ia harus mengetahui cara memulai/menghentikan/memulai ulang anak-anaknya.
Setiap modul anak harus memiliki fungsi `child_spec/1` untuk mendefinisikan perilaku ini.
Makro `use GenServer`, `use Supervisor`, dan `use Agent` secara otomatis mendefinisikan metode ini untuk kita (`SimpleQueue` memiliki `use GenServer`, jadi kita tidak perlu memodifikasi modul), tetapi jika Anda perlu mendefinisikannya sendiri, `child_spec/1` harus mengembalikan map opsi:

```elixir
def child_spec(opts) do
  %{
    id: SimpleQueue,
    start: {__MODULE__, :start_link, [opts]},
    shutdown: 5_000,
    restart: :permanent,
    type: :worker
  }
end
```

+ `id` - Kunci wajib.
  Digunakan oleh supervisor untuk mengidentifikasi spesifikasi anak.

+ `start` - Kunci wajib.
  Modul/Fungsi/Argumen yang akan dipanggil saat dimulai oleh supervisor.

+ `shutdown` - Kunci opsional.
  Mendefinisikan perilaku anak selama proses penghentian.

  Beberapa opsi:

  + `:brutal_kill` - Anak dihentikan segera.

  + `0` atau bilangan bulat positif - waktu dalam milidetik yang akan ditunggu supervisor sebelum menghentikan proses anak.

    Jika prosesnya bertipe `:worker`, `shutdown` secara default adalah `5000`.

  + `:infinity` - Supervisor akan menunggu tanpa batas waktu sebelum menghentikan proses anak.

    Default untuk tipe proses `:supervisor`.

    Tidak disarankan untuk tipe `:worker`.

  + `restart` - Kunci opsional.

    Ada beberapa pendekatan untuk menangani crash proses anak:

    + `:permanent` - Proses anak selalu dimulai ulang.
      Default untuk semua proses
    
    + `:temporary` - Proses anak tidak pernah dimulai ulang.
    
    + `:transient` - Proses anak hanya dimulai ulang jika berakhir secara tidak normal.

+ `type` - Kunci opsional.
  Proses dapat berupa `:worker` atau `:supervisor`.
  Defaultnya adalah `:worker`.

## DynamicSupervisor

Supervisor biasanya dimulai dengan daftar proses anak yang akan dijalankan saat aplikasi dimulai.
Namun, terkadang proses anak yang diawasi tidak diketahui saat aplikasi kita dimulai (misalnya, kita mungkin memiliki aplikasi web yang memulai proses baru untuk menangani pengguna yang terhubung ke situs kita).
Untuk kasus-kasus ini, kita memerlukan supervisor di mana proses anak dapat dijalankan sesuai permintaan.
DynamicSupervisor digunakan untuk menangani kasus ini.

Karena kita tidak akan menentukan proses anak, kita hanya perlu mendefinisikan opsi runtime untuk supervisor.
DynamicSupervisor hanya mendukung strategi supervisi `:one_for_one`:

```elixir
options = [
  name: SimpleQueue.Supervisor,
  strategy: :one_for_one
]

DynamicSupervisor.start_link(options)
```

Kemudian, untuk memulai SimpleQueue baru secara dinamis, kita akan menggunakan `start_child/2` yang membutuhkan supervisor dan spesifikasi child (sekali lagi, `SimpleQueue` menggunakan `use GenServer` sehingga spesifikasi child sudah ditentukan):

```elixir
{:ok, pid} = DynamicSupervisor.start_child(SimpleQueue.Supervisor, SimpleQueue)
```

## Supervisor untuk Task

Setiap Task memiliki Supervisor khusus, yaitu `Task.Supervisor`.
Dirancang untuk tugas yang dibuat secara dinamis, supervisor ini menggunakan `DynamicSupervisor` di baliknya.

### Setup

Menambahkan `Task.Supervisor` tidak berbeda dengan supervisor lainnya:

```elixir
children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Perbedaan utama antara `Supervisor` dan `Task.Supervisor` adalah strategi restart default-nya adalah `:temporary` (tugas tidak akan pernah di-restart).

### Task yang Disupervisi

Setelah supervisor dijalankan, kita dapat menggunakan fungsi `start_child/2` untuk membuat tugas yang diawasi:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

Jika task kita mengalami crash sebelum waktunya, task tersebut akan dijalankan ulang untuk kita.
Ini sangat berguna saat bekerja dengan koneksi masuk atau memproses pekerjaan latar belakang.
