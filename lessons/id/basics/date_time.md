%{
  version: "1.2.0",
  title: "Date and Time",
  excerpt: """
  Working with time in Elixir.
  """
}
---

## Time

Elixir memiliki beberapa modul untuk bekerja dengan waktu.
mari kita mulai dengan mendapatkan waktu saat ini:

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Sebagai catatan kita memiliki *sigil* yang dapat digunakan juga untuk untuk membuat *struct* `Time` :

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

Anda dapat mempelajari lebih lanjut tentang *sigils* pada link berikut [sigils](/en/lessons/basics/sigils).
Berikut adalah contoh betapa mudahnya mengakses bagian-bagian dari *struct* *sigils* ini:

```elixir
iex> t = ~T[19:39:31.056226]
~T[19:39:31.056226]
iex> t.hour
19
iex> t.minute
39
iex> t.day
** (KeyError) key :day not found in: ~T[19:39:31.056226]
```
Tetapi ada masalah: seperti yang mungkin Anda perhatikan, *struct* ini hanya berisi waktu dalam sehari, tidak ada data hari/bulan/tahun..

## Date

Berlawanan dengan `Time`, *struct* `Date` memiliki info tentang tanggal, tanpa info tentang waktu.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

Dan *struct* `Date` memiliki beberapa fungsi yang berguna untuk bekerja dengan tanggal

```elixir
iex> {:ok, date} = Date.new(2020, 12, 12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1` menghitung hari apa dalam seminggu pada tanggal tertentu.
Dalam hal ini hari Sabtu.
`leap_year?/1` memeriksa apakah ini tahun kabisat.
Fungsi lainnya dapat ditemukan di [doc](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

Ada dua jenis *struct* yang berisi tanggal dan waktu sekaligus di Elixir.
Yang pertama adalah `NaiveDateTime` yang memiliki kekurangan dalam dukungan zona waktu.

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2022-01-21 19:55:10.008965]
```

Tetapi memiliki waktu dan tanggal, sehingga Anda dapat bermain dengan menambahkan waktu, misalnya:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

Yang kedua, seperti yang mungkin sudah Anda duga dari judul bagian ini, adalah `DateTime`.
Itu tidak memiliki batasan yang dicatat dalam `NaiveDateTime`: ia memiliki waktu dan tanggal, dan mendukung zona waktu.
Tapi waspadalah tentang zona waktu. Dokumen resmi menyatakan:

> Many functions in this module require a time zone database. By default, it uses the default time zone database returned by `Calendar.get_time_zone_database/0`, which defaults to `Calendar.UTCOnlyTimeZoneDatabase` which only handles "Etc/UTC" datetimes and returns `{:error, :utc_only_time_zone_database}` for any other time zone.

Perhatikan bahwa Anda dapat membuat instance DateTime dari NaiveDateTime, hanya dengan memberikan zona waktu:

```elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## Bekerja dengan Zona Waktu

Seperti yang telah kami catat di bagian sebelumnya, secara default Elixir tidak memiliki data zona waktu.
Untuk mengatasi masalah ini, kita perlu menginstal dan menyiapkan paket [tzdata](https://github.com/lau/tzdata).
Setelah menginstalnya, Anda harus mengonfigurasi Elixir secara global untuk menggunakan `Tzdata` sebagai basis data zona waktu:

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

Sekarang mari kita coba membuat waktu dalam zona waktu Paris dan mengubahnya menjadi waktu New York:

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

Seperti yang Anda lihat, waktu berubah dari 12:00 waktu Paris menjadi 6:00, yang berarti benar karena perbedaan waktu antara kedua kota adalah 6 jam.

Ini dia! Jika Anda ingin bekerja dengan fungsi lanjutan lainnya, Anda mungkin ingin mempertimbangkan untuk melihat lebih jauh ke dalam dokumen untuk [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html) dan [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html)
Anda mungkin juga ingin mempertimbangkan [Timex](https://github.com/bitwalker/timex) dan [Calendar](https://github.com/lau/calendar) yang merupakan *library* yang cukup bagus untuk bekerja dengan waktu di Elixir.
