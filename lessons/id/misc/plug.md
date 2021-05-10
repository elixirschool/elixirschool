%{
  version: "0.10.0",
  title: "Plug",
  excerpt: """
  Kalau anda familiar dengan Ruby anda bisa menganggap Plug seperti Rack dengan sedikit Sinatra.  Plug memberi spesifikasi untuk komponen aplikasi web dan adapter untuk web server. Walau bukan bagian Elixir core, Plug adalah sebuah project resmi Elixir.
  """
}
---

## Instalasi

Instalasi menggunakan Mix sangat mudah.  Untuk menginstal Plug kita perlu membuat dua perubahan kecil pada `mix.exs` kita.  Yang pertama perlu dilakukan adalah menambahkan Plug dan sebuah web server (kita akan pakai Cowboy) ke file kita sebagai dependensi:

```elixir
defp deps do
  [{:cowboy, "~> 1.1.2"}, {:plug, "~> 1.3.4"}]
end
```

Yang terakhir kita perlu lakukan adalah menambahkan web server kita dan Plug ke aplikasi OTP kita:

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## Spesifikasi

Untuk memulai membuat Plug, kita perlu tahu, dan menuruti, spesifikasi Plug.  Untungnya, hanya ada dua fungsi yang diperlukan: `init/1` dan `call/2`.

Fungsi `init/1` digunakan untuk menginisialisasi opsi-opsi Plug kita, yang dimasukan sebagai argumen kedua untuk fungsi `call/2` kita.  Di samping opsi inisialisasi itu fungsi `call/2` menerima sebuah `%Plug.Conn` sebagai argumen pertamanya dan mengembalikan sebuah connection.

Ini adalah sebuah Plug sederhana yang mengembalikan "Hello World!":

```elixir
defmodule HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!")
  end
end
```

## Membuat sebuah Plug

Untuk contoh ini kita akan membuat sebuah Plug untuk memverifikasi apakan request memiliki parameter yang dibutuhkan.  Dengan mengimplementasikan validasi kita dalam sebuah Plug kita bisa yakin bahwa request yang valid yang mencapai aplikasi kita.  Kita akan mempunyai ekspektasi bahwa Plug kita diinisialisasi dengan dua opsi: `:paths` dan `:fields`.  Kedua opsi ini akan merepresentasikan path yang akan kita terapkan logika kita atasnya dan field apa saja yang dibutuhkan.

_Catatan_: Plug diterapkan pada semua request sehingga kita akan menerapkan logika kita hanya pada sebagian dari request tersebut.  Untuk mengabaikan sebuah request kita hanya akan meneruskannya.

Kita akan mulai dengan melihat pada Plug kita yang sudah jadi dan kemudian mendiskusikan bagaimana ia bekerja.  Kita akan membuatnya di `lib/example/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  import Plug.Conn

  defmodule IncompleteRequestError do
    @moduledoc """
    Error raised when a required field is missing.
    """

    defexception message: "", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.body_params, opts[:fields])
    conn
  end

  defp verify_request!(body_params, fields) do
    verified =
      body_params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

Hal pertama yang perlu dicatat adalah bahwa kita telah mendefinisikan sebuah exception baru `IncompleteRequestError` dan bahwa salah satu opsinya adalah `:plug_status`.  Jika tersedia opsi ini digunakan oleh Plug untuk menset kode status HTTP jika terjadi exception.

Bagian kedua dari Plug kita adalah fungsi `call/2`.  Di sinilah kita memutuskan apakah akan menerapkan logika verifikasi kita atau tidak.  Hanya jika path dari request tersebut ada dalam opsi `:paths` kita sajalah kita akan memanggil `verify_request!/2`.

Bagian terakhir dari plug kita adalah fungsi privat `verify_request!/2` yang memverifikasi apakah `:fields` yang dibutuhkan semuanya ada.  Jika ada yang tidak ada, kita memunculkan exception `IncompleteRequestError`.

## Menggunakan Plug.Router

Sekarang setelah kita memiliki plug `VerifyRequest` kita, kita bisa lanjutkan ke router kita.  Sebagaimana akan kita lihat, kita tidak butuh sebuah framework seperti Sinatra dalam Elixir karena kita sudah dapatkan gratis dari Plug.

Untuk memulai mari buat sebuah file di `lib/plug/router.ex` dan salin code berikut ini:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

Ini adalah sebuah Router yang minimum tapi code nya mestinya sudah jelas.  Kita meng-include beberapa macro melalui `use Plug.Router` dan kemudian menset dua Plug yang built-in: `:match` dan `:dispatch`.  Ada dua route yang didefinisikan, satu untuk menangani request GET ke root dan yang kedua untuk menangani semua request lain sehingga kita bisa mengembalikan sebuah pesan 404.

Mari tambahkan Plug kita ke router tersebut:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias Example.Plug.VerifyRequest

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(
    VerifyRequest,
    fields: ["content", "mimetype"],
    paths: ["/upload"]
  )

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  post("/upload", do: send_resp(conn, 201, "Uploaded"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

Beres! Kita sudah mensetup Plug kita untuk memverifikasi bahwa semua request ke `/upload` menyertakan `"content"` dan `"mimetype"`.  Hanya jika itu terpenuhi route code nya dijalankan.

Sementara ini endpoint `/upload` kita tidak begitu berguna tetapi kita sudah melihat bagaimana membuat dan mengintegrasikan Plug kita.

## Menjalankan Web App Kita

Sebelum kita bisa menjalankan aplikasi kita kita perlu mensetup dan mengkonfigurasi web server kita, yang dalam hal ini adalah Cowboy.  Untuk saat ini kita akan hanya membuat perubahan code yang perlu untuk menjalankan semuanya, dan kita akan perdalam di pelajaran-pelajaran berikutnya.

Mari mulai dengan mengubah bagian `application` dari `mix.exs` kita untuk memberitahu Elixir tentang apliksi kita dan menset sebuah environment variable.  Dengan perubahan itu code kita seharusnya tampak seperti berikut:

```elixir
def application do
  [applications: [:cowboy, :plug], mod: {Example, []}, env: [cowboy_port: 8080]]
end
```

Kemudian kita perlu mengubah `lib/example.ex` untuk menjalankan dan mensupervisi Cowboy:

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Plug.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Lalu untuk menjalankan aplikasi kita kita bisa gunakan:

```shell
$ mix run --no-halt
```

## Menguji Plug

Menguji Plug adalah mudah berkat `Plug.Test`.  `Plug.Test` menyertakan sejumlah fungsi yang mempermudah pengujian.

Coba kita lihat apakah anda bisa pahami test router ini:

```elixir
defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Plug.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn =
      conn(:get, "/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      conn(:get, "/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

## Plug yang Tersedia

Ada sejumlah Plug yang sudah disertakan.  Daftar lengkapnya dapat dilihat di dokumentasi Plug [di sini](https://github.com/elixir-lang/plug#available-plugs).
