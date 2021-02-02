%{
  version: "1.1.0",
  title: "エラーハンドリング",
  excerpt: """
  `{:error, reason}` のようなタプルを返すのが一般的とはいえ、Elixirは例外をサポートしており、このレッスンではエラーハンドリングの方法や利用可能な異なる仕組みについて見ていきます。

一般的に、Elixirでは `{:ok, result}` や `{:error, reason}` を返す関数(`example/1`)を作成する、あるいはラップされていない `result` を返すかエラーを発生させる関数(`example!/1`)に分離するのが慣習です。

このレッスンでは後者に焦点を当てます。
  """
}
---

## 一般的な規則

現時点では、Elixirコミュニティにはエラーを返すことに関していくつかの慣習があります:

* 関数の通常の操作の一部であるエラー（たとえば、ユーザーが間違ったタイプの日付を入力した場合）の場合、関数はそれに応じて `{:ok、result}` と `{:error、reason}` を返します。
* 通常の操作の一部ではないエラー（構成データを解析できないなど）の場合は、例外をスローします。

通常、標準エラーは[パターンマッチング](../../basics/pattern-matching/)で処理しますが、このレッスンでは、2番目のケース、つまり例外について焦点を当てます。

大体のパブリックAPIでは、!がついている関数（example!/1）かを見て後者かを確認することもできます。このような関数はラップされていない結果を返すか、エラーを発生させます。

## エラーハンドリング

エラーをハンドリングする前にエラーを発生させる必要がありますが、最も簡単な方法は `raise/1` を使うことです:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

もしエラーの種類やメッセージを明記したいなら `raise/2` を使う必要があります:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

エラーが起き得ることが分かっている場合、 `try/rescue` とパターンマッチングを使ってエラーをハンドリングできます:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

単独のrescue節で複数のエラーにマッチさせることができます:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

時にはエラーの有無にかかわらず `try/rescue` の後に何らかの処理を必要とする場面があるかもしれません。
このような場合のために `try/after` が存在します。
これはRubyの `begin/rescue/ensure` やJavaの `try/catch/finally` に似ています:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

これはファイルや接続が必ず閉じられなければいけない場合に最もよく使われます:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## 新しいエラー

Elixirには `RuntimeError` のように多くの備え付けのエラー型が含まれていますが、プロジェクト特有のエラー型が必要なら新しいエラーを作ることが出来ます。
新しいエラーを簡単に作るには、デフォルトのエラーメッセージを指定するために `:message` オプションを受け入れる `defexception/1` マクロを使います:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

新しいエラーを試してみましょう:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throw

Elixirのエラーを扱うためのもう一つのメカニズムは `throw` と `catch` です。
実際には新しいElixirコードでこれらを使うのは非常にまれですが、にも関わらずこれらを知り理解することは重要です。

`throw/1` 関数を使えば `catch` できる特定の値で実行を中断できます:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

すでに述べたように、 `throw/catch` はかなり珍しく、概してライブラリが十分なAPIを提供していない時の間に合わせとして存在します。

## 終了

Elixirが提供している最後のエラー処理機構は `exit` です。
終了シグナルはプロセスが死に、それがElixirのフォールトトレランスの重要な部分であるときに発せられます。

明示的に終了するには `exit/1` を使います:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

`try/catch` で終了を捕捉できますが、そうすることは _非常に_ まれです。
ほとんど全ての場合ではsupervisorにプロセスの終了をハンドリングさせるほうが都合がいいでしょう:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
