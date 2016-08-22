---
layout: page
title: 埋め込みElixir (EEx)
category: specifics
order: 3
lang: jp
---

RubyにERBが、そしてJavaにJSPがあるようにElixirにもEEx即ち埋め込みElixirがあります。EExを使って文字列の中にElixirを埋め込んで評価することができます。

{% include toc.html %}

## API

EExのAPIは直接、文字列またはファイルに対して動作します。APIは主な３つのコンポーネントに分けられます。単純な評価、関数定義、及びASTへのコンパイルです。

### 評価

`eval_string/3` と `eval_file/2` を使って文字列またはファイルの内容に対して単純な評価を行えます。これは一番簡単なAPIですがコードが評価されるだけでコンパイルされないため最も遅いです。

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### 定義

