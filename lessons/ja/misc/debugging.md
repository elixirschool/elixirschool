%{
  version: "1.0.1",
  title: "デバッグ",
  excerpt: """
  バグはあらゆるプロジェクトにおいて存在するものであり、それゆえに私たちはデバッグを必要とします。
  このレッスンでは、潜在的なバグを見つけ出すための静的解析ツールとともにElixirのコードのデバッグについて学びます。
  """
}
---

# DialyxirとDialyzer

[Dialyzer](http://erlang.org/doc/man/dialyzer.html) 、 **DI**screpancy **A**na**LYZ**er for **ER**lang programsは、静的コード解析のためのツールです。
言い換えると、これはコードを _読む_ だけで _実行_ はせず、その内容を解析し、
例えばバグやデッドコード、不要なコード、あるいは到達不能コードを検出します。

[Dialyxir](https://github.com/jeremyjh/dialyxir) は、ElixirにおけるDialyzerの使用を簡易化するmixタスクです。

Dialyzerのような仕様ヘルプツールは、あなたのコードをよりよく理解します。
人が読むことができるドキュメント(それが存在し、良く書かれていれば)とは違い、 `@spec` はツールが理解しやすい形式的な文法を使います。

Dialyxirをプロジェクトに追加してみましょう。
最もシンプルな方法は `mix.exs` ファイルに依存を追加することです。

```elixir
defp deps do
  [{:dialyxir, "~> 0.4", only: [:dev]}]
end
```

そして以下のコマンドを実行します:

```shell
$ mix deps.get
...
$ mix deps.compile
```

最初のコマンドはDialyxirをダウンロードしてインストールします。
Hexを一緒にインストールするかどうか確認されるかもしれません。
2つ目はDialyxirアプリケーションをコンパイルします。
Dialyxirをグローバルにインストールしたい場合は、 [documentation](https://github.com/jeremyjh/dialyxir#installation) を読んでください。

最後のステップはPLT(Persistent Lookup Table)をリビルドするためにDialyzerを実行することです。
新しいバージョンのErlangやElixirをインストールした際は毎回この作業を行う必要があります。
幸いにも、Dialyzerはあなたが使おうとしている標準ライブラリを毎回解析しません。
ダウンロードが完了するまでには数分かかります。

```shell
$ mix dialyzer --plt
Starting PLT Core Build ...
this will take awhile
dialyzer --build_plt --output_plt /.dialyxir_core_18_1.3.2.plt --apps erts kernel stdlib crypto public_key -r /Elixir/lib/elixir/../eex/ebin /Elixir/lib/elixir/../elixir/ebin /Elixir/lib/elixir/../ex_unit/ebin /Elixir/lib/elixir/../iex/ebin /Elixir/lib/elixir/../logger/ebin /Elixir/lib/elixir/../mix/ebin
  Creating PLT /.dialyxir_core_18_1.3.2.plt ...
...
 done in 5m14.67s
done (warnings were emitted)
```

## コードの静的解析

これでDialyxirを使う準備が整いました:

```shell
$ mix dialyzer
...
examples.ex:3: Invalid type specification for function 'Elixir.Examples':sum_times/1.
The success typing is (_) -> number()
...
```

このDialyzerのメッセージの内容は明らかです。 `sum_times/1` 関数の戻り値の型が定義されたものと異なります。
これは `Enum.sum/1` が `integer` ではなく `number` を返すためですが、 `sum_times/1` の戻り値の型は `integer` となっています。

`number` は `integer` ではないため、このようなエラーとなります。
どのように修正すればよいでしょう？ここでは `number` を `integer` に変換するために `round/1` 関数を使う必要があります:

```elixir
@spec sum_times(integer) :: integer
def sum_times(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

最終的に次のようになります:

```shell
$ mix dialyzer
...
  Proceeding with analysis...
done in 0m0.95s
done (passed successfully)
```

静的コード解析のためにツールで仕様を利用すると、自己テストされたバグの少ないコードを作成できます。

# デバッグ

時には静的解析だけでは不十分なことがあります。
バグを見つけるために実行フローを理解する必要があるかもしれません。
最も簡単な方法は、値とコードフローを追跡するために `IO.puts/2` のような出力ステートメントをコードの中に設置することですが、このテクニックは原始的であり限界があります。
ありがたいことに、ElixirのコードをデバッグするためにErlangデバッガを使用することができます。

基本的なモジュールを見てみましょう:

```elixir
defmodule Example do
  def cpu_burns(a, b, c) do
    x = a * 2
    y = b * 3
    z = c * 5

    x + y + z
  end
end
```

ここで `iex` を実行します:

```bash
$ iex -S mix
```

そしてデバッガを実行します:

```elixir
iex > :debugger.start()
{:ok, #PID<0.307.0>}
```

Erlangの `:debugger` モジュールはデバッガへのアクセスを提供します。
設定をするためには `start/1` を使います:

- ファイルパスを渡すことで外部の設定ファイルを使うことができます。
- 引数が `:local` か `:global` であれば、デバッガは次のように動作します: + `:global` – デバッガは全ての既知のノードでコードを解釈します。
  これはデフォルトの値です。 + `:local` – デバッガは現在のノードでのみコードを解釈します。

次のステップは、モジュールをデバッガにアタッチすることです:

```elixir
iex > :int.ni(Example)
{:module, Example}
```

`:int` モジュールはブレークポイントの作成とコードのステップ実行を可能にするインタプリタです。

デバッガを開始すると、次のような新しいウィンドウが表示されます:

![Debugger Screenshot 1](/images/debugger_1.png)

モジュールをデバッガにアタッチした後、左にあるメニューが利用可能になります:

![Debugger Screenshot 2](/images/debugger_2.png)

## ブレークポイントの作成

ブレークポイントは、実行が中断されるコード内のポイントです。
ブレークポイントを作成する方法は2通りあります:

- コードに `:int.break/2` を設置する
- デバッガのUIを使う

IExでブレークポイントの作成を試してみましょう:

```elixir
iex > :int.break(Example, 8)
:ok
```

これは `Example` モジュールの8行目にブレークポイントを設置します。
これで関数を実行すると:

```elixir
iex > Example.cpu_burns(1, 1, 1)
```

IExでのコードの実行は中断され、デバッガウィンドウは次のように表示されます:

![Debugger Screenshot 3](/images/debugger_3.png)

ソースコードを含む追加のウィンドウも表示されます:

![Debugger Screenshot 4](/images/debugger_4.png)

このウィンドウでは変数の値を確認したり、次の行に進んだり、式の評価を行ったりすることができます
ブレークポイントを無効化するには `:int.disable_break/2` を使うことができます:

```elixir
iex > :int.disable_break(Example, 8)
:ok
```

ブレークポイントを再び有効化するために `:int.enable_break/2` を実行できますし、次のようにブレークポイントを削除できます:

```elixir
iex > :int.delete_break(Example, 8)
:ok
```

デバッガウィンドウでも同様の操作が可能です。
トップメニューの **Break** で **Line Break** を選択してブレークポイントを設定できます。
コードを含まない行を選択した場合はブレークポイントは無視されますが、デバッガウィンドウには表示されます。
ブレークポイントには次の3種類があります:

- 行ブレークポイント - 行に到達した際にデバッガは実行を停止します。 `:int.break/2` で設定します
- 条件ブレークポイント - 行ブレークポイントと似ていますが、設定された条件を満たした時のみデバッガが停止します。これらは `:int.get_binding/2` で設定します
- 関数ブレークポイント - デバッガは関数の先頭の行で停止します。 `:int.break_in/3` で設定します

以上です！デバッグを楽しんでください！
