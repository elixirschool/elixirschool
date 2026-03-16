%{
  version: "1.5.0",
  title: "基础",
  excerpt: """
  安装，基本类型和基本操作。
  """
}
---

## 安装

### 安装 Elixir

每个操作系统的安装说明可以在 elixir-lang.org 网站上 [Installing Elixir](http://elixir-lang.org/install.html) 部分找到。

安装后你可以很轻松地确认所安装的版本。

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### 交互模式

Elixir 自带了`iex`这样一个交互 shell，可以让我们随时计算 Elixir 表达式的值。

运行`iex`命令，让我们开始教程：

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

让我们继续输入几个简单的表达式试试：

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

如果你现在还无法理解所有的表达式，请不要担心，不过我们希望你能有所体会。

## 基本类型

### 整数类型

```elixir
iex> 255
255
```

Elixir 语言本身就支持二进制、八进制和十六进制的整数：

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### 浮点类型

在 Elixir 语言中，浮点数要求小数点之前必须有至少一个数字；支持 64 位多精度和 `e` 表示的科学计数：

```elixir
iex> 3.14
 3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### 布尔类型

Elixir 支持 `true` 和 `false` 两种布尔值，除了 `false` 和 `nil` 之外所有的值都为真。

```elixir
iex> true
true
iex> false
false
```

### 原子类型

原子类型是名字和代表的值相同的常量，如果你熟悉 Ruby，它们和Ruby中的符号是同义的。

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

注意：布尔值 `true` 和 `false` 实际上就是对应的原子 `:true` 和 `:false`

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Elixir 模块的名字也是原子，即使实际上还不存在这个模块，`MyApp.MyModule` 也是一个合法的原子名称。

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Elixir 以大写字母开始的别名也是原子。

```elixir
iex> is_atom(JustMyAliasTest)
true
```

原子也可以用来直接引用 Erlang 标准库的模块，包括内置的模块。

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### 字符串

Elixir 的字符串是 UTF-8 编码的，用双引号包住：

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

字符串支持换行符和转义字符：

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir 还包含很多复杂的数据类型。当我们学到[集合](/zh-hans/lessons/basics/collections)和[函数](/zh-hans/lessons/basics/functions)的时候我们会学到更多关于这方面的知识。

## 基本操作

### 算术运算

如你所想，Elixir 支持基本的 `+`、`-`、`*`、`/`操作符，不过要注意 `/` 的结果是浮点数。

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

如果你需要整数除法和求余，Elixir 提供了两个函数：

```elixir
iex> div(10, 3)
3
iex> rem(10, 3)
1
```

### 布尔运算

Elixir 提供了 `||`、`&&` 和 `!` 布尔操作符，它们支持任何类型的操作：

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

在 Elixir 中，"真值性"的概念非常简单：只有 `false` 和 `nil` 被视为假值。其他所有值，包括 `0`、`""`（空字符串）和 `[]`（空列表），都被视为真值。这个严格的规则让布尔运算符如 `||`、`&&` 和 `!` 能够以可预测的方式与任何数据类型配合使用于条件逻辑。

还有三个操作符（`and`、`or`、`not`），它们的第一个参数_必须_是布尔类型（`true` 和 `false`）:

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (BadBooleanError) expected a boolean on left-side of "and", got: 42
iex> not 42
** (ArgumentError) argument error
```

备注：Elixir 的 `and` 和 `or` 实际上映射到 Erlang 中的 `andalso` 和 `orelse`。

### 比较

Elixir 有我们习惯的一切比较运算符 ：`==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` 和 `>`。

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

对于整数和浮点数的严格比较，可以使用 `===` ：

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Elixir 有一个很重要的特性，那就是任意两个类型之间都可以进行比较，这在排序的时候非常有用。我们没有必要去记住比较的优先级，但是知道了也没坏处 ：

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

这个特性可以导致一些非常有趣但是完全合法，而且在其他语言中很难看到的比较 ：

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### 字符串插值

如果你使用过 Ruby，那么 Elixir 的字符串插值看起来会很熟悉：

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### 字符串拼接

使用 `<>` 操作符进行字符串拼接：

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```

## 结论

在这个课程中，我们涵盖了 Elixir 的基本构建模块。

我们从安装 Elixir 和启动交互式 shell IEx 开始，在其中评估简单的表达式并立即看到结果。从那里，我们探索了核心数据类型：整数（包括二进制、八进制和十六进制形式）、浮点数、布尔值、原子和字符串。

我们也使用了基本运算，如算术、布尔逻辑和比较运算符。一路上，我们看到了 Elixir 如何处理真值性 — 只有 `false` 和 `nil` 是假值 — 以及 `||`、`&&`、`and` 和 `or` 运算符如何根据它们的期望而有不同的行为。

最后，我们看了字符串内插和字符串拼接，这是处理文本的两个基本工具。

这些概念构成了日常 Elixir 开发的基础。花些时间在 IEx 中实验它们，尝试修改示例，并观察语言的行为。对这些基础的扎实理解将使接下来的主题更容易掌握。
