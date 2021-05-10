---
version: 0.9.2
title: Modules
---

Chúng ta biết từ kinh nghiệm là để tất cả các hàm vào trong một file khá là không tốt. Trong bài học này, chúng ta sẽ học cách nhóm các hàm lại với nhau, và định nghĩa một loại map đặc biệt là `struct` để tổ chức code một cách hiệu quả hơn.

{% include toc.html %}

## Modules

Module là cách tốt nhất để tổ chức các hàm vào một namespace. Ngoài việc nhóm các hàm với nhau, nó còn cho phép chúng ta định nghĩa các "named function" public và private như chúng ta đã học ở bài học trước.

Hãy cùng xem một ví dụ cơ bản:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Trong Elixir, chúng ta có thể tạo các module lòng này, điều này cho phép bạn có thể dễ dàng phân chia các tính năng hơn.


```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### Thuộc tính của module

Thuộc tính của module phần lớn được dùng như hằng số trong Elixir. Hãy cùng xem một ví dụ đơn giản:


```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Cần đặc biệt chú ý rằng: có một vài thuộc tính đặc biệt trong Elixir. Ba thuộc tính phổ thông nhất là:

+ `moduledoc` — Định nghĩa tài liệu cho module hiện tại
+ `doc` — Định nghĩa tài liệu cho hàm và macro.
+ `behaviour` — Sử dụng trong OTP hoặc định nghĩa các behaviour

## Structs

Struct là các map đặc biệt được định nghĩa như một tập các khoá và các giá trị mặc định. Một struct phải được định nghĩa trong một module, từ đó tên của struct sẽ là tên của module. Rất là bình thường nếu như struct là thứ duy nhất mà module định nghĩa trong nó.

Để định nghĩa một struct, chúng ta sử dụng macro `defstruct` cùng với một keyword list của các trường và các giá trị mặc định:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Hãy cùng tạo một vài structs:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Chúng ta cũng có thể cập nhật struct giống như chúng ta làm với một map:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Quan trọng nhất, chúng ta có thể so trùng mẫu struct với map:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

## Composition

Giờ chúng ta đã biết cách để tạo các module và struct. Hãy cùng học cách để thêm cách tính năng đã tồn tại vào trong chúng thông qua composition. Elixir cung cấp cho chúng ta một vài cách để tương tác giữa các module với nhau.

### `alias`

Cho phép chúng ta có thể "alias" tên của một module, "alias" được sử dụng khá thường xuyên trong Elixir:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Without alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Nếu như có xung đột giữa 2 alias, hoặc chúng ta muốn alias với một tên hoàn toàn khác, chúng ta có thể sử dụng lựa chọn `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Chúng ta thậm chí có thể alias nhiều module cùng một lúc:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Nếu chúng ta muốn import nhiều hàm và macros thay vì alias module, chúng ta có thể dùng `import/`

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtering

Mặc định tất cả các hàm và macro sẽ được import vào, nhưng chúng ta có thể lọc chúng ra bằng cách sử dung lựa chọn `:only` và `:except`.

Để import các hàm và macro cụ thể, chúng ta sẽ phải cung cấp một cặp tên/số tham số (arity) cho `:only` và `:except`. Hãy cùng import chỉ nguyên hàm `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Nếu chúng ta import tất cả mọi thứ trừ `last/1`, chúng ta có thể làm như sau:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Bên cạnh các cặp tên/arity, có 2 atom đặc biệt, `:functions` và `:macros` được dùng để chỉ import các hàm hoặc các macro tương ứng:


```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Mặc dùng ít khi sử dụng, `require/2` dù sao cũng khá quan trong để yêu cầu một module đảm bảo rằng nó được biên dịch vào nạp vào. Điều này đặc biệt hữu dụng nếu chúng ta muốn truy cập vào các macro của một module:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Nếu chúng ta có gắng gọi một macro chưa được nạp trong Elixir, một lỗi sẽ bị văng ra.

### `use`

`use` macro sẽ gọi tới một macro đặc biệt, được gọi là `__using__/1` từ module được chỉ định. Đây là một ví dụ:


```elixir
# lib/use_import_require/use_me.ex
defmodule UseImportRequire.UseMe do
  defmacro __using__(_) do
    quote do
      def use_test do
        IO.puts("use_test")
      end
    end
  end
end
```

và chúng ta có thể thêm dòng này vào trong `UseImportRequire`

```elixir
use UseImportRequire.UseMe
```

sử dụng module UseImportRequire.UseMe để định nghĩa một hàm `use_test/0` thông qua việc gọi tới macro `__using__/1`.

Đó là tất cả những gì mà `use` làm. Ngoài ra, `__using__` được sử dụng khá là phổ biến để gọi tới các `alias`, `require` và `import`. Những macro này sẽ tạo các alias, hoặc là import trong module đươc sử dụng. Điều này cho phép module có thể được sử dụng để định nghĩa một chính sách để các hàm các các macros có thể tham chiếu lẫn nhau. Nó khá là linh động khi `__using__/1` có thể được sử dụng để cấu hình việc tham chiếu tới các module khác, đặc biệt là các module con (submodule).

Phoenix framework sử dụng `__using__/1` để giảm bớt việc phải lặp lại các alias và import call trong các module do lập trình viên định nghĩa.

Sau đây là một ví dụ rất ngắn gọi từ trong module `Ecto.Migration`:


```elixir
defmacro __using__(_) do
  quote location: :keep do
    import Ecto.Migration
    @disable_ddl_transaction false
    @before_compile Ecto.Migration
  end
end
```

Macro `Ecto.Migration.__using__/1` bao gồm một lời gọi import, do vậy khi bạn gọi `use Ecto.Migration`, bạn cũng gọi tới `import Ecto.Migration`. Nó cũng cấu hình một thuộc tính của module từ đó chúng ta sẽ điều khiển hoạt động của Ecto.

Nói tóm lại: `use` macro đơn giản gọi tới `__using__/1` macro của module cụ thể. Để thực sử hiều nó làm những gì, bạn cần đọc vào module `__using__/1`

**Note**: `quote`, `alias`, `use`, `require` là các macro được sử dụng khi chúng ta làm việc với [metaprogramming](../../advanced/metaprogramming).
