%{
  version: "0.9.0",
  title: "Testing",
  excerpt: """
  Testing adalah bagian yang penting dalam mebuat software.  Di dalam pelajaran ini kita akan melihat cara melakukan tes pada code Elixir kita menggunakan ExUnit dan beberapa best practice untuk mengerjakannya.
  """
}
---

## ExUnit

Test framework bawaan Elixir adalah ExUnit yang berisi semua yang kita butuhkan untuk menguji code kita secara menyeluruh.  Sebelum melanjutkan, perlu dicatat bahwa test diimplementasikan sebagai script Elixir sehingga kita perlu menggunakan ekstensi `.exs`.  Sebelum kita bisa menjalankan test kita, kita perlu memulai ExUnit dengan perintah `ExUnit.start()`, paling sering dijalankan dalam `test/test_helper.exs`.

Ketika kita membuat project contoh kita di pelajaran lalu, mix cukup membantu dengan membuatkan sebuah tes sederhana untuk kita, dapat dilihat di `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

Kita bisa menjalankan tes di project kita dengan `mix test`.  Jika kita lakukan itu sekarang kita mestinya melihat output seperti berikut:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

Kalau anda sudah pernah menulis tes sebelumnya, anda pasti sudah kenal dengan `assert`; dalam beberapa framework `should` atau `expect` dipakai sebagai ganti `assert`.

Kita menggunakan macro `assert` untuk menguji bahwa sebuah expression adalah benar.  Jika terjadi sebaliknya, sebuah error dihasilkan dan tes kita akan gagal.  Untuk mencoba sebuah kegagalan, mari coba ganti sample kita dan lalu jalankan `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

Sekarang kita mestinya melihat sebuah output yang berbeda:

```shell
  1) test the truth (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/example_test.exs:6

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

ExUnit akan menunjukkan di mana gagalnya, apa value yang diharapkan dan apa yang aktual.

### refute

`refute` terhadap `assert` itu seperti `unless` terhadap `if`.  Gunakan `refute` ketika anda ingin memastikan bahwa sebuah expression selalu bernilai salah.

### assert_raise

Kadang perlu untuk memastikan bahwa sebuah error telah muncul, kita dapat melakukannya dengan `assert_raise`.  Kita akan lihat sebuah contoh `assert_raise` di pelajaran berikutnya tentang Plug.

## Test Setup

Dalam beberapa situasi bisa jadi diperlukan untuk melakukan setup sebelum menjalankan test kita.  Untuk mencapai hal ini kita bisa gunakan macro `setup` dan `setup_all`.  `setup` akan dijalankan sebelum tiap test dan `setup_all` dijalankan sekali sebelum keseluruhannya dijalankan.  Diharapkan keduanya mengembalikan tuple `{:ok, state}`, state tersebut akan bisa diakses untuk test kita.

Sebagai contoh, kita ubah code kita untuk menggunakan `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```

## Mocking

Jawaban sederhana untuk mocking dalam Elixir: jangan lakukan.  Anda mungkin terbiasa menggunakan mock tapi mock sangat tidak disukai dalam komunitas Elixir dan untuk alasan yang benar.  Jika anda mengikuti prinsip disain yang baik, code yang dihasilkan akan mudah dites sebagai komponen yang mandiri.

Lawanlah godaan ini.

