%{
  version: "1.0.1",
  title: "GenStage",
  excerpt: """
  Trong bài này ta sẽ có cái nhìn cận cảnh về GenStage, nó đóng vai trò gì, và chúng ta có thể dùng nó như thế nào trong ứng dụng.
  """
}
---

## Giới thiệu

Vậy GenStage là gì? Nói một cách sách vở thì nó là một "cách đặc tả luồng tính toán của Elixir", nhưng nó có nghĩa gì với chúng ta?

Nó có nghĩa là GenState cung cấp cho chúng ta cách định nghĩa luồng công việc cần làm thành các bước (giai đoạn) độc lập trong những process riêng biệt. Nếu bạn từng làm việc với pipelines trước đó thì sẽ không lạ gì khái niệm này.

Để hiểu rõ hơn cách nó làm việc, ta hãy hình dung một mô hình producer-consumer (tạm dịch: mô hình sản xuất - tiêu thụ) đơn giản:

```
[A] -> [B] -> [C]
```

Trong ví dụ này chúng ta có ba giai đoạn: `A` là một producer, `B` là một producer-consumer và `C` là một consumer. `A` cung cấp một giá trị được tiêu thụ bởi `B`, `B` thực hiện một số việc và trả giá trị mới cho consumer `C`; vai trò của mỗi giai đoạn đều quan trọng và chúng ta sẽ xem tiếp nó trong phần tiếp theo.

Ví dụ của chúng ta là mô hình producer-to-consumer 1-đối-1 nên không có vấn đề khi có nhiều producer và nhiều consumer ở bất kì giai đoạn nào.

Để có thể dễ dàng hình dung những khái niệm này, ta sẽ cấu trúc một luồng với GenStage nhưng trước hết, ta hãy xem qua các vai trò trong GenStage một chút:

## Consumers và Producers

Như đã đọc, vai trò mà ta trao cho mỗi giai đoạn là quan trọng. Đặc tả của GenStage nhận ba vai trò:

+ `:producer` — Một nguồn. Một Producer sẽ đợi yêu cầu từ consumer và trả lời các sự kiện được yêu cầu.

+ `:producer_consumer` — Vừa là nguồn vừa là hồ chứa. Producer-consumer vừa có thể trả lời yêu cầu cho các consumer, vừa có thể yêu cầu sự kiện từ các producer khác.

+ `:consumer` — Một hồ chứa. Một Consumer sẽ gửi yêu cầu và nhận kết quả từ producer.

Ai đó vừa nói rằng các producer _đợi_ yêu cầu ư? Với GenStage các consumer gửi yêu cầu ngược lên và xử lý dữ liệu từ producer. Cơ chế này được gọi là back-pressure (tạm dịch: phản áp lực). Back-pressure giúp cho producer không tạo quá nhiều áp lực khi các consumer đang bận.

Và ta đã xem xong các vai trò trong GenStage, giờ hãy bắt đầu với ứng dụng.

## Bắt đầu

Ở ví dụ này ta sẽ xây dựng một ứng dụng GenStage mà nó xuất ra các con số, lựa chọn các con số chẵn và cuối cùng in chúng ra.

Với ứng dụng này chúng ta sẽ sử dụng cả ba vai trò trong GenStage. Producer sẽ chịu trách nhiệm đếm và xuất các con số. Một producer-consumer sẽ lọc ra những con số chẵn và sau đó trả lời yêu cầu từ bên dưới. Cuối cùng ta sẽ tạo một consumer để hiển thị các con số còn lại.

Chúng ta sẽ bắt đầu với việc sinh ra một dự án với supervision tree (tạm dịch: cây giám sát).

```shell
$ mix new genstage_example --sup
$ cd genstage_example
```

Sau đó thêm `gen_stage` vào các thư viện trong `mix.exs`

```elixir
defp deps do
  [
    {:gen_stage, "~> 0.11"}
  ]
end
```

Chúng ta cần tải thư viện về và biên dịch trước khi xem tiếp:

```shell
$ mix do deps.get, compile
```

Giờ thì ta đã sẵn sàng để viết producer rồi!

## Producer

Bước đầu tiên của ứng dụng GenStage là tạo producer. Như đã nói từ trước, chúng ta muốn tạo một producer xuất một dãy các con số. File producer là như sau:

```shell
$ mkdir lib/genstage_example
$ touch lib/genstage_example/producer.ex
```

Sau đó thêm code vào:

```elixir
defmodule GenstageExample.Producer do
  use GenStage

  def start_link(initial \\ 0) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(counter), do: {:producer, counter}

  def handle_demand(demand, state) do
    events = Enum.to_list(state..(state + demand - 1))
    {:noreply, events, state + demand}
  end
end
```

Có hai phần quan trọng cần chú ý ở đây là `init/1` và `handle_demand/2`. Trong `init/1` ta thiết lập trạng thái khởi tạo như vẫn thường làm với GenServer, nhưng quan trọng hơn là ta phải đánh dấu nó là một producer. GenStage sẽ dựa vào kết quả trả về từ hàm `init/1` của chúng ta để phân loại process.

Hàm `handle_demand/2` là phần chủ yếu và **phải được cài đặt** của tất cả producer của GenStage. Ở đây ta sẽ trả về một dãy các số theo yêu cầu của consumer và nâng cờ đếm (`counter`) lên. Yêu cầu của consumer (`demand` trong đoạn code trên) được đại diện bởi một số nguyên tùy vào số sự kiện mà nó có thể xử lý, mặc định là 1000.

## Producer Consumer

Giờ ta đã có một producer để sinh các con số rồi, tiếp đến sẽ là producer-consumer. Chúng ta sẽ muốn gửi yêu cầu các con số từ producer, sau đó lọc ra các con số chẵn, rồi cuối cùng trả lời các yêu cầu.

```shell
$ touch lib/genstage_example/producer_consumer.ex
```

Ta cập nhật file cho nó giống với đoạn code bên dưới:

```elixir
defmodule GenstageExample.ProducerConsumer do
  use GenStage

  require Integer

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter, name: __MODULE__)
  end

  def init(state) do
    {:producer_consumer, state, subscribe_to: [GenstageExample.Producer]}
  end

  def handle_events(events, _from, state) do
    numbers =
      events
      |> Enum.filter(&Integer.is_even/1)

    {:noreply, numbers, state}
  end
end
```

Chú ý là producer-consumer mà ta vừa viết có một tùy chỉnh mới trong `init/1` và một hàm mới `handle_event/3`. Trong tùy chỉnh `subscribe_to`, ta chỉ ra cho GenStage biết là producer-consumer cần được giao tiếp với một producer cụ thể nào.

Phương thức `handle_event/3` sẽ chịu trách nhiệm xử lý chính, là nơi mà ta nhận các sự kiện tiếp theo, xử lý chúng và trả dữ liệu đã xử lý về. Ta thấy rằng consumer cũng được cài đặt theo cách khá giống nhau, nhưng cái khác nằm ở chỗ dữ liệu `handle_event/3` trả về và cách nó được sử dụng.
Khi ta đánh dấu process là một producer-consumer, tham số thứ hai của tuple (`numbers` trong trường hợp này) được dùng để trả lời cho yêu cầu của consumer ở bên dưới. Trong consumer giá trị này sẽ được loại bỏ.

## Consumer

Và giờ thì tới lượt consumer:

```shell
$ touch lib/genstage_example/consumer.ex
```

Vì consumer và producer-consumer khá giống nhau nên code của chúng ta trông không khác nhau lắm:

```elixir
defmodule GenstageExample.Consumer do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [GenstageExample.ProducerConsumer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect({self(), event, state})
    end

    # As a consumer we never emit events
    {:noreply, [], state}
  end
end
```

Như ta đã nói qua ở phần trước, consumer không tạo sự kiện, nên giá trị thứ hai trong tuple sẽ được loại bỏ:

## Ráp chúng lại với nhau

Bây giờ producer, producer-consumer và consumer đã sẵn sàng, ta sẽ ráp chúng lại với nhau.

Ta bắt đầu bằng việc mở file `lib/genstage_example/application.ex` và thêm process mới vào supervisor tree:

```elixir
def start(_type, _args) do
  import Supervisor.Spec, warn: false

  children = [
    worker(GenstageExample.Producer, [0]),
    worker(GenstageExample.ProducerConsumer, []),
    worker(GenstageExample.Consumer, [])
  ]

  opts = [strategy: :one_for_one, name: GenstageExample.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Nếu mọi thứ được cài đặt chính xác, ta có thể chạy dự án và nó sẽ hoạt động như bên dưới:

```shell
$ mix run --no-halt
{#PID<0.109.0>, 2, :state_doesnt_matter}
{#PID<0.109.0>, 4, :state_doesnt_matter}
{#PID<0.109.0>, 6, :state_doesnt_matter}
...
{#PID<0.109.0>, 229062, :state_doesnt_matter}
{#PID<0.109.0>, 229064, :state_doesnt_matter}
{#PID<0.109.0>, 229066, :state_doesnt_matter}
```

Xong rồi! Ứng dụng sẽ chỉ xuất các con số chẵn như ta mong đợi và nó chạy quá _mượt_.

Lúc này thì ta đã chạy được một pipeline với một producer xuất các con số, một producer-consumer loại bỏ các con số lẻ và một consumer hiển thị các thứ này và tiếp tục chạy theo luồng.

## Chạy đa Producer và Consumer

Như đã đề cập trong phần Giới thiệu, ta có thể có nhiều hơn một producer hoặc consumer. Hãy cùng xem lại ví dụ lúc nãy.

Nếu ta thử chạy `IO.inspec/1` trong ví dụ ta sẽ thấy tất cả sự kiện đều được xử lý bởi một PID duy nhất. Ta hãy chỉnh sửa file `lib/genstage_example/application.ex` một chút để chạy nhiều worker.

```elixir
children = [
  worker(GenstageExample.Producer, [0]),
  worker(GenstageExample.ProducerConsumer, []),
  worker(GenstageExample.Consumer, [], id: 1),
  worker(GenstageExample.Consumer, [], id: 2)
]
```

Bây giờ thì ta đã cấu hình xong hai consumer, ta hãy cùng xem nó hiển thị gì khi chạy ứng dụng:

```shell
$ mix run --no-halt
{#PID<0.120.0>, 2, :state_doesnt_matter}
{#PID<0.121.0>, 4, :state_doesnt_matter}
{#PID<0.120.0>, 6, :state_doesnt_matter}
{#PID<0.120.0>, 8, :state_doesnt_matter}
...
{#PID<0.120.0>, 86478, :state_doesnt_matter}
{#PID<0.121.0>, 87338, :state_doesnt_matter}
{#PID<0.120.0>, 86480, :state_doesnt_matter}
{#PID<0.120.0>, 86482, :state_doesnt_matter}
```

Như bạn thấy giờ ta đã có nhiều PID, đơn giản bằng cách thêm một dòng code và cấp ID cho các consumer.

## Ứng dụng thực tiễn

Giờ ta đã biết GenStage và dựng được ứng dụng đầu tiên, nhưng ứng dụng _thực tiễn_ của GenStage là gì?

+ Data Transformation Pipeline - Producer không nhất thiết phải là bộ sinh số đơn giản. Chúng ta có thể tạo ra các sự kiện từ database và thậm chí từ các nguồn như Kafka của Apache. Kết hợp với producer-consumer và consumer, ta có thể xử lý, sắp xếp, phân loại và lưu trữ thông số khi có dữ liệu.

+ Work Queue - Vì sự kiện có thể là bất cứ thứ gì, ta có thể sinh ra một loạt các công việc sẽ được hoàn thành bởi một loạt các consumer.

+ Event Processing - Tương tự như data pipeline, ta có thể nhận, xử lý, sắp xếp hay thao tác các sự kiện được tạo ra theo thời gian thực từ các nguồn.

Và đó chỉ là _một vài_ ví dụ đơn giản của GenStage.
