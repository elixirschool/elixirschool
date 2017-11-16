---
version: 0.9.1
title: モジュール
---

私たちは経験的に、全ての関数を1つの同じファイルとスコープに持つと手に負えないことを知っています。このレッスンでは関数をまとめ、構造体として知られる特別なマップを定義することで、コードをより効率のよい形に組織化する方法を取り上げます。

{% include toc.html %}

## モジュール

モジュールは関数群を名前空間へと組織する最良の方法です。関数をまとめることに加えて、前回のレッスンで取り上げた名前付き関数やプライベート関数を定義することができます。

基本的な例を見てみましょう:

``` elixir
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
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

## コンポジション(Composition)

さて、モジュールと構造体の作り方がわかったので、コンポジションを用いてモジュールや構造体に既存の機能を追加する方法を学びましょう。Elixirは他のモジュールと連携する様々な方法を用意しています。

### `alias`

モジュール名をエイリアスすることができます。Elixirのコードでは頻繁に使われます:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# alias を使わない場合

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

2つのエイリアス間で衝突があったり、全体を別名でエイリアスしたい場合には、`:as` オプションを使います:

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

### `import`

モジュールをエイリアスするよりも、関数やマクロを取り込みたいという場合には、`import`を使います:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### フィルタリング

デフォルトでは全ての関数とマクロが取り込まれますが、`:only` や `:except` オプションを使うことでフィルタすることができます。

特定の関数やマクロを取り込むには、名前/アリティのペアを `:only` や `:except`に渡す必要があります。`last/1`で最後の関数のみを取り込んでみましょう:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

`last/1`で指定された関数以外を全て取り込むには、同じ関数で試してみましょう:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

名前/アリティのペアに加えて、`:functions` と `:macros` という2つの特別なアトムもあります。これらはそれぞれ関数とマクロのみを取り込みます:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

それほど頻繁に使われませんが、`require/2`も重要です。モジュールを require すると、コンパイルとロードが確実に行われます。モジュールのマクロを呼び出す必要がある場合には最も役に立ちます:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

まだロードされていないマクロを呼びだそうとすると、Elixir はエラーを発生させます。

### `use`

use マクロは特別なマクロ、`__using__/1` を特定のモジュールから呼び出します。例を見てください:

```elixir
# lib/use_import_require/use_me.ex
defmodule UseImportRequire.UseMe do
  defmacro __using__(_) do
    quote do
      def use_test do
        IO.puts("use_test")
      end
    end
  end
end
```

UseImportRequireに以下の行を追加します:

```elixir
use UseImportRequire.UseMe
```

UseImportRequire.UseMe を use すると、`__using__/1` マクロ呼出しによって use_test/0 関数が定義されます。

useが行うことはこれで全てですが、 `__using__` マクロは順々に alias、require、import を呼び出します。これにより、そのモジュール内でエイリアスが作られたり、インポートが行われます。この動作によって、モジュールを、関数やマクロがどう参照されるべきかというポリシーの定義に用いることが可能となります。`__using__/1` が他のモジュール、とりわけサブモジュールへの参照を組み立てられるので、こうした使い方をとても柔軟に行う事ができます。

Phoenix フレームワークは use と `__using__/1` を活用して、ユーザが定義したモジュール内で繰り返し行われる alias や import 呼び出しの必要性を減らしています。

Ecto.Migration モジュールから、素晴らしく、短い例をあげます:

```elixir
defmacro __using__(_) do
  quote location: :keep do
    import Ecto.Migration
    @disable_ddl_transaction false
    @before_compile Ecto.Migration
  end
end
```

`Ecto.Migration.__using__/1` マクロは import 呼び出しを含んでいるため、`use Ecto.Migration` されると `import Ecto.Migration` も呼び出されます。また、Ecto のビヘイビアを制御するモジュールのプロパティも設定します。

要約: use マクロは特定モジュールの `__using__/1` マクロを呼び出します。これが何をするのか本当に理解したければ、その `__using__/1` マクロを読む必要があるでしょう。
