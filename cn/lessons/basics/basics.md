---
layout: page
title: 基础
category: basics
order: 1
lang: cn
---

安装，基本类型和基本操作。

{% include toc.html %}

## 安装

### 安装 Elixir

各个 os 的安装说明可以在 Elixir-lang.org 网站上 [Installing Elixir](http://elixir-lang.org/install.html) 部分找到。

### 交互模式

Elixir 自带了 `iex` 这样一个交互 shell, 可以让我们随时计算 Elixir 表达式的值。

运行 `iex` 命令，让我们开始教程：

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## 基本类型

### 整数类型

```elixir
iex> 255
255
iex> 0xFF
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
iex> 3.41
3.41
iex> .41
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

原子类型是名字和代表的值相同的常量，如果你熟悉 Ruby，它们和符号类型同义。

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

注意：布尔值 `true` 和 `false` 实际上就是对应的原子 `:true` 和 `:false`

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
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
iex> div(10, 5)
2
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

还有三个操作符（`and`、`or`、`not`），它们的第一个参数必须是布尔类型（`true` 和 `false`）:

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

### 比较

### 字符串差值

如果你使用过 Ruby，那么 Elixir 的字符串差值看起来会很熟悉：

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
