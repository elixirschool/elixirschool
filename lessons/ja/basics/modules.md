%{
  version: "1.4.1",
  title: "モジュール",
  excerpt: """
  私たちは経験的に、全ての関数を1つの同じファイルとスコープに持つと手に負えないことを知っています。
  このレッスンでは関数をまとめ、構造体として知られる特別なマップを定義することで、コードをより効率のよい形に組織化する方法を取り上げます。
  """
}
---

## モジュール

モジュールは関数群を名前空間へと組織する最良の方法です。
関数をまとめることに加えて、[関数](../functions/)のレッスンで取り上げた名前付き関数やプライベート関数を定義できます。

基本的な例を見てみましょう:

```elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
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

モジュール属性はElixirでは一般に定数として用いられることがほとんどです。
単純な例を見てみましょう:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

重要なので言及しておきますと、Elixirには予約されている属性があります。
もっとも一般的なのは以下の3つです:

- `moduledoc` — 現在のモジュールにドキュメントを付けます。
- `doc` — 関数やマクロについてのドキュメント管理。
- `behaviour` — OTPまたはユーザが定義した振る舞い(ビヘイビア)に用います。

## 構造体

構造体は定義済みのキーの一群とデフォルト値を持つ特殊なマップです。
モジュール内部で定義されなくてはならず、そのモジュールから名前をとります。
構造体にとっては、モジュール内部で自身しか定義されていないというのもありふれたことです。

構造体を定義するには `defstruct` を用い、フィールドとデフォルト値のキーワードリストを添えます:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

いくつか構造体を作ってみましょう:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

構造体はあたかもマップのように更新することができます:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

最も重要なことですが、構造体はマップに対してマッチすることができます:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

Elixir 1.8以降、構造体にカスタムイントロスペクション機能が追加されました。

カスタムイントロスペクションがどのように使われるのかを理解するため、 `sean` の中身を見てみましょう。

```elixir
iex> inspect(sean)
"%Example.User<name: \"Sean\", roles: [...], ...>"
```

この例では全てのフィールドが出力対象になっていますが、出力したくない項目がある場合、どのようにしたら良いでしょうか？
この場合、 `@derive` を利用することで実現することができます！
`roles` を出力から除外したい場合、以下のように記述します。

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]}
  defstruct name: nil, roles: []
end
```

**注記**： `@derive {Inspect, except: [:roles]}` でも実現することができます。

モジュールを更新したら、 `iex` で確認してみましょう。

```elixir
iex> sean = %Example.User{name: "Sean"}
%Example.User<name: "Sean", ...>
iex> inspect(sean)
"%Example.User<name: \"Sean\", ...>"
```

`roles` が出力から除外されました!

## コンポジション(Composition)

さて、モジュールと構造体の作り方がわかったので、コンポジションを用いてモジュールや構造体に既存の機能を追加する方法を学びましょう。
Elixirは他のモジュールと連携する様々な方法を用意しています。

### alias

モジュール名をエイリアスすることができます。Elixirのコードでは頻繁に使われます:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# aliasを使わない場合

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

2つのエイリアス間で衝突があったり、全体を別名でエイリアスしたい場合には、 `:as` オプションを使います:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

複数のモジュールを一度にエイリアスすることも可能です:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### import

モジュールをエイリアスするよりも、関数を取り込みたいという場合には、 `import` を使います:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### フィルタリング

デフォルトでは全ての関数とマクロが取り込まれますが、 `:only` や `:except` オプションを使うことでフィルタすることができます。

特定の関数やマクロを取り込むには、名前/アリティのペアを `:only` や `:except` に渡す必要があります。
`last/1` で最後の関数のみを取り込んでみましょう:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

`last/1` で指定された関数以外を全て取り込むには、同じ関数で試してみましょう:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

名前/アリティのペアに加えて、 `:functions` と `:macros` という2つの特別なアトムもあります。これらはそれぞれ関数とマクロのみを取り込みます:

```elixir
import List, only: :functions
import List, only: :macros
```

### require

他のモジュールのマクロを使用することをElixirに伝えるために `require` を使うことができます。
`import` とのわずかな違いは、関数ではなくマクロを使用可能とすることです。

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

まだロードされていないマクロを呼びだそうとすると、Elixirはエラーを発生させます。

### use

`use` マクロを用いることで他のモジュールを利用して現在のモジュールの定義を変更することができます。
コード上で `use` を呼び出すと、実際には提供されたモジュールに定義されている `__using__/1` コールバックを呼び出します。
`__using__/1` マクロの結果はモジュールの定義の一部になります。
この動作に対する理解を深めるために簡単な例を見ましょう:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

ここでは `hello/1` 関数を定義する `__using__/1` コールバックを定義した `Hello` モジュールを作りました。
この新しいコードを試すために新しいモジュールを作ります:

```elixir
defmodule Example do
  use Hello
end
```

IExでこのコードを試して見ると `Example` モジュールで `hello/1` を使えるのがわかります。

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

ここで `use` が `Hello` の `__using__/1` コールバックを呼び出して、結果のコードをモジュールに追加します。
基本的な例を見せたので、ここからはこのコードを変更して `__using__/1` にオプションをサポートする方法を見てみましょう。
`greeting` オプションを追加します:

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

新しく作った `greeting` オプションを含むために `Example` モジュールを更新します:

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

IExで試して見ると挨拶が変わるのを確認できます。

```
iex> Example.hello("Sean")
"Hola, Sean"
```

これらは `use` がどうやって動作するのかを説明する簡単な例でしたが、これはElixirのツールボックスで信じられないほどに強力なツールです。
Elixirを学び続けたら `use` をあっちこっちで見ることになるでしょう。かならず見ることになりそうな例をひとつあげれば、 `use ExUnit.Case, async: true` です。

**注意**: `quote` 、 `alias` 、 `use` 、 `require` は[メタプログラミング](../../advanced/metaprogramming)で使用してたマクロです。
