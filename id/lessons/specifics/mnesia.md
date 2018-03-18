---
version: 0.9.0
title: Mnesia
---

Mnesia adalah sebuah sistem manajemen database terdistribusi real-time yang kuat.


{% include toc.html %}

## Sekilas

Mnesia adalah sebuah Sistem Manajemen Database (DBSM) yang disertakan bersama Erlang Runtime System yang tentu saja bisa kita gunakan dengan Elixir. *Model data hibrid antara relasional  dan object* Mnesia adalah apa yang membuatnya cocok untuk membuat aplikasi terdistribusi pada skala apapun.

## Kapan Digunakan

Kapan kita menggunakan sebuah teknologi seringkali jadi masalah yang membingungkan.  Jika anda bisa menjawab 'ya' pada satu saja pertanyaan berikut, maka ini adalah indikasi bagus untuk menggunakan Mnesia sebagai ganti ETS atau DETS.

  - Apakah aku perlu membalikkan (roll back) transaksi?
  - Apakah aku perlu sebuah sintaks yang mudah digunakan untuk membaca dan menulis data?
  - Apakah aku perlu menyimpan data lintas node, dan tidak hanya satu node?
  - Apakah aku perlu bisa memilih di mana informasi disimpan (RAM atau disk)?

## Schema

Karena Mnesia adalah bagian dari Erlang core, bukannya Elixir, kita harus mengaksesnya dengan sintaks colon (Lihat Pelajaran: [Erlang Interoperability](../../advanced/erlang/)) seperti ini:

```shell

iex> :mnesia.create_schema([node()])

# atau jika anda lebih suka rasa Elixir...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

Untuk pelajaran ini, kita akan mengambil pendekatan yang terakhir ketika bekerja dengan API Mnesia. `Mnesia.create_schema/1` menginisialisasikan sebuah schema kosong yang baru dan memasukkan sebuah Node List. Dalam kasus ini, kita memasukkan node yang terasosiasikan dengan sesi IEx kita.

## Node

Begitu kita sudah menjalankan perintah `Mnesia.create_schema([node()])` via IEx, anda mestinya melihat sebuah folder bernama **Mnesia.nonode@nohost** atau yang serupa di dalam direktori kerja yang sekarang ada.  Anda mungkin bertanya-tanya apa artinya **nonode@nohost** karena sebelumnya kita belum pernah melihatnya. Mari kita lihat. 

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

Ketika kita berikan opsi `--help` ke IEx dari command line kita ditunjuki semua opsi yang mungkin. Kita bisa melihat bahwa ada opsi `--name` dan `--sname` untuk memberikan informasi ke node. Sebuah node hanyalah sebuah Erlang Virtual Machine yang sedang berjalan yang menangani sendiri komunikasi, pembersihan sampah (garbage collection), penjadwalan, memori, dan lain-lain. Secara default node dinamai **nonode@nohost**.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Sebagaimana bisa kita lihat, node yang sedang kita jalankan adalah sebuah atom bernama `:"learner@elixirschool.com"`. Kalau kita jalankan `Mnesia.create_schema([node()])` lagi, kita akan lihat bahwa ia membuat folder lagi bernama **Mnesia.learner@elixirschool.com**. Tujuan dari hal ini adalah sederhana. Node di Erlang digunakan untuk mengkoneksi ke node lain untuk berbagi (distribusi) informasi dan sumber daya (resource). Hal ini tidak harus dibatasi pada mesin yang sama dan dapat berkomunikasi lewat LAN, internet, dan lain-lain.

## Menjalankan Mnesia

Sekarang setelah kita mahami dasar-dasarnya dan sudah mensetup databasenya, kita sekarang bisa jalankan DBMS Mnesia dengan perintah ```Mnesia.start/0``` command.

```shell
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

Patut diingat ketika menjalankan sebuah sistem terdistribusi dengan dua node atau lebih, fungsi `Mnesia.start/1` harus dijalankan pada semua node yang berpartisipasi.

## Membuat Tabel

Fungsi `Mnesia.create_table/2` digunakan untuk membuat tabel dalam database kita. Di bawah ini kita membuat tabel bernama `Person` dan kemudian memasukkan keyword list yang mendefinisikan schema tabelnya.

```shell
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Kita mendefinisikan kolom-kolom menggunakan atom-atom `:id`, `:name`, dan `:job`. Ketika kita menjalankan `Mnesia.create_table/2`, fungsi tersebut akan mengembalikan salah satu dari respons berikut:

 - `{:atomic, :ok}` jika fungsi tersebut selesai dengan baik
 - `{:aborted, Reason}` jika fungsi tersebut gagal

## Cara yang Kotor

Pertama-tama kita akan melihat cara yang kotor untuk membaca dan menulis ke sebuah tabel Mnesia.  Hali ini secara umum mesti dihindari karena tidak dijamin berhasil, tetapi ini dapat menolong kita mempelajari dan menjadi terbiasa bekerja dengan Mnesia. MAri tambahkan beberapa etri ke tabel **Person** kita.

```shell
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...dan untuk mengambil entri-entri tersebut kita bisa gunakan `Mnesia.dirty_read/1`:

```shell
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

Kalau kita coba melakukan query ke sebuah record yang tidak ada Mnesia akan merespon dengan sebuah list kosong.

## Transaksi

Secara tradisional kita menggunakan **transaksi** untuk mengenkapsulasi pembacaan dan penulisan kita ke database. Transaksi adalah bagian yang penting dalam mendisain sistem sangat terdistribusi yang toleran terhadap kegagalan. Sebuah transaksi Mnesia adalah *sebuah mekanisme yang melaluinya serangkaian operasi database bisa dieksekusi sebagai sebuah blok fungsional*. Pertama-tama kita membuat sebuah fungsi anonim, dalam hal ini `data_to_write` dan kemudian memasukkannya ke `Mnesia.transaction`.

```shell
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```
Berdasarkan pesan transaksi ini, kita bisa dengan aman mengasumsikan bahwa kita telah menuliskan data ke tabel `Person` kita.  Mari kita gunakan transaksi untuk membaca dari database untuk memastikan. Kita akan gunakan `Mnesia.read/1` untuk membaca dari database, tetapi sekali lagi dari sebuah fungsi anonim.

```shell
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```
