---
layout: page
title: 構成
category: basics
order: 8
lang: jp
---

私たちは経験的に、全ての関数を1つの同じファイルとスコープに持つと手に負えないことを知っています。このレッスンでは関数をまとめ、構造体として知られる特別なマップを定義することで、コードをより効率のよい形に組織化する方法を取り上げます。

{% include toc.html %}

## モジュール

モジュールは関数群を名前空間へと組織する最良の方法です。関数をまとめることに加えて、前回のレッスンで取り上げた名前付き関数やプライベート関数を定義することができます。

基本的な例を見てみましょう:

``` elixir
defmodule Example do
  def greeting(name) do
    ~s(Hello #{name}.)
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Elixirではモジュールをネストすることが可能で、機能ごとにさらなる名前空間をつけることができます:

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### モジュールの属性

モジュール属性はElixirでは一般に定数として用いられることがほとんどです。単純な例を見てみましょう:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

重要なので言及しておきますと、Elixirには予約されている属性があります。もっとも一般的なのは以下の3つです:

+ `moduledoc` — 現在のモジュールにドキュメントを付けます。
+ `doc` — 関数やマクロについてのドキュメント管理。
+ `behaviour` — OTPまたはユーザが定義した振る舞い(ビヘイビア)に用います。

## 構造体

構造体は定義済みのキーの一群とデフォルト値を持つ特殊なマップです。モジュール内部で定義されなくてはならず、そのモジュールから名前をとります。構造体にとっては、モジュール内部で自身しか定義されていないというのもありふれたことです。

構造体を定義するには`defstruct`を用い、フィールドとデフォルト値のキーワードリストを添えます:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

いくつか構造体を作ってみましょう:

```elixir
iex> %Example.User{}
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

構造体はあたかもマップのように更新することができます:

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

最も重要なことですが、構造体はマップに対してマッチすることができます:

```elixir
iex()> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```
