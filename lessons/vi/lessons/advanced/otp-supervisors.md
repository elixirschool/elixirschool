%{
  version: "0.9.1",
  title: "OTP Supervisors",
  excerpt: """
  Supervisor (tạm dịch là giám trình - tiến trình giám sát) là các tiến trình (process) đặc biệt với chỉ một mục đích: quản lý các tiến trình khác. Giám trình cho phép chúng ta tạo ra các ứng dụng chống chịu lỗi (fault-tolerent) bằng cách tự động khởi động lại các tiến trình con khi chúng bị hỏng.
  """
}
---

## Cấu hình

Phép thuật của giám trình nằm trong hàm `Supervisor.start_link/2`. Ngoài việc khởi động giám trình và các tiến trình con, nó cho phép chúng ta định nghĩa chiến thuật cho giám trình để quản lý các tiến trình con.

Các tiến trình con được định nghĩa bằng cách sử dụng một danh sách, và hàm `worker/3` (được import từ module `Supervisor.Spec`). Hàm `worker/3` nhận vào một module, các đối số, và một tập các tuỳ chọn. Ở bên dưới `worker/3` gọi tới hàm `start_link/3` với các đối số trong quá trình khởi tạo.

Chúng ta sẽ bắt đầu với SimpleQueue trong bài [OTP Concurrency](../../advanced/otp-concurrency):

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], name: SimpleQueue)
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Nếu tiến trình của chúng ta bị lỗi, hoặc bị tắt đi, giám trình sẽ tự động khởi động lại nó như chưa có điều gì xảy ra.

### Các chiến thuật:

Hiện tại, có bốn chiến thuật khác nhau để khởi động lại các tiến trình con:

+ `:one_for_one` - Chỉ khởi động lại tiến trình con bị hỏng.

+ `:one_for_all` - Khởi động lại tất cả các tiến trình con, nếu có một tiến trình con bị hỏng.

+ `:rest_for_one` - Khởi động lại tiến trình con bị hỏng, và tất cả các tiến trình khác khởi động sau tiến trình đó.

+ `:simple_one_for_one` - Đây là chiến thuật tốt nhất cho các tiến trình con được gắn vào giám trình một cách động. Giám trình yêu cẩu chỉ chứa duy nhất một tiến trình con, nhưng tiến trình này có thể được sinh ra nhiều lần. Chiến thuật này được sử dụng khi bạn muốn khởi động và tắt đi tiến trình con một cách động.

### Restart values

Có một vài cách tiếp cận để quản lý việc các tiến trình con bị hỏng:

+ `:permanent` - Tiến trình con luôn luôn được khởi động lại.

+ `:temporary` - Tiến trình con không bao giờ được khởi động lại.

+ `:transient` - Tiến trình con chỉ được khởi động lại, nếu như nó bị tắt một cách không bình thường.

Giá trị mặc định là `:permanent`.

### Lồng

Ngoài việc sử dụng với các tiến trình worker, chúng ta cũng có thể dùng giám trình để tạo ra một cây các giám trình. Điểm khác biệt duy nhất là gọi `supervisor/3` thay cho `worker/3`:

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Task Supervisor

Task có một kiểu giám trình đặc biệt là `Task.Supervisor`. Được thiết kế cho các task động, `Task.Supervisor` sử dụng chiến thuật `:simple_one_for_one`.

### Cấu hình

Việc thêm vào `Task.Supervisor` cũng giống với các loại giám trình khác khác.

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor, restart: :transient]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Điểm khác biệt chính giữa `Supervisor` và `Task.Supervisor` đó là, chiến thuật khởi động lại mặc định là `:temporary` (tức là task sẽ không bao giờ được khởi động lại).

### Supervised Tasks

Với các giám trình đã được chạy, chúng ta có thể dùng `start_child/2` để tạo ra một task bị giám sát:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

Nếu task của chúng ta bị hỏng, nó sẽ được khởi động lại. Điều này đặc biệt hữu dụng khi làm việc với các kết nối từ bên ngoài hoặc các công việc xử lý dưới nền.
