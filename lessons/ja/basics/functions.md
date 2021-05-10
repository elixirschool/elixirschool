%{
  version: "1.2.0",
  title: "関数",
  excerpt: """
  Elixirや多くの関数型言語では、関数は第一級市民(≒ ファーストクラスオブジェクト)です。
Elixirにおける関数の種類について、それぞれどう異なっていて、どのように使うのかを学んでいきます。
  """
}
---

## 匿名関数

その名前が暗に示している通り、匿名関数は名前を持ちません。
`Enum` のレッスンで見たように、匿名関数はたびたび他の関数に渡されます。
Elixirで匿名関数を定義するには、 `fn` と `end` のキーワードが必要です。
これらの内側で、任意の数の引数と `->` で隔てられた関数の本体とを定義することができます。

基本的な例を見てみましょう:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### &省略記法

匿名関数を利用するのはElixirでは日常茶飯事なので、そのための省略記法があります:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

おそらく見当が付いているでしょうが、省略記法では引数を `&1` 、 `&2` 、 `&3` などとして扱うことができます。

## パターンマッチング

Elixirではパターンマッチングは変数だけに限定されているわけではなく、次の項にあるように、関数へと適用することができます。

Elixirはパターンマッチングを用いてマッチする可能性のある全てのオプションをチェックし、最初にマッチするオプションを選択して実行します:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## 名前付き関数

関数を名前付きで定義して後から呼び出せるようにすることができます。
こうした名前付き関数はモジュール内部で `def` キーワードを用いて定義されます。
モジュールについては次のレッスンで学習しますので、今のところ名前付き単体に着目しておきます。

モジュール内部で定義される関数は他のモジュールからも使用することができます。
これはElixirでは特に有用な組み立て部品になります:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

関数本体が1行で済むなら、 `do:` を使ってより短くすることができます:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

パターンマッチングの知識を身にまとったので、名前付き関数を使った再帰を探検しましょう:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### 関数の命名とアリティ

以前言及したとおり、関数は名前とアリティ(引数の数)の組み合わせで命名されます。
つまり、以下のようなことができるということです:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

関数名の一覧を上記のコメントに載せました。
例えば、1つめの実装は引数を取らないので `hello/0` 、2つ目は1つの引数を取るので `hello/1` となります。
他の言語におけるオーバーロードとは違い、これらは互いに _異なる_ 関数として扱われます。
(さっき扱ったパターンマッチングは _同じ_ 数の引数を取る関数定義が複数ある場合のみ適用されます)

### 関数とパターンマッチング

内部では、関数は実行された時の引数をパターンマッチングしています。

マップを受け取るが、特定のキーにだけ関心がある関数が必要であるとしましょう。
私たちは次のようにキーの有無に基づいて引数をパターンマッチすることができます:

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

今度はFredという名前の人物を表すマップを持っているとしましょう。

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

`Greeter1.hello/1` を `fred` のマップで実行するとこのような結果となります:

```elixir
# call with entire map
...> Greeter1.hello(fred)
"Hello, Fred"
```

`:name` キーを _含まない_ マップで関数を実行するとどうなるでしょうか？

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

このような挙動となる理由は、Elixirは関数が実行された際の引数を関数で定義されたアリティに対してパターンマッチさせているためです。

`Greeter1.hello/1` にデータが届いた際どのように見えるか考えてみましょう:

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

`Greeter1.hello/1` は次のような引数を期待します:

```elixir
%{name: person_name}
```

`Greeter1.hello/1` では、私たちが渡したマップ(`fred`)は引数(`%{name: person_name}`)に対して評価されます:

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

これは渡されたマップの中に `name` に対応するキーを見つけます。
マッチがありました！このマッチの成功によって、右辺のマップ(つまり
`fred` マップ)の中にある `:name` キーの値は左辺の変数(`person_name`)に格納されます。

さて、Fredの名前を `person_name` にアサインしたいが、人物マップ全体の値も保持したいという場合はどうするのでしょう？挨拶を出力した後 `IO.inspect(fred)` を使いたいとしましょう。
この時点では、マップの `:name` キーだけをパターンマッチしているので、そのキーの値だけが変数に格納され、関数はFredの残りの値に関する知識を持っていません。

これを保持するためには、マップ全体を変数にアサインして使用できるようにする必要があります。

新しい関数を作ってみましょう:

```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Elixirは引数を渡されたままパターンマッチするということを覚えておいてください。
そのためこのケースでは、それぞれが渡された引数に対してパターンマッチして、マッチした全てのものを変数に格納します。
まずは右辺を見てみましょう:

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

ここでは、 `person` が評価され、fredマップ全体が格納されました。
次のパターンマッチに進みます:

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

これは、マップをパターンマッチしてFredの名前だけを保持したオリジナルの `Greeter1` 関数と同じです。
これによって1つではなく2つの変数を使用することができます:

1. `person` は `%{name: "Fred", age: "95", favorite_color: "Taupe"}` を参照します
2. `person_name` は `"Fred"` を参照します

これで `Greeter2.hello/1` を実行したとき、Fredの全ての情報を使用することができます:

```elixir
# call with entire person
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# call with only the name key
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# call without the name key
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

入ってきたデータに対して独立してパターンマッチして、関数の中でそれらを使用できるようにしたことで、Elixirは複数の奥行きでパターンマッチするという点を確認しました。

リストの中で `%{name: person_name}` と `person` の順序を入れ替えたとしても、それぞれがfredとマッチングするので同じ結果となります。

変数とマップを入れ替えてみましょう:

```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

`Greeter2.hello/1` で使用した同じデータで実行してみます:

```elixir
# call with same old Fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

`%{name: person_name} = person}` は `%{name: person_name}` が `person` に対してパターンマッチしているように見えたとしても、実際には _それぞれが_ 渡された引数をパターンマッチしているということを覚えておいてください。

**まとめ:** 関数は渡されたデータをそれぞれの引数で独立してパターンマッチします。
関数の中で別々の変数に格納するためにこれを利用できます。

### プライベート関数

他のモジュールから特定の関数へアクセスさせたくない時には関数をプライベートにすることができます。
プライベート関数はそのモジュール自身の内部からのみ呼び出すことが出来ます。
Elixirでは `defp` を用いて定義することができます:

```elixir
defmodule Greeter do
  def hello(name), do: phrase() <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### ガード

[制御構造](../control-structures)レッスンでもガードについて少しだけ触れましたが、これを名前付き関数に適用する方法を見ていきます。
Elixirはある関数にマッチするとそのガードを全てテストします。

以下の例では同じ名前を持つ2つの関数があります。ガードを頼りにして、引数の型に基づいてどちらを使うべきか決定します:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### デフォルト引数

引数にデフォルト値が欲しい場合、`引数 \\ デフォルト値`の記法を用います:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

先ほどのガードの例をデフォルト引数と組み合わせると、問題にぶつかります。
どんな風になるか見てみましょう:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header.
Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixirは複数のマッチング関数にデフォルト引数があるのを好みません。混乱の元になる可能性があります。
これに対処するには、デフォルト引数付きの関数を先頭に追加します:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
