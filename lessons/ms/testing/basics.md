%{
  version: "0.9.0",
  title: "Pengujian",
  excerpt: """
  Pengujian adalah aspek penting di dalam pembangunan perisian.  Di dalam pelajaran ini kita akan melihat bagaimana untuk menguji kod Elixir kita menggunakan ExUnit dan juga beberapa amalan terbaik untuk melaksanakannya.
  """
}
---

## ExUnit

Kerangka pegujian yang telah disiap-pasang oleh Elixir ialah ExUnit dan ia mengandungi semua yang kita perlukan untk membuat pengujian kod yang teliti.  Sebelum kita teruskan, penting untuk diperhatikan bahawa ujian-ujian diimplementasikan sebagai skrip Elixir jadi kita perlu gunakan sambungan fail `.exs`.
Sebelum kita boleh menjalankan ujian, kita hendaklah menjalankan ExUnit menggunakan `ExUnit.start()`, ianya selalu dilakukan di dalam `test/test_helper.exs`.

Apabila kita menjana projek contoh di dalam pelajaran lepas, mix telah membuat satu ujian mudah untuk kita, yag boleh dijumpai di dalam `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

Kita boleh jalankan ujian-ujian untuk projek kita dengan `mix.test`.  Jika lakukan itu sekarang kita akan mendapat paparan seperti berikut:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

Jika anda pernah menulis ujian-ujian sebelum ini anda akan mengenali `assert`; di dalam beberapa kerangka lain ia dikenali sebagai `should` atau `expect`.

Kita gunakan makro `assert` untuk menguji jika ungkapan tersebut ialah benar.  Jika ungkapan itu tidak benar, satu ralat akan ditimbulkan dan ujian kita akan gagal.  Untuk menguji kegagalan kita akan ubahkan contoh kita dan kemudian jalankan `mix.test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

Sekarang kita sepatutnya akan melihat paparan yang berbeza:

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

ExUnit akan memberitahu dengan jelas di mana penerapan kita gagal, nilai yang dijangkakan, dan nilai sebenar.

### refute

`refute` kepada `assert` adalah sama dengan `unless` kepada `if`.  Gunakan `refute` apabila anda mahu pastikan satu kenyataan itu sentiasa tidak benar.

### assert_raise

Kadang-kadang ianya perlu untuk menerapkan bahawa satu ralat telah ditimbulkan, kita boleh lakukan ini dengan `assert_raise`.  Kita akan melihat contoh `assert_raise` di dalam pelajaran Plug.

## Penyediaan Ujian

Kadang-kala ada keperluan untuk melakukan penyediaan sebelum menjalankan ujian-ujian kita.  Untuk melaksanakannya kita boleh gunakan makro-makro `setup` dan `setup_all`.  `setup` akan dijalankan sebelum setiap ujian dan `setup_all` akan dijalankan sekali sahaja sebelum sekumpulan ujian.  Ia dijangkakan untuk memulangkan satu tuple `{:ok, state}`, di mana 'state' akan sedia untuk kegunaan ujian-ujian kita.

Sebagai contoh, kita akan tukarkan kod kita untuk gunakan `setup_all`:

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

Jawapan mudah untuk kegunaan 'mocking' di dalam Elixir: jangan.  Anda mungkin sudah terbiasa untuk menggunakan 'mock' tetapi ianya amat tidak digalakkan oleh komuniti Elixir dan ada sebab-sebab baik untuknya.  Jika anda ikut prinsip amalan baik rekabentuk, kod yang dihasilkan akan lebih mudah untuk diuji sebagai komponen-komponen individu.
