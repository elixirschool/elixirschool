---
layout: page
title: 基本
category: basics
order: 1
lang: jp
---

セットアップ、基本型、そして演算。

## 目次

- [セットアップ](#setup)
	- [Elixirのインストール](#install-elixir)
	- [対話モード](#interactive-mode)
- [基本型](#basic-types)
	- [整数](#integers)
	- [浮動小数](#floats)
	- [真理値](#booleans)
	- [アトム](#atoms)
	- [文字列](#strings)
- [基本の演算](#basic-operations)
	- [算術](#arithmetic)
	- [論理](#boolean)
	- [比較](#comparison)
	- [文字列への式展開](#string-interpolation)
	- [文字列の連結](#string-concatenation)

## セットアップ

### Elixirのインストール

各OS向けのインストール方法は Elixir-lang.org 上の[Installing Elixir](http://elixir-lang.org/install.html) で探すことが出来ます。

### 対話モード

Elixirには`iex`という対話シェルが付属しており、入力したそばからElixirの式を評価することができるようになっています。

対話モードを開始するには、`iex`を起動しましょう:

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir (1.0.4) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## 基本型

### 整数

```elixir
iex> 255
iex> 0xFF
```

2進数、8進数、16進数は組み込みで対応しています:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
255
```

### 浮動小数

Elixirでは、浮動小数点数は少なくとも1桁の数字とその後に続く小数を必要とし、 64ビットの倍精度で、指数`e`に対応しています:

```elixir
iex> 3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
```


### 真理値

Elixirは真理値として`true`と`false`を提供しています。また、`false`と`nil`以外は真とみなされます:

```elixir
iex> true
iex> false
```

### アトム

アトムは自身の名前がそのまま値になる定数です。もしRubyに慣れ親しんでいれば、シンボルと同義です:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

注記: 真理値の`true`と`false`はそれぞれ、アトムの`:true`と`:false`でもあります。

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
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
iex(9)> "foo
...(9)> bar"
"foo\nbar"
iex(10)> "foo\nbar"
"foo\nbar"
```

## 基本的な演算

### 算術

予想されている通りかもしれませんが、Elixirは基本的な演算子である`+`, `-`, `*`, `/`を提供しています。重要なので言及しておきますと、`/`は常に浮動小数を返します:

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

もし整数同士の割り算や剰余が必要な場合、Elixirにはこれを解く2つの便利な関数があります:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### 論理

Elixirは`||`と`&&`、`!`という論理演算子を用意しており、これらはどんな型にも対応しています:

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

さらに、最初の引数が真理値(`true`と`false`)で _なければならない_ 3つの演算子があります:

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

### 比較

### 文字列への式展開

もしRubyを使っているなら、Elixirでの式展開は見覚えがあるでしょう:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### 文字列の連結

文字列連結は`<>`演算子を利用します:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
