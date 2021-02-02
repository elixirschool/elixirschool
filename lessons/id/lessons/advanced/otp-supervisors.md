%{
  version: "0.9.1",
  title: "OTP Supervisors",
  excerpt: """
  Supervisor adalah proses khusus yang memiliki satu peran: memonitor proses lain. Supervisor ini memungkinkan kita membuat aplikasi yang toleran-kegagalan (fault-tolerant) dengan secara otomatis menjalankan ulang proses anak (child process) jika proses anak itu fail (mengalami kegagalan).
  """
}
---

## Konfigurasi

Inti Supervisor adalah fungsi `Supervisor.start_link/2`.  Di samping menjalankan supervisor kita dan anak-anaknya, fungsi ini juga memungkinkan kita mendefinisikan strategi yang digunakan supervisor kita untuk mengatur proses-proses anak.

Proses-proses anak didefinisikan menggunakan sebuah list dan fungsi `worker/3` yang kita import dari `Supervisor.Spec`.  Fungsi `worker/3` ini menerima sebuah modul, argumen, dan sekumpulang opsi.  Di dalamnya `worker/3` memanggil `start_link/3` dengan argumen-argumen kita dalam inisialisasi.

Menggunakan SimpleQueue dari pelajaran [OTP Concurrency](../../advanced/otp-concurrency) mari kita mulai:

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], name: SimpleQueue)
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Jika proses kita crash atau diterminasi Supervisor kita akan secara otomatis menjalankan ulang seakan tidak ada yang terjadi.

### Strategi

Saat ini ada empat strategi penjalanan ulang yang tersedia untuk supervisor:

+ `:one_for_one` - Hanya jalankan ulang proses anak yang gagal.

+ `:one_for_all` - Jalankan ulang semua proses anak jika satu gagal.

+ `:rest_for_one` - Jalankan ulang proses yang gagal dan semua proses yang dijalankan setelahnya.

+ `:simple_one_for_one` - Pilihan terbaik untuk proses anak yang dipasangkan secara dinamis (dynamically attached). Supervisor hanya bisa mengurus satu anak.

### Nesting

Di samping proses pekerja (worker process), kita juga bisa mensupervisi supervisor lain untuk membuat sebuah pohon supervisor (supervisor tree).  Satu-satunya perbedaan adalah menggantikan `worker/3` dengan `supervisor/3`:

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Supervisor untuk Task

Task punya Supervisornya sendiri, `Task.Supervisor`.  Didesain untuk task yang dibuat secara dinamis, supervisor ini menggunakan `:simple_one_for_one` di dalamnya.

### Setup

Menggunakan `Task.Supervisor` tidak beda dengan supervisor lain:

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

### Task yang Disupervisi

Setelah supervisor dijalankan kita bisa menggunakan fungsi `start_child/2` untuk membuat task yang disupervisi:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

Jika task kita crash sebelum waktunya, task itu akan dijalankan ulang (restart) untuk kita.  Ini khususnya bisa berguna ketika bekerja dengan koneksi yang datang atau memproses pekerjaan di belakang layar (background work).
