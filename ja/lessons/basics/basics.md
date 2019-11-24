---
version: 1.2.1
title: 基本
---

入門、基本データ型、そして基本的な演算。

{% include toc.html %}

## 入門

### Elixirのインストール

各OS向けのインストール方法はElixir-lang.org上の[Installing Elixir](http://elixir-lang.org/install.html) で探すことができます。

Elixirがインストールされたら簡単にバージョンを確認できます。

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### 対話モード

ElixirにはIExという対話シェルが付属しており、入力したそばからElixirの式を評価することができるようになっています。

対話モードを開始するには、 `iex` を起動しましょう:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

先に進み、試しにいくつかの簡単な式を入力してみましょう:

```elixir
iex>
2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

それぞれの式をまだ理解していなくても心配することはありませんが、どういう感じで使えるのかは感じられたかと思います。

## 基本データ型

### 整数

```elixir
iex> 255
255
```

2進数、8進数、16進数は組み込みで対応しています:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### 浮動小数

Elixirでは、浮動小数点数は少なくとも1桁の数字とその後に続く小数を必要とし、64ビットの倍精度で、指数 `e` に対応しています:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### 真理値

Elixirは真理値として `true` と `false` を提供しています。また、 `false` と `nil` 以外は真とみなされます:

```elixir
iex> true
true
iex> false
false
```

### アトム

アトムは自身の名前がそのまま値になる定数です。Rubyをご存知なら、シンボルと同義になります:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

真理値の `true` と `false` はそれぞれ、アトムの `:true` と `:false` でもあります。

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Elixirのモジュールの名前もまたアトムです。 `MyApp.MyModule` は、そのようなモジュールが宣言されていなくても有効なアトムです。

```elixir
iex> is_atom(MyApp.MyModule)
true
```

アトムは、Erlangのビルトインのものも含めたライブラリのモジュールを参照するのにも使われます。

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### 文字列

文字列はElixirではUTF-8エンコードされていて、二重引用符で囲みます:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

文字列は改行やエスケープシーケンスに対応しています:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

また、Elixirにはより複雑なデータ型も含まれています。[コレクション](../collections/)や[関数](../functions/)について学ぶときにそれらについても詳しく学びます。

## 基本的な演算

### 算術

予想されている通りかもしれませんが、Elixirは基本的な演算子である `+`, `-`, `*`, `/` を提供しています。重要なので言及しておきますと、 `/` は常に浮動小数を返します:

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

整数同士の割り算や剰余が必要な場合、Elixirにはこれを解く2つの便利な関数があります:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### 論理

Elixirは `||` と `&&` 、 `!` という論理演算子を用意しており、これらはどんな型にも対応しています:

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

さらに、最初の引数が真理値(`true` と `false`)で _なければならない_ 3つの演算子があります:

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

参考: Elixirの `and` と `or` はErlangの `andalso` と `orelse` に実際に対応しています。

### 比較

Elixirには私たちが慣れている全ての比較演算子が備わっています: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` そして `>` です。

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

整数と浮動小数を厳密に比べるには `===` を使います:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Elixirの重要な特徴はどんな2つの型でも比べられるということで、これは特にソートにおいて有用です。ソートされる順序を覚える必要はありませんが、順序を気にするのは重要なことです:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

これは他の言語では見られないかもしれない、正当で興味深い比較を引き起こします:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### 文字列への式展開

Rubyを使っているなら、Elixirでの式展開は見覚えがあるでしょう:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### 文字列の連結

文字列連結は `<>` 演算子を利用します:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
