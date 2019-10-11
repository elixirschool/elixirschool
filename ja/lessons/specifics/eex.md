---
version: 1.0.2
title: 埋め込みElixir (EEx)
---

RubyにERBが、そしてJavaにJSPがあるようにElixirにもEEx即ち埋め込みElixirがあります。EExを使って文字列の中にElixirを埋め込んで評価することができます。

{% include toc.html %}

## API

EExのAPIは直接、文字列またはファイルに対して動作します。APIは主な３つのコンポーネントに分けられます。単純な評価、関数定義、及びAST(抽象構文木)へのコンパイルです。

### 評価

`eval_string/3` と `eval_file/2` を使って文字列またはファイルの内容に対して単純な評価を行えます。これは一番簡単なAPIですがコードが評価されるだけでコンパイルされないため最も遅いです。

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### 定義

最も高速で、よく使われるEExの使われ方はテンプレートをモジュールの中に埋め込むやり方でこの場合それらはコンパイルされます。それにはコンパイル時にマクロ `function_from_string/5` 及び `function_from_file/5` と共にテンプレートが必要です。

では上記の挨拶の例を他のファイルに移動しテンプレートから関数を生成してみましょう。

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

### コンパイル

最後に、EExは `compile_string/2` または `compile_file/2` により文字列またはファイルから直接ElixirのASTを生成する手段を提供します。このAPIは本来、前述のAPIから利用されるものなのですが、我々独自の埋め込みElixirの処理を実装したい場合にも使えます。

## タグ

デフォルトではEExは4種類のタグをサポートしています。

```elixir
<% Elixir expression - inline with output (Elixirの式 - インラインに展開される) %>
<%= Elixir expression - replace with result (Elixirの式 - 式の評価結果に置き換える) %>
<%% EEx quotation - returns the contents inside (EExの引用 - 内側のコンテンツを返す) %>
<%# Comments - they are discarded from source (コメント、ソースから落とされる)%>
```

出力させたい式には **必ず** 等号(`=`)を使ってください。重要な明記すべきこととして他のテンプレート言語は `if` などの節を特別に扱うのに対しEExはそうではない、ということがあります。 `=` なしでは何も表示されません:

```elixir
<%= if true do %>
  A truthful statement
<% else %>
  A false statement
<% end %>
```

## エンジン

デフォルトではElixirは(`@name` などの)代入に対応した `EEx.SmartEngine` を使います:

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

`EEx.SmartEngine` の代入はテンプレートのコンパイルを必要とせず代入結果を変えられるので非常に便利です。

あなた自身でエンジンを書いてみたくなりましたか? [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html) ビヘイビアを調べて何が必要か見てみてください。
