%{
  version: "1.0.2",
  title: "メタプログラミング",
  excerpt: """
  メタプログラミングとはコード自体にコードを記述させる機能です。Elixirでは、メタプログラミング機能によりニーズに合わせて言語を拡張し、動的にコードを変更することができます。Elixirが内部でどのように表現されるかを見ることから始めましょう。次にそれを修正する方法を学び、そして最終的に拡張するためにこの知識を使用してみましょう。

  注意事項: メタプログラミングはトリッキーで、どうしても必要な場合にのみ使用してください。過度の使用は、ほぼ確実に、理解及びデバッグすることが困難な複雑なコードにつながります。
  """
}
---

## Quote

メタプログラミングするための最初のステップは、式が表現される方法を理解することです。Elixirでは抽象構文木(AST)（コードの内部表現)は、タプルで構成されています。タプルは、右記3つの要素で構成されます : 関数名、メタデータ、関数の引数

これらの内部構造を見るために、Elixirは `quote/2` 関数を提供しています。 `quote/2` を使い、Elixirのコードをその基礎となる表現に変換することができます:

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
```

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

今、コードの内部構造を検索することができましたが、どのようにそれを修正しましょう？新しいコードまたは値を注入するために、 `unquote/1` を使用します。式をunquoteすると、それが評価され、ASTに注入されます。 `unquote/1` を実証するために、いくつかの例を見てみましょう:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

最初の例では変数 `denominator` は、結果として得られるASTが変数にアクセスするためのタプルを含んでいるようにquoteされています。 `unquote/1` の使用例では生成されたコードに `denominator` の値が含まれています。

## マクロ

`quote/2` と `unquote/1` を理解すれば、マクロに飛び込む準備が整います。マクロのようなすべてのメタプログラミングは、慎重に使用する必要があることを覚えておくことが重要です。

最も簡単な用語であるマクロは、私たちのアプリケーションコードに挿入されるquoteされた式を返すように設計された特別な機能です。マクロは関数のように呼び出されるのではなく、quoteされた表現に置き換えられるのだということを想像してみてください。マクロで、私たちはElixirを拡張し、動的に私たちのアプリケーションにコードを追加するために必要なすべてを持っています。

`defmacro/2` を使用してマクロの定義から始めます。 `defmacro/2` 自身がマクロであり、Elixrの多数の機能がマクロで出来ています。例として、 `unless` をマクロとして実装します。マクロはquoteされた式を返す必要があることを忘れないでください:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

早速作ったモジュールをrequireして使ってみましょう:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

マクロは我々のアプリケーションのコードを置き換えているので、コンパイル時にどのような制御でもすることができます。この例は `Logger` モジュールで見ることができます。ロギングは無効になっていると何のコードも注入されず、結果としてアプリケーションにログ用の関数呼び出しや参照が含まれていません。これは、実装がNOP(処理なし)であっても、関数呼び出しのオーバーヘッドがまだある他の言語とは異なります。

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

ロギングを有効にすると、 `test` 関数は、このコードのような結果になります:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

しかしロギング無効にした場合、結果のコードは次のようになります:

```elixir
def test do
end
```

## デバッグ

たった今 `quote/2` や `unquote/1` の使い方を知り、マクロを書きました。しかし、もし巨大なquoteされたコードがあり、それを理解したい場合はどうすればいいでしょうか？このような場合、 `Macro.to_string/2` を使うことができます。次の例を見てください:

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

マクロで生成されたコードを見たいときは、与えられたquoteされたコードのマクロを展開する `Macro.expand/2` や `Macro.expand_once/2` と組み合わせます。前者はマクロを複数回展開するかもしれませんが、後者は一度だけ展開します。例えば、前のセクションの `unless` の例を変更してみましょう:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

しかし、同じコードを `Macro.expand/2` で実行すると、興味深い結果になります:

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

もしかしたら `if` はElixirのマクロであると述べたのを思い出したかもしれません。これを見れば `if` が基本的な `case` 文に展開されるのが分かります。

### プライベートマクロ

一般的ではないものの、Elixirは、プライベートなマクロをサポートしています。プライベートマクロは `defmacrop` で定義され、それが定義されたモジュールから呼び出すことができます。プライベートマクロはそれを呼び出すコードの前に定義する必要があります。

### 衛生的なマクロ

衛生なマクロは展開したとき、呼び出し元のコンテキストとどの様に相互作用するのでしょう。デフォルトでElixirのマクロは衛生的であり、コンテキストと競合しません:

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

しかし、 `val` の値を操作したい場合は？非衛生的な変数としてマークするために、 `var!/2` を使用することができます。 `var!/2` を利用して例を更新してみましょう:

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

`var!/2` を含めることでマクロに `val` を渡すことなく `val` の値を操作できました。非衛生的なマクロの使用は最小限に抑える必要があります。 `var!/2` を含めることで変数解釈の競合リスクを高めます。

### Binding

すでに `unquote/1` という便利なマクロを抑えておりますが、我々のコードに値を注入する別な方法があります: Bindingです。変数をbindするとマクロ内で複数の変数を含む場合に、一回のみquoteされ予想外の再評価を回避できます。変数をbindするために、 `quote/2` 内の `bind_quoted` オプションにキーワードリストを渡す必要があります。

`bind_quote` の利点を実証するために再評価の問題を抱えた例を見てみましょう。式を二度出力する単純なマクロを作成してみます:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

現在のシステム時刻を渡して新しいマクロを試してみましょう。システム時刻が2回出力されるべきです:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

時間が異なっています！何が起こったのでしょう？ `unquote/1` を同じ式に対し複数回使うことで、再評価され予期しない結果になることがあります。 `bind_quoted` を使用して例題を更新し、どうなったか見てみましょう:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

`bind_quoted` によって期待される成果を得ました: 同じ値が二回出力されています。

これでカバーしてきた `quote/2`, `unquote/1`, `defmacro/2` により、ニーズに合わせてElixirを拡張するために必要なすべてのツールを持ちました。
