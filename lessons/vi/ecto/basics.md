%{
  version: "0.9.1",
  title: "Basics",
  excerpt: """
  Ecto là một dự án chính thức của Elixir cung cấp một database wrapper (tạm dịch: lớp bọc cho cơ sở dữ liệu) và ngôn ngữ truy vấn tích hợp. Với Ecto ta có thể tạo các migration, định nghĩa model, ghi và cập nhật các bản ghi, và truy vấn chúng.
  """
}
---

## Cài đặt

Để bắt đầu ta cần thêm Ecto và một database adapter trong file `mix.exs` của dự án. Bạn có thể tìm thấy một danh sách database adapter được hỗ trợ trong phần [Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage) trong Ecto README. Trong ví dụ này ta sẽ dùng PostgreSQL:

```elixir
defp deps do
  [{:ecto, "~> 2.1.4"}, {:postgrex, ">= 0.13.2"}]
end
```

Bây giờ ta có thể thêm Ecto và adapter vào danh sách trong `application`:

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### Repository

Trước hết ta cần tạo repository (database wrapper) của dự án bằng cách dùng tác vụ `mix ecto.gen.repo -r FriendsApp.Repo`. Ta sẽ xem các tác vụ của Ecto sau. Repo của chúng ta có thể được tìm thấy ở `lib/<tên project>/repo.ex`

```elixir
defmodule FriendsApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### Supervisor

Khi đã tạo xong Repo ta cần cài đặt cây giám sát, thường nằm trong file `lib/<project name>.ex`.

Một điều quan trọng là ta phải cài đặt Repo là một supervisor với `supervisor/3` mà không phải `worker/3`. Thông thường nếu bạn sinh ứng dụng với tùy chọn `--sup` thì nó đã có sẵn:

```elixir
defmodule FriendsApp.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(FriendsApp.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: FriendsApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Để tìm hiểu kĩ hơn về supervisor, bạn có thêm xem lại bài [OTP Supervisors](../../advanced/otp-supervisors).

### Cấu hình

Để cấu hình Ecto ta cần thêm một chút vào file `config/config.exs`. Ở đây ta sẽ cung cấp các thông tin về repository, adapter, database và thông tin truy cập:

```elixir
config :example_app, FriendsApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Tác vụ Mix

Ecto cung cấp một loạt những tác vụ hữu ích để làm việc với database:

```shell
mix ecto.create         # Tạo database
mix ecto.drop           # Xóa database
mix ecto.gen.migration  # Sinh một migration mới cho repo
mix ecto.gen.repo       # Sinh một repo mới
mix ecto.migrate        # Chạy migration
mix ecto.rollback       # Rollback migration
```

## Migrations

Cách tốt nhất để tạo migration là dùng tác vụ `mix ecto.gen.migration <tên>`. Nếu bạn biết ActiveRecord thì cũng sẽ không lạ gì tác vụ này.

Ta hãy bắt đầu với một migration cho bảng user:

```elixir
defmodule FriendsApp.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:username, :string, unique: true)
      add(:encrypted_password, :string, null: false)
      add(:email, :string)
      add(:confirmed, :boolean, default: false)

      timestamps
    end

    create(unique_index(:users, [:username], name: :unique_usernames))
  end
end
```

Mặc định Ecto sẽ tạo một khóa chính tự động tăng (auto-incrementing primary key) tên là `id`. Ở đây ta dùng callback `change/0` nhưng Ecto cũng hỗ trợ `up/0` và `down/0` nếu như bạn muốn tùy chỉnh nhiều hơn.

Chắc bạn cũng có thể đoán được là `timestamps` sẽ giúp bạn tạo và quản lý `inserted_at` và `updated_at`.

Để chạy migration ta dùng lệnh `mix ecto.migrate`.

Để biết thêm về migration bạn có thể xem [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content) trên tài liệu chính thức.

## Models

Sau khi có migration ta có thể chuyển qua phần model. Model định nghĩa cấu trúc của bảng, các hàm bổ trợ, và changeset (tập thay đổi). Ta sẽ xem changeset ở phần tiếp theo.

Giờ ta sẽ xem model cho migration của chúng ta trông thế nào:

```elixir
defmodule FriendsApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username encrypted_password email)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:username)
  end
end
```

Cấu trúc schema mà ta định nghĩa trong model rất giống với những gì ta đã viết trong migration. Ngoài các trường trong database ta còn thêm hai trường ảo. Các trường ảo sẽ không được lưu vào database nhưng lại có ích trong một số trường hợp, ví dụ như validation (tạm dịch: kiểm tra lỗi). Chúng ta sẽ xem các trường ảo được dùng trong thực tế như thế nào trong phần [Changesets](#changesets).

## Truy vấn

Trước khi có thể truy vấn ta cần import các hàm hỗ trợ truy vấn vào. Ở đây ta có thể import `from/2`:

```elixir
import Ecto.Query, only: [from: 2]
```

Tài liệu chính thức có thể xem tại [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html).

### Cơ bản

Ecto cung cấp một DSL tuyệt vời để ta viết truy vấn một các rõ ràng. Để tìm username của tất cả các tài khoản đã xác nhận ta có thể viết như sau:

```elixir
alias FriendsApp.{Repo, User}

query =
  from(
    u in User,
    where: u.confirmed == true,
    select: u.username
  )

Repo.all(query)
```

Ngoài `all/2`. Repo còn cung cấp một số hàm callback như `one/2`, `get/3`, `insert/2`, and `delete/2`. Bạn có thể đọc danh sách callback hoàn chỉnh tại [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks).

### Count

Nếu muốn đếm số người dùng đã xác nhận tài khoản ta có thể dùng `count/1`:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

Hoặc hàm `count/2` nếu bạn muốn đếm các giá trị riêng biệt trong một tập xác định:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id, :distinct)
  )
```

### Group By

Để gom các người dùng theo trạng thái xác nhận của họ, ta có thể dùng tùy chọn `group_by`:

```elixir
query =
  from(
    u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]
  )

Repo.all(query)
```

### Order By

Sắp xếp người dùng theo ngày tạo tài khoản của họ:

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

Để sắp theo thứ tự từ lớn đến bé:

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### Joins

Ví dụ như ta có bảng Profile liên kết với User, ta hãy tìm tất cả thông tin tài khoản của các tài khoản đã xác nhận:

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### Fragments

Đôi lúc nếu ta cần các hàm có sẵn trong cơ sở dữ liệu thì các hàm hỗ trợ Query sẽ là không đủ. Hàm `fragment/1` sẽ giúp ta làm điều đó:

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

Các ví dụ truy vấn khác bạn có thể xem tại [Ecto.Query.API](http://hexdocs.pm/ecto/Ecto.Query.API.html).

## Changesets

Ở phần trước ta đã học cách để lấy dữ liệu, những làm sao để ghi và cập nhật nó? Để làm việc đó ta cần Changeset.

Changeset đóng vai trò lọc, kiểm tra, và giữ các ràng buộc khi thay đổi model.

Với ví dụ này ta sẽ tập trung vào changeset cho việc tạo tài khoản người dùng. Ta sẽ sửa model của chúng ta một chút:

```elixir
defmodule FriendsApp.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username email password password_confirmation)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:password, min: 8)
    |> validate_password_confirmation()
    |> unique_constraint(:username, name: :email)
    |> put_change(:encrypted_password, hashpwsalt(params[:password]))
  end

  defp validate_password_confirmation(changeset) do
    case get_change(changeset, :password_confirmation) do
      nil ->
        password_incorrect_error(changeset)

      confirmation ->
        password = get_field(changeset, :password)
        if confirmation == password, do: changeset, else: password_mismatch_error(changeset)
    end
  end

  defp password_mismatch_error(changeset) do
    add_error(changeset, :password_confirmation, "Passwords does not match")
  end

  defp password_incorrect_error(changeset) do
    add_error(changeset, :password, "is not valid")
  end
end
```

Ta đã nâng cấp hàm `changeset/2` và thêm vào ba hàm tiện ích: `validate_password_confirmation/1`, `password_mismatch_error/1` và `password_incorrect_error/1`.

Đúng như nghĩa đen của cái tên, `changeset/2` tạo ra một changeset mới cho chúng ta. Trong đó ta dùng hàm `cast/4` để chuyển các tham số thành changeset từ một tập các trường bắt buộc và không bắt buộc. Sau đó ta kiểm tra điều kiện độ dài của chuỗi mật khẩu của changeset, ta dùng hàm của riêng mình để kiểm tra liệu việc xác nhận mật khẩu đã chính xác, và ta kiểm tra liệu username có bị trùng lặp. Cuối cùng ta cập nhận trường mật khẩu thật sự. Ở đây ta dùng hàm `put_change/3` để cập nhật một giá trị trong changeset.

Dùng `User.changeset/2` nhìn cũng khá đơn giản:

```elixir
alias FriendsApp.{User, Repo}

pw = "passwords should be hard"

changeset =
  User.changeset(%User{}, %{
    username: "doomspork",
    email: "sean@seancallan.com",
    password: pw,
    password_confirmation: pw
  })

case Repo.insert(changeset) do
  {:ok, model}        -> # Inserted with success
  {:error, changeset} -> # Something went wrong
end
```

Xong rồi! Và bây giờ bạn đã sẵn sàng để lưu dữ liệu rồi đấy.
