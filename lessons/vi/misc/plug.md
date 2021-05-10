%{
  version: "0.10.0",
  title: "Plug",
  excerpt: """
  Nếu bạn biết Ruby bạn có thể nghĩ Plug như là Rack với một chút Sinatra. Nó cung cấp một đặc tả cho các thành phần ứng dụng web và kết nối nó với web servers. Tuy không nằm trong phần cốt lõi nhưng Plug là một dự án chính thức của Elixir.
  """
}
---

## Cài đặt

Cài đặt Plug với Mix khá đơn giản. Để cài đặt ta chỉ cần thay đổi hai chỗ trong file `mix.exs`. Đầu tiên là thêm Plug và một web server nào đó (ở đây ta dùng Cowboy) làm thư viện.

```elixir
defp deps do
  [{:cowboy, "~> 1.1.2"}, {:plug, "~> 1.3.4"}]
end
```

Cuối cùng là thêm cả web server lẫn Plug vào ứng dụng OTP.

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## Đặc tả

Trước khi tạo ra các plug thì ta cần biết về đặc tả của Plug. Nó chỉ gồm hai hàm chủ yếu: `init/1` và `call/2`.

Hàm `init/1` được dùng để khởi tạo các tùy chọn cho Plug, thứ mà sau đó sẽ được truyền vào hàm `call/2` như là tham số thứ hai. Ngoài tùy chỉnh khởi tạo đó, hàm `call/2` còn nhận tham số đầu tiên có kiểu là `%Plug.Conn` và hàm này sẽ trả phải về một kết nối.

Dưới đây là một Plug đơn giản trả về dòng chữ "Hello World!":

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

## Tạo một Plug

Với ví dụ này ta sẽ viết một Plug để kiểm tra request có các tham số bắt buộc chưa. Cài đặt việc kiểm tra trong một Plug ta có thể biết chắc rằng chỉ có những request hợp lệ mới được đi vào ứng dụng. Plug của chúng ta sẽ được khởi tạo với hai tùy chọn: `:paths` và `:fields`. Chúng đại diện cho các đường dẫn mà ta sẽ áp dụng các logic vào và các trường cần thiết.

_Chú ý_: Plug được chạy cho tất cả request, đó là lý do vì sao ta phải lọc request và áp dụng logic vào phần đã được lọc. Để bỏ qua một request nào đó ta chỉ cần đơn giản trả về kết nối.

Ta sẽ bắt đầu xem một Plug hoàn chỉnh và sau đó tìm hiểu cách nó hoạt động. Ta sẽ viết nó ở file `lib/example/plug/verify_request.ex`:

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

Đầu tiên ta định nghĩa ra một kiểu lỗi mới tên `IncompleteRequestError` và một trong những tùy chọn của nó là `:plug_status`. Tùy chọn này sẽ được Plug dùng để cài đặt _HTTP status code_ trong trường hợp có lỗi.

Phần thứ hai của Plug là hàm `call/2`. Đây là nơi mà ta quyết định xem có áp dụng logic của chúng ta vào không. Chỉ khi nào request có chứa đường dẫn trong tùy chọn `:paths` ta mới gọi `verify_request!/2`.

Phần cuối là hàm private `verify_request!/2`, nó sẽ kiểm tra liệu các trường bắt buộc đã có đầy đủ trong `:fields` chưa. Trong trường hợp bị thiếu, ta sẽ văng lỗi `IncompleteRequestError`.

## Dùng Plug.Router

Giờ ta đã có plug tên là `VerifyRequest`, ta có thể tiếp tục đi vào router (tạm dịch: bộ định tuyến). Với Plug thì trong Elixir ta không cần một framework như Sinatra nữa.

Để bắt đầu ta tạo một file `lib/plug/router.ex` và copy đoạn code ở dưới vào:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

Đây là một Router tối thiểu nhưng code đọc cũng khá dễ hiểu. Ta đã kèm vào một số macros thông qua `use Plug.Router` và sau đó dùng hai Plug có sẵn là `:match` và `:dispatch`. Có hai đường dẫn được định nghĩa ở đây, một để xử lý các request GET ở root và một để match các request còn lại và trả về lỗi 404.

Và ta thêm Plug của chúng ta vào router:

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

Xong! Ta đã cài đặt Plug của chúng ta để kiểm tra tất cả những request vào `/upload` để đảm bảo chúng có cả `"content"` lần `"mimetype"`. Kế đến ta sẽ chạy đoạn code router.

Lúc này thì đường dẫn `/upload` không thực sự hữu dụng lắm nhưng ta đã biết cách tạo và tích hợp Plug vào như thế nào.

## Chạy ứng dụng web

Trước khi ta có thể chạy ứng dụng ta cần cài đặt và cấu hình web server, ở đây là Cowboy. Hiện tại thì ta chỉ đủ viết code để chạy mọi thứ, ta sẽ tìm hiểu sâu hơn trong những bài học tiếp theo.

Ta hãy bắt đầu bằng cách chỉnh sửa phần `application` trong `mix.exs` để thông báo cho Elixir về ứng dụng của chúng ta và tạo một biến môi trường. Code của chúng trông như sau:

```elixir
def application do
  [applications: [:cowboy, :plug], mod: {Example, []}, env: [cowboy_port: 8080]]
end
```

Tiếp theo ta chỉnh `lib/example.ex` để bắt đầu và giám sát Cowboy:

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

> (Không bắt buộc) ta có thể thêm `:cowboy_port` vào `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Now to run our application we can use:

```shell
$ mix run --no-halt
```

## Kiểm thử Plug

Kiểm thử Plug khá đơn giản với `Plug.Test`. Nó chứa một số hàm tiện ích giúp việc kiểm thử trở nên dễ dàng.

Xem qua đoạn code kiểm thử router ở dưới đây nhé:

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

## Các Plug sẵn dùng

Có một số Plug đã được viết sẵn, danh sách hoàn chỉnh bạn có thể tìm thấy trong tài liệu của Plug [ở đây](https://github.com/elixir-lang/plug#available-plugs).
