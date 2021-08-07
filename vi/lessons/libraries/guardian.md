---
version: 0.9.1
title: Guardian (Cơ bản)
---

[Guardian](https://github.com/ueberauth/guardian) là một thư viện xác thực danh tính người dùng được sử dụng rộng rãi dựa trên chuẩn [JWT](https://jwt.io/) (JSON Web Token).

{% include toc.html %}

## JWTs

Một JWT cung cấp một token với nhiều thông tin để xác thực danh tính người dùng. Trong khi nhiều hệ thống xác thực khác, chỉ cung cấp truy cập tới chủ thể của token, JWT còn cho chúng ta các thông tin khác như :

* Ai đã tạo token
* Token đó dùng cho ai
* Hệ thống nào sử dụng token
* Thời điểm issued được tạo
* Thời điểm issue hết hạn

Guardian cung cấp thêm một số tính năng khác như :

* Kiểu của token là gì
* Những hành vi nào được làm

Đây là các fields cơ bản trong JWT. Bạn tùy ý thêm bất cứ thông tin nào cần cho ứng dụng của bạn. Nhớ rằng, nên giữ cho JWT không có quá nhiều trường, để JWT có thể vừa vặn trong HTTP header.

Sự phong phú này cho phép bạn truyền JWTs khắp hệ thống của bạn.

### Sử dụng chúng ở đâu

JWT tokens có thể sử dụng xác thực danh tính ở bộ phận bất kỳ của ứng dụng.

* Các ứng dụng Single page
* Các controllers (qua phiên làm việc trình duyệt)
* Các controllers (qua authorization headers - API)
* Các kênh Phoenix
* Các request Service to service
* Inter-process
* Chứng thực bởi bên thứ 3
* Chức năng nhớ tự động
* Các giao diện khác - raw TCP, UDP, CLI, etc

JWT tokens có thể sử dụng ở bất cứ chỗ nào trong ứng dụng cần thực hiện hành vi xác thực danh tính.

### Tôi có sử dụng cho một cơ sở dữ liệu không?

Bạn không cần kiểm tra JWT qua một cơ sở dữ liệu. Cách đơn giản bạn dựa trên thời điểm tạo và thời điểm hết hạn để điều khiển truy cập. Thường thi bạn sẽ mở cơ sở dữ liệu để tra cứu người dùng nào đó nhưng JWT tự thân nó không cần điều này.

Ví dụ, nếu bạn sử dụng JWT để xác thực danh tính thông qua giao thức UDP, bạn có thể không cần dùng cơ sở dữ liệu. Nén tất cả thông tin bạn cần một cách trực tiếp vào token khi bạn khởi tạo nó. Sau đó bạn có thể kiểm tra tính hợp lệ của token bằng cách kiểm tra xem nó có được mã hoá đúng hay không.

Tuy nhiên bạn có thể sử dụng một cơ sở dữ liệu kiểm soát JWT. Nếu sử dụng cơ sở dữ liệu, bạn có khả năng kiểm tra xem token có còn hợp lệ hay không - tức là nó vẫn chưa bị huỷ bỏ. Hoặc bạn có thể sử dụng các bản ghi trong cơ sở dữ liệu để bắt tất cả các token của user 5 là sẽ bị log out. Điều này khá dễ dàng trong Guardian bởi sử dụng [GuardianDb](https://github.com/hassox/guardian_db). GuardianDb sử dụng Guardians 'Hooks' để thực hiện kiểm tra xác thực, lưu và xóa khỏi DB. Chúng ta sẽ đề cập nó sau.

## Thiết lập

Có nhiều lựa chọn cho việc thiết lập Guardian. Chúng ta đề cập tới chúng ở vài điểm nhưng chỉ ở mức rất đơn giản.

### Thiết lập tối giản

Để bắt đầu đơn giản bạn chỉ cần vài thứ.

#### Cấu hình

`mix.exs`

```elixir
def application do
  [
    mod: {MyApp, []},
    applications: [:guardian, ...]
  ]
end

def deps do
  [
    {guardian: "~> x.x"},
    ...
  ]
end
```

`config/config.exs`

```elixir
config :guardian, Guardian,
  issuer: "MyAppId",
  secret_key: Mix.env, # trong mỗi tệp tin cấu hình từng môi trường bạn nên ghi đè nó nếu nó là ngoại vi
  serializer: MyApp.GuardianSerializer
```

Đây chỉ là thiết lập ở mức tối thiểu để bạn sử dụng Guardian. Bạn không nên để khoá bí mật của bạn trực tiếp trong file config.exs. Thay vì đó, mỗi một trường nên có một khoá bí mật riêng. Điều này có thể thực hiện bằng cách thiết lập trong các file config/dev.exs, config/test.exs. Với môi trường staging và production, các khoá này cần phải là các khoá mạnh (e.g: sử dụng `mix phoenix.gen.secret` để sinh ra)

`lib/my_app/guardian_serializer.ex`

```elixir
defmodule MyApp.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias MyApp.Repo
  alias MyApp.User

  def for_token(user = %User{}), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("User:" <> id), do: {:ok, Repo.get(User, id)}
  def from_token(_), do: {:error, "Unknown resource type"}
end
```
Serializer của bạn đảm nhiệm phần tìm kiếm tài nguyên ở trong trường `sub` (subject). Nó có thể tìm trong DB, một API hoặc thậm chí trong nội dung một chuỗi đơn giản.
Nó cũng chịu trách nhiệm cho việc serializer các tài nguyên trong trường `sub`.

Đây là cấu hình đơn giản nhất, đủ để chúng ta bắt đầu. Trên thực tế, bạn có thể làm được rất nhiều thứ nếu bạn muốn.

#### Sử dụng trong ứng dụng

Lúc này chúng ta đã cấu hình xong Guardian, chúng ta cần tích hợp nó vào trong ứng dụng. Bởi vì đây chỉ là cấu hình đơn giản nhất, chúng ta sẽ bắt đầu bằng việc xem xét các request HTTP.

## Các yêu cầu trong giao thức HTTP

Guardian cung cấp một số Plugs để dễ dàng nhúng vào HTTP requests. Bạn có thể học về Plug tại đây [separate lesson](../../specifics/plug/). Guardian làm việc không nhất thiết cần Phoenix, nhưng chúng ta sử dụng Phoenix trong ví dụ dưới đây sẽ dễ dàng mô tả cách hoạt động.

Dễ nhất là sử dụng HTTP qua router - module route của Phoenix. Bởi vì Guardian tích hợp HTTP hoàn toàn dựa trên plugs, bạn có thể sử dụng nó bất kỳ chỗ nào có sử dụng plug.

Luồng tiến trình chung của Guardian plug là:

1. Tìm ra một token trong request và xác minh nó : `Verify*` plugs
2. Tìm ra tài nguyên tương ứng với mỗi token: `LoadResource` plug
3. Đảm bảo tính hợp lệ của token đó nếu không từ chối nó. `EnsureAuthenticated` plug

Để đáp ứng tất cả các nhu cầu của các nhà phát triển ứng dụng, Guardian hiện thực các pha riêng rẽ. Để tìm token sử dụng `Verify*` plugs.

Hãy cùng tạo một số pipelines.

```elixir
pipeline :maybe_browser_auth do
  plug(Guardian.Plug.VerifySession)
  plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
  plug(Guardian.Plug.LoadResource)
end

pipeline :ensure_authed_access do
  plug(Guardian.Plug.EnsureAuthenticated, %{"typ" => "access", handler: MyApp.HttpErrorHandler})
end
```

Các pipelines có thể được sử dụng để tạo các yêu cầu xác thực khác nhau. Pipeline thứ nhất cố gắng tìm kiếm ra token đầu tiên trong phiên làm việc, nếu không có, nó sẽ tìm token trong header. Nếu nó tìm thấy token, nó sẽ đọc/ghi các thông tin cho bạn.

Pipeline thứ 2 cần token hợp lệ, xác nhận hợp lệ token hiện tại và đánh dấu nó "access". Để sử dụng nó, ta thêm chúng vào scope.

```elixir
scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth])

  get("/login", LoginController, :new)
  post("/login", LoginController, :create)
  delete("/login", LoginController, :delete)
end

scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth, :ensure_authed_access])

  resource("/protected/things", ProtectedController)
end
```

Các login routes ở trên sẽ chứng thực danh tính của user nếu cùng một đối tượng. Scope thứ hai đảm bảo rằng có một token hợp lệ được truyền cho tất cả các actions.
Bạn không nhất thiết phải đặt chúng trong các pipelines. Bạn có thể đặt chúng trong các controller để có thể tuỳ biến một cách linh hoạt, tuy nhiên, ở đây chúng ta đã sử dụng cấu hình đơn giản nhất.

Chúng ta chưa nói phần mã sau này dùng. Đó là bắt các lỗi xảy ra khi ấy thêm `EnsureAuthenticated` plug. Đây là một module rất đơn giản trả về tới user

* `unauthenticated/2`
* `unauthorized/2`

Cả hai chức năng nhận một struct Plug.Conn và các parameter đầu vào sẽ có các lỗi tương ứng xảy ra. Bạn thậm chí có thể sử dụng một Phoenix controller!

#### Bên trong controller

Bên trong controller, để truy cập vào user hiện tại đang logged in, chúng ta có một vài cách. Hãy bắt đầu với cách đơn giản nhất.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller
  use Guardian.Phoenix.Controller

  def some_action(conn, params, user, claims) do
    # làm gì đó
  end
end
```

Bằng việc sử dụng `Guardian.Phoenix.Controller` module, các action sẽ nhận 2 tham trị mà bạn tùy ý sử dụng pattern match cho chúng. Nên nhớ, nếu bạn không sử dụng `EnsureAuthenticated` bạn có thể nhận giá trị nil cho user và claims.

Mặt khác - chúng ta có cách viết lắt léo/rườm rà hơn sau - là để sử dụng plug helpers.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller

  def some_action(conn, params) do
    if Guardian.Plug.authenticated?(conn) do
      user = Guardian.Plug.current_resource(conn)
    else
      # Không phải user
    end
  end
end
```

#### Đăng nhập/Thoát

Đăng nhập và thoát của phiên làm việc trên trình duyệt là rất đơn giản. Trong controller login ta viết như sau:

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      # Ở đây ta dùng access. Các token khác có thể sử dụng, như :resfresh vân vân
      conn
      |> Guardian.Plug.sign_in(user, :access)
      |> respond_somehow()

    {:error, reason} ->
      nil
      # xử lý xảy ra lỗi xác minh user
  end
end

def delete(conn, params) do
  conn
  |> Guardian.Plug.sign_out()
  |> respond_somehow()
end
```

Khi sử dụng API đăng nhập, nó có chút khác biệt bởi vì ở đó không có dựa trên session và bạn cần cung cấp một raw token - token gốc trở về lại cho người dùng. Hàm này tiện lợi khi bạn không có ý định cho việc sử dụng một session.

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      {:ok, jwt, _claims} = Guardian.encode_and_sign(user, :access)

      conn
      |> respond_somehow(%{token: jwt})

    {:error, reason} ->
      nil
      # xử lý xảy ra lỗi xác minh user
  end
end

def delete(conn, params) do
  jwt = Guardian.Plug.current_token(conn)
  Guardian.revoke!(jwt)
  respond_somehow(conn)
end
```

Bản chất việc session đăng nhập trình duyệt gọi `encode_and_sign` vẫn thế vì vậy bạn có thể sử dụng chúng khá tương tự.
