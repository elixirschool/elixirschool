---
layout: page
title: メタプログラミング
category: advanced
order: 6
lang: jp
---

<!--
 Metaprogramming is the process of using code to write code.  
 In Elixir this gives us the ability to extend the language to fit our needs and dynamically change the code.  
 We'll start by looking at how Elixir is represented under the hood, then how to modify it, 
 and finally we can use this knowledge to extend it. 
 -->
メタプログラミングとはコード自体にコード記述させる機能です。
Elixirでは、メタプログラミング機能によりニーズに合わせて言語を拡張し、動的にコードを変更することができます。
Elixirがフードの下でどのように表現されるかを見ることから始めましょう。次にそれを修正する方法を学び、そして最終的に拡張するためにこの知識を使用してみましょう。

<!--
A word of caution:  Metaprogramming is tricky and should only be used when absolutely necessary.  Overuse will almost certainly lead to complex code that is difficult to understand and debug.
-->
注意事項: メタプログラミングはトリッキーで、どうしても必要な場合にのみ使用してください。過度の使用は、ほぼ確実に、理解及びデバッグすることが困難な複雑なコードにつながります。
 
## 目次

- [Quote](#quote)
- [Unquote](#unquote)
- [マクロ](#section-1)
	- [プライベートマクロ](#section-2)
	- [衛生的なマクロ](#section-3)
	- [Binding](#binding)

## Quote

<!--
The first step to metaprogramming is understanding how expressions are represented.  
In Elixir the abstract syntax tree (AST), the internal representation of our code, is comprised of tuples.  
These tuples contain three parts: function name, metadata, and function arguments.
-->
メタプログラミングするための最初のステップは、式が表現される方法を理解することです。
Elixirでは抽象構文木(AST)（コードの内部表現)は、タプルで構成されています。
タプルは、右記3つの要素で構成されます : 関数名,　メタデータ,　関数の引数

<!--
In order to see these internal structures, Elixir supplies us with the `quote/2` function.
  Using `quote/2` we can convert Elixir code into their underlying representation:
-->
これらの内部構造を見るために、Elixirは `quote/2` 関数を提供しています。
`quote/2`を使い、Elixirのコードをその基礎となる表現に変換することができます:

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
iex(6)>
```
<!--
Notice the first three don't return tuples?  There are five literals that return themselves when quoted:
-->
注意点として、最初の3つはタプルを返しません。以下の５つのリテラルはquoteされた時に自分自身を返します:

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Unquote

<!--
Now that we can retrieve the internal structure of our code, how do we modify it?  
To inject new code or values we rely use `unquote/1`.  
When we unquote an expression it will be evaluated and injected into the AST.  
To demonstrate `unqoute/1` let's look at some examples:
-->
今、コードの内部構造を検索することができましたが、どのようにそれを修正しましょう？
新しいコードまたは値を注入するために、`unquote/1` を使用します。
式をunqoteすると、それが評価され、ASTに注入されます。
`unquote/1`を実証するために、いくつかの例を見てみましょう：

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

<!--
In the first example our variable `denominator` is quoted so the resulting AST includes a tuple for accessing the variable.  
In the `unquote/1` example the resulting code includes the value of `denominator` instead.
-->
最初の例では変数 `denominator` は、結果として得られるASTが変数にアクセスするためのタプルを含んでいるようにquoteされています。
`unquote/1` の使用例では生成されたコードは、`denominator` の値が含まれています。


## マクロ

<!--
Once we understand `quote/2` and `unquote/1` we're ready to dive into macros.  
It is important to remember that macros, like all metaprogramming, should be used sparingly.
-->
`quote/2` と `unquote/1` を理解すれば、マクロに飛び込む準備が整います。
マクロのようなすべてのメタプログラミングは、慎重に使用する必要があることを覚えておくことが重要です。

<!--
In the simplest of terms macros are special functions designed to return a quoted expression that will be inserted into our application code.  
Imagine the macro being replaced with the quoted expression rather than called like a function.  With macros we have everything necessary to extend Elixir and dynamically add code to our applications.
-->
最も簡単な用語であるマクロは、私たちのアプリケーションコードに挿入されるquoteされた式を返すように設計された特別な機能です。
マクロはquoteされた表現に置き換えではなく、関数のように呼び出されていると想像してみてください。
マクロで、私たちはElixirを拡張し、動的に私たちのアプリケーションにコードを追加するために必要なすべてを持っています。

<!--
We begin by defining a macro using `defmacro/2` which itself is a macro, 
like much of Elixir (let that sink in).  As an example we'll implement `unless` as a macro.  
Remember that our macro needs to return a quoted expression:
-->
`defmacro/2`を使用してマクロの定義から始めます。`defmacro/2`自身がマクロであり、Elixrの多数の機能がマクロで出来ています。
例として、`unless`をマクロとして実装します。マクロはquoteされた式を返す必要があることを忘れないでください：

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

<!-- 
Let's require our module and give our macro a whirl:
-->
早速作ったモジュールをrequireして使ってみましょう:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```
<!--
Because macros replace code in our application we can control when and what is compiled.  
An example of this can be found in the `Logger` module.  
When logging is disabled no code is injected and the resulting application contains no references or function calls to logging.  
This is different from other languages where there is still the overhead of a function call even when the implementation is NOP.
-->
マクロは我々のアプリケーションのコードを置き換えているので、コンパイル時にどのような制御でもすることができます。
例として`Logger` モジュールで見ることができます。
ロギングは無効になっていると何のコードも注入されず、結果としてアプリケーションにログ用の関数呼び出しや参照が含まれていません。
これは、実装がNOP(処理なし)であっても、関数呼び出しのオーバーヘッドがまだある他の言語とは異なります。

<!--
To demonstrate this we'll make a simple logger that can either be enabled or disabled:
-->
これを実証するために、有効または無効にすることができる、簡単なロガーを作ってみます:

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```
<!--
With logging enabled our `test` function would result in code looking something like this:
-->
ロギングを有効にすると、`test` 関数は、このコードのような結果になります:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

<!--
But if we disable logging the resulting code would be:
-->
しかしロギング無効にした場合、結果のコードは次のようになります:

```elixir
def test do
end
```

### プライベートマクロ

<!--
Though not as common, Elixir does support private macros.  
A private macro is defined with `defmacrop` and can only be called from the module in which it was defined.  
Private macros must be defined before the code that invokes them.
-->
一般的ではないものの、Elixirは、プライベートなマクロをサポートしています。
プライベートマクロは`defmacrop`で定義され、それが定義されたモジュールから呼び出すことができます。
プライベートマクロはそれを呼び出すコードの前に定義する必要があります。

### 衛生的なマクロ

<!--
How macros interact with the caller's context when expanded is known as macro hygiene. 
By default macros in Elixir are hygienic and will not conflict with our context:
-->
衛生なマクロは展開したとき、呼び出し元のコンテキストとどの様に相互作用するのでしょう。
elixirのデフォルトのマクロで衛生的であり、コンテキストと競合しません:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

<!--
But what if we wanted to manipulate the value of `val`?  To mark a variable as being unhygienic we can use `var!/2`.  
Let's update our example to include another macro utilizing `var!/2`:
-->
しかし、 `val`の値を操作したい場合は？
非衛生的な変数としてマークするために、`var!/2` を使用することができます。`var!/2` を利用して例を更新してみましょう:


```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

<!--
Let's compare how they interact with our context:
-->
コンテキストとの相互作用を比較してみましょう:

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

<!--
By including `var!/2` in our macro we manipulated the value of `val` without passing it into our macro.  
The use of non-hygienic macros should be kept to a minimum.  
By including `var!/2` we increase the risk of a variable resolution conflict.
-->
 `var!/2`を含めることでマクロで`val`の値を操作できました。
非衛生的なマクロの使用は最小限に抑える必要があります。
`var!/2` を含めることで変数解釈の競合リスクを高めます。


### Binding

<!--
We already covered the usefulness of `unquote/1` but there's another way to inject values into our code: binding.  
With variable binding we are able to include multiple variables in our macro and ensure they're only unquoted once, avoiding accidental revaluations.
 To use bind variables we need to pass a keyword list the `bind_quoted` option in `quote/2`.
-->
すでに`unquote/1` という便利なマクロを抑えておりますが、我々のコードに値を注入する別な方法があります：Bindingです。
変数がbindするとマクロ内で複数の変数を含む場合に、一回のみquoteされ予想外の再評価を回避できます。
変数をbindするために、`quote/2` 内の`bind_quoted` オプションにキーワードリストを渡す必要があります。


<!--
To see the benefit of `bind_quote` and to demonstrate the revaluation issue let's use an example.  
We can start by creating a macro that simply outputs the expression twice:
-->
`bind_quote` の利点を実証するために再評価の問題を抱えた例を見てみましょう。
式を二度出力する単純なマクロを作成してみます:


```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts unquote(expr)
      IO.puts unquote(expr)
    end
  end
end
```

<!--
We'll try out our new macro by passing it the current system time, we should expect to see it outputted twice:
-->
現在のシステム時刻を渡した場合、おなじ内容が二回出力見ることを期待しています。新しいマクロを試してみましょう：

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

<!--
The times are different!  What happened?  
Using `unquote/1` on the same expression multiple times results in revaluation and that can have unintended consequences.  
Let's update the example to use `bind_quoted` and see what we get:
-->
時間が異なっています！何が起こったのでしょう？
`unquote/1`を使うことで、同じ式で再評価され複数の結果(予期しない結果)が返りました。
`bind_quoted`を使用して例題を更新してみましょう:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts expr
      IO.puts expr
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

<!--
With `bind_quoted` we get our expected outcome: the same time printed twice.
-->
`bind_quoted` によって期待される成果を得ました: 同じ値が二回出力されています。

<!--
Now that we've covered `quote/2`, `unquote/1`, and `defmacro/2` we have all the tools necessary to extend Elixir to suit our needs.
-->
これでカバーしてきた `quote/2`, `unquote/1`, `defmacro/2` により、ニーズに合わせてElixirを拡張するために必要なすべてのツールを持ちました。

