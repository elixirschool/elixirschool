---
version: 1.0.1
title: IEx Helpers
---

{% include toc.html %}

## 概要

Elixirを始めるとき、IExはあなたの開発の強力な手助けになるでしょう。
IExはREPLでありながら、コードの探索やあなたのコードの開発をよりかんたんにするための多くの機能を備えています。

IExにはたくさんの内蔵のヘルパーがあります。このレッスンでそれぞれ説明していきます。

### オートコンプリート

シェルで作業をしていると、あなたは自力でよく知らない、新しいモジュールを発見できるでしょう。
利用できる機能の中でもオートコンプリート機能は素晴らしい機能です。
モジュール名の後に `.` を入力し、続いて `Tab` を押してみてください。

```elixir
iex> Map. # press Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

これで、モジュールが持つ関数及びその引数を知ることができます。

### `.iex.exs`

IExを起動するとき、毎回 `.iex.exs` という設定ファイルを参照しています。もしそのファイルがカレントディレクトリに存在しない場合はユーザーのホームディレクトリの(`~/.iex.exs`)がフォールバック先として参照されます。

オプションやコードをこのファイルに設定するとIEx上で利用可能になります。たとえば、新しくIEx上で利用したいヘルパー関数がある場合は `.iex.exs` を変更します。

幾つかヘルパー関数を用意してみましょう

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

IExを起動すると、 `IExHelpers` モジュールが利用可能になっています。実際に試してみましょう。

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

このようにヘルパーを利用するためになにか特別な処理を記述する必要が無いことがわかります。

### `h`

`h` はもっとも便利なツールの一つです。
このヘルパーを使って、言語機能によって提供された素晴らしいドキュメンテーションに到達することができます。

次のようにシンプルに利用できます

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

さらに、オートコンプリート機能と組み合わせて利用することもできます。
最初にMapを探索してみます。

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

このようにモジュールのどの関数が利用可能かということだけでなく、それぞれの関数のドキュメンテーションやたくさんの利用例を見ることができます。

### `i`

さて、前の項で学んだ `h` ヘルパーを利用して、 `i` というヘルパーについて学んでいきましょう。

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

こうして `Map` に関するソースコードの所在や関連するモジュールなどの情報を見ることができます。この機能によって簡単に慣習や外部データ型や新しい関数について調べる事ができます。

それぞれの見出しは密である可能性がありますが、高い水準で関連する情報を集めています。

- MapはAtom型である
- ソースコードがどこにあるか
- そのバージョンとコンパイルオプション
- 一般的な説明分
- Mapにアクセスする方法
- 他にどのモジュールを参照しているか

この機能は私たちにより多く働きかけ、有意義にできます。

### `r`

モジュール単位など、部分的に再コンパイルをしたいときは `r` ヘルパーを使います。コードを変更し変更したときや新しい関数を再コンパイルしたいときに使ってみましょう。今回は変更を加えたコードを `r` ヘルパーによってを再コンパイルしてみます。

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

`t` ヘルパーは引数に渡したモジュールの利用可能な型を見ることができます。

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

このように `Map` モジュールがkeyとvalueに定義している型が分かります。
`Map` のソースを読んで確認してみます。

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

これは簡単な例であり、keyやvalueの値はどのような型でも構いませんが知っておくと便利です。

これらすべての内蔵機能を活用することで、簡単にコードを探索したりどのように実行されるか学ぶことができます。IExは開発者にとって協力なツールです。このようなツール郡を使いこなすことでより開発を楽しめるようになるでしょう！
