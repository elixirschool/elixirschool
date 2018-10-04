---
version: 1.0.2
title: 嵌入的 Elixir (EEx)
---

正如 Ruby 有 ERB，Java 有 JSPs, Elixir 也有 EEx, 或者 嵌入的 Elixir。通过 EEx，我们可以在字符串里面嵌入 Elixir 表达式并求值。

{% include toc.html %}

## API

EEx 的 API 支持直接操作字符串和文件。API 分为三个主要部分：简单求值，函数定义，和编译为 AST 语法树。

### 求值（Evaluation）

通过 `eval_string/3` 和 `eval_file/2`，我们可以对一个字符串和文件内容进行简单求值计算。这是最简单的 API 但也是最慢的，因为代码只是运算求值，而没有编译。  

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### 定义（Definitions）

把我们的模板嵌入到模块里面，然后编译，是使用 EEx 的最佳，也是效率最高的做法。这种做法需要在编译期准备好我们的模板，还有使用 `function_from_string/5` 和 `function_from_file/5` 两个宏。  

看看我们如何把上面的祝福语移到一个文件里面，并从这个模板生成一个函数：  

```elixir
# greeting.eex
Hi, <%= name %>

defmodule Example do
  require EEx
  EEx.function_from_file(:def, :greeting, "greeting.eex", [:name])
end

iex> Example.greeting("Sean")
"Hi, Sean"
```

### 编译（Compilation）

最后，EEx 为我们提供了从字符串或者文件直接生成 Elixir AST 的方法：`compile_string/2` 或 `compile_file/2`。这两个 API 主要是给前面提到的 API 调用的，但你也可以使用这两个 API 打造你自己的处理嵌入 Elixir 的方法。  

## 标签

在 EEx 里面，有四个默认支持的标签：  

```elixir
<% Elixir 表达式 - inline 代码执行 %>
<%= Elixir 表达式 - 替换为结果返回 %>
<%% EEx 引用 - 返回里面的内容 %>
<%# 注释 - 它们会从源码中移除 %>
```

所有期望返回输出的表达式，都__必须__使用等号（`=`）。要特别注意的是，其它模板语言会把一些类似于 `if` 这样的语句特殊处理，EEx 则不会。没有 `=` 的话，什么都不会返回：  

```elixir
<%= if true do %>
  A truthful statement
<% else %>
  A false statement
<% end %>
```

## 引擎

Elixir 默认是使用 `EEx.SmartEngine` 引擎，它包含了对赋值的支持（如 `@name`）：  

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

`EEx.SmartEngine` 的赋值是很有用的，因为它的值可以随时改变而不需要重新编译模板。  

想写你自己的引擎？参考 [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html) 看看需要实现什么行为吧。  
