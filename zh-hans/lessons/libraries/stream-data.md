---
version: 1.1.0
title: StreamData
---

基于用例的单元测试工具库，如 [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) 是帮助你验证代码是否与预期运行逻辑相符的好工具。
但是基于用例的单元测试有它的缺点：

* 由于你只测试某一些输入，一些极端情况很容易被忽略。
* 你可能没有仔细思考清楚需求就能够写出这些测试用例。
* 仅为一个函数编写几个测试样例也可能会非常繁琐。

本教程将探索如何使用 [StreamData](https://github.com/whatyouhide/stream_data) 来帮助我们克服上述缺点。

{% include toc.html %}

## 什么是 StreamData?

[StreamData](https://github.com/whatyouhide/stream_data) 是进行基于属性来进行无状态测试的工具库。

每一个测试用例，StreamData 都会使用随机产生的数据[默认运行 100 次](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1-options)。
当一个测试用例失败后，StreamData 会尝试[缩小](https://hexdocs.pm/stream_data/StreamData.html#module-shrinking)导致用例失败的输入的最小集。
这对于你调试代码来说是非常有帮助的！
如果是一个拥有 50 个元素的列表导致你的函数运行出错，并只是其中的一个元素是有问题的，StreamData 能帮你找到那个元素。

这个测试工具库有两个主要的模块。
[`StreamData`](https://hexdocs.pm/stream_data/StreamData.html) 负责生成随机数据流。
[`ExUnitProperties`](https://hexdocs.pm/stream_data/ExUnitProperties.htm) 让你使用生成的数据来针对函数编写和运行测试。

你或许觉得，如果你都不知道函数的输入是什么，那怎么能判断这个函数是否能真正进行有效测试呢？别着急，接着看你就知道了！

## 安装 StreamData

首先，创建一个 Mix 项目。
如果需要帮助的话，你可以参考[新建项目](https://elixirschool.com/en/lessons/basics/mix/#new-projects) 这个章节。

然后，把 StreamData 添加到 `mix.exs` 的依赖中：

```elixir
defp deps do
  [{:stream_data, "~> x.y", only: :test}]
end
```

把 `x` 和 `y` 替换为 StreamData [安装指引](https://github.com/whatyouhide/stream_data#installation) 里的版本号就可以了。

最后，在命令行运行以下命令：

```
mix deps.get
```

## 使用 StreamData

为了展示 StreamData 的特性，我们需要准备一个简单的重复输入的函数。
它的功能就和 [`String.duplicate/2`](https://hexdocs.pm/elixir/String.html#duplicate/2) 类似，但是我们这个函数能复制字符串，列表或元组。

### 字符串

首先，我们写一个能复制字符串的函数。
它的需求有哪些呢？

1. 第一个参数应该是一个字符串。
   这是需要复制的源字符串。
2. 第二个参数应该是一个非负数。
   它指定我们需要复制第一个字符串参数的次数。
3. 函数需要返回一个字符串。
   返回的新字符串就是复制过 0 次或多次源字符串的结果。
4. 如果源字符串为空，返回的字符串也为空。
5. 如果第二个参数为 0，返回的字符串也应该为空。

当我们运行函数时，期望的效果应该是这样的：

```elixir
Repeater.duplicate("a", 4)
# "aaaa"
```

Elixir 有一个 `String.duplicate/2` 函数可以帮我们处理这个需求。
所以我们的 `duplicate/2` 可以委托它去处理：

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end
end
```

正常的使用场景可以很方便的使用 [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) 来测试。

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicate/2" do
    test "creates a new string, with the first argument duplicated a specified number of times" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end
  end
end
```

但，这并不是一个全面的测试。
如果第二个参数为 `0` 的时候，结果应该如何？
如果第一个参数为空字符串时，结果又怎样？
重复一个空字符串的意义是什么？
这个函数能处理 UTF-8 的字符吗？
函数能处理很大的字符串吗？

我们需要提供更多的样例来测试极端情况和大字符串。
但是，让我们看看如何使用 StreamData 来更严格地测试这个函数，而不需要写更多的代码。

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do

        assert ??? == Repeater.duplicate(str, times)
      end
    end
  end
end
```

以上的代码是什么意思呢？

* 我们把 `test` 替换为 [`property`](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109)。
  这是描述要测试的特性。
* [`check/1`](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1) 是一个允许我们设置测试用例中的数据的宏。
* [`StreamData.string/2`](https://hexdocs.pm/stream_data/StreamData.html#string/2) 负责生成随机字符串。
  我们可以在调用 `string/2` 时不传模块名，因为 `use ExUnitProperties` 这个写法 [导入 StreamData 函数](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109)。
* `StreamData.integer/0` 生成随机整数。
* `times >= 0` 是条件防护语句。
  它确保产生的随机整数必须大于等于零。
  其实有 [`SreamData.positive_integer/0`](https://hexdocs.pm/stream_data/StreamData.html#positive_integer/0) 这个函数，但是不符合我们的需求，因为 `0` 是我们这个函数的有效参数。

那个 `???` 只是我添加的伪代码。
具体我们要怎么写这个断言呢？
我们 **可以** 这么写：

```elixir
assert String.duplicate(str, times) == Repeater.duplicate(str, times)
```

但使用函数的实际实现并没有任何帮助。
我们可以先把我们的断言条件放松一点，比如我们先只是验证字符串的长度：

```elixir
expected_length = String.length(str) * times
actual_length =
  str
  |> Repeater.duplicate(times)
  |> String.length()

assert actual_length == expected_length
```

这总比没有好，但还不完美。这个测试还是能通过那些产生正确长度字符串的函数。

我们真正想验证的两个条件是：
1. 我们的函数生成的字符串长度正确。
2. 字符串的内容是源字符串的不断重复。

这其实是[改变措辞来描述特性](https://www.propertesting.com/book_what_is_a_property.html#_alternate_wording_of_properties)。
我们已经有验证第一个条件的代码了。
为了验证第二个条件，我们可以把结果字符串按源字符串分割，然后得到的是一个拥有零个或多个空字符串的列表。

```elixir
list =
  str
  |> Repeater.duplicate(times)
  |> String.split(str)

assert Enum.all?(list, &(&1 == ""))
```

让我们把这两个断言结合起来看看：

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end
  end
end
```

和原来的测试代码相比，我们可以看到 StreamData 这个版本是原来的两倍。但是，如果你在原来的测试上添加更多的测试用例的话：

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicating a string" do
    test "duplicates the first argument a number of times equal to the second argument" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end

    test "returns an empty string if the first argument is an empty string" do
      assert "" == Repeater.duplicate("", 4)
    end

    test "returns an empty string if the second argument is zero" do
      assert "" == Repeater.duplicate("a", 0)
    end

    test "works with longer strings" do
      alphabet = "abcdefghijklmnopqrstuvwxyz"

      assert "#{alphabet}#{alphabet}" == Repeater.duplicate(alphabet, 2)
    end
  end
end
```

StreamData 这个版本其实更短。
而且 StreamData 还能防止开发人员遗忘一些极端情况。

### 列表

好，现在让我们来写一个重复列表的函数。我们希望它的表现行为是这样的：

```elixir
Repeater.duplicate([1, 2, 3], 3)
# [1, 2, 3, 1, 2, 3, 1, 2, 3]
```

下面是一个正确，但是低效的实现方式：

```elixir
defmodule Repeater do
  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end
end
```

StreamData 的测试看起来可能是这样的：

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end
  end
end
```

上面使用了 `StreamData.list_of/1` 和 `StreamData.term/0` 来创建包含了任意类型，任意长度的列表。

和重复字符串的基于属性的测试用例类似，我们把源列表长度与 `times` 的乘积，和结果列表的长度进行对比。
第二个断言需要稍微解释一下：

1. 我们把结果列表按源列表 `list` 的长度切分成好几段。
2. 然后验证每段是否和 `list` 相等。

也就是说，我们需要确保的是源列表在最终列表中重复了正确的次数，并且没有 **其它任何** 元素包含在我们的结果列表中。

为什么要使用条件判断呢？
因为第一个断言已经证明在源列表和结果列表长度为 0 的情况，所以我们就没有必要进行更多的列表比较了。
而且，`Enum.chunk_every/2` 的第二个参数必须为正数。

### 元组

最后，让我们实现重复元组的函数。它的表现行为应该如下：

```elixir
Repeater.duplicate({:a, :b, :c}, 3)
# {:a, :b, :c, :a, :b, :c, :a, :b, :c}
```

其中一种实现方式是把元组转为列表，复制列表，然后再转为元组。

```elixir
defmodule Repeater do
  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

这要怎么测试呢？
让我们尝试一种和之前不同的方式。
对于字符串和列表来说，我们根据最后结果的长度，和内容来断言。
用同样的方式来处理元组也是可以的，只是测试代码看起来就可能不是那么简单易懂了。

想想下面两个你处理元组的不同操作：

1. 调用 `Repeater.duplicate/2` 来处理元组，把结果转成列表
2. 把元组转成列表，再传入 `Repeater.duplicate/2`

这就是 Scott Wlaschin 提到的一种应用模式 ["不同的路径，相同的终点"](https://fsharpforfunandprofit.com/posts/property-based-testing-2/#different-paths-same-destination)。
这两种不同的处理顺序，最后生成的结果应该是一样的。
让我们用这种方式来测试。

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

## 总结

现在，我们有了三个分别复制字符串，列表和元组的函数。
同时也拥有一些基于特性的测试，让我们有很大的信心可以认定函数的实现是正确的。

最后的应用代码应该是：

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end

  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end

  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

下面是基于特性的测试：

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end

    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end

    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

最后，你可以在命令行输入以下命令来运行测试：

```
mix test
```

记住，每个 StreamData 测试都会默认运行 100 次。
而且，有些 StreamData 的随机数据需要更多时间来生成。
所以，累积的效果就是这些测试会比基于用例的测试会慢好一些。

即便这样，基于特性的测试是基于用例的测试的很好的补充。
它允许我们通过简明的测试来覆盖大范围的输入情况。
如果你不需要在每个测试之间维护状态，StreamData 提供很好的语法来编写基于特性的测试。
