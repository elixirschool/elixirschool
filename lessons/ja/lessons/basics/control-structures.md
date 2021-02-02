%{
  version: "1.1.1",
  title: "制御構造",
  excerpt: """
  このレッスンではElixirで利用できる制御構造を見ていきます。
  """
}
---

## `if` と `unless`

ひょっとすると以前に `if/2` と出くわしているかもしれませんし、Rubyを使っていれば `unless/2` をご存知でしょう。Elixirではこの2つはほとんど同じように作用しますが、言語の構成要素としてではなく、マクロとして定義されています。この実装は[Kernel module](https://hexdocs.pm/elixir/Kernel.html)で知ることができます。

Elixirでは偽とみなされる値は `nil` と真理値の `false` だけだということに、留意すべきです。

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

`unless/2` は `if/2` のように使いますが、条件が否定される時だけ作用します:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

複数のパターンに対してマッチする必要があるなら、 `case/2` を使うことができます:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

`_` 変数は `case/2` 命令文の中に含まれる重要な要素です。これが無いと、マッチするものが見あたらない場合にエラーが発生します:

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

`_` を"他の全て"にマッチする `else` と考えましょう。

`case/2` はパターンマッチングに依存しているため、パターンマッチングと同じルールや制限が全て適用されます。既存の変数に対してマッチさせようという場合にはピン `^` 演算子を使わなくてはいけません:

```elixir
iex> pie = 3.14
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

`case/2` のもう1つの素晴らしい特徴として、ガード節に対応していることがあげられます:

_この例は公式のElixirの[Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)ガイドから直接持ってきています。_

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

公式ドキュメントから[Expressions allowed in guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions)を読んでみてください。

## `cond`

値ではなく、条件をマッチさせる必要がある時には、 `cond/1` を使うことができます。これは他の言語でいうところの `else if` や `elsif` のようなものです:

_この例は公式のElixirの[Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)ガイドから直接持ってきています。_

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

`case` のように、 `cond` はマッチしない場合にエラーを発生させます。これに対処するには、 `true` になる条件を定義すればよいです:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

特殊形式の `with/1` はネストされた `case/2` 文を使うような時やきれいにパイプできない状況に便利です。 `with/1` 式はキーワード, ジェネレータ, そして式から成り立っています。

ジェネレータについては[リスト内包表記のレッスン](../comprehensions/)でより詳しく述べますが、今は `<-` の右側と左側を比べるのに[パターンマッチング](../pattern-matching/)が使われることを知っておくだけでよいです。

`with/1` の簡単な例から始め、その後さらなる例を見てみましょう:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

式がマッチに失敗した場合はマッチしない値が返されます:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

それでは、 `with/1` を使わない長めの例と、それをどのようにリファクタリングできるかを見てみましょう:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, jwt, full_claims} ->
        important_stuff(jwt, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

`with/1` を導入するとコードが短く、わかりやすくなります:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token, claims),
     do: important_stuff(jwt, full_claims)
```

Elixir 1.3からは `with/1` で `else` を使えます:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
    true <- is_even(number) do
      IO.puts "#{number} divided by 2 is #{div(number, 2)}"
      :even
  else
    :error ->
      IO.puts("We don't have this item in map")
      :error

    _ ->
      IO.puts("It is odd")
      :odd
  end
```

これは `case` のようなパターンマッチングを提供することで、エラーを扱いやすくします。渡されるのはマッチングに失敗した最初の表現式の値です。
