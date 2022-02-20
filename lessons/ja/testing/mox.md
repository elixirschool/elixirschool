%{
  version: "1.0.1",
  title: "Mox",
  excerpt: """
  MoxはElixirで並列モックを設計するためのライブラリです。
  """
}
---

## テスト可能なコードを書く

テストとそれを支援するモックは、通常、どの言語でも注目を集めるようなハイライトではないので、それらについて書かれたものが少ないのは当然かもしれません。
しかし、Elixirではモックを*完全に*使うことができます！

正確な方法論は、あなたが他の言語で慣れ親しんでいるものとは異なるかもしれませんが、最終的なゴールは同じです。モックは内部関数の出力をシミュレートし、コードの中で起こりうるすべての実行経路に対してアサートできます。

より複雑な使用例に入る前に、コードをよりテストしやすくするためのいくつかのテクニックについて説明します。
簡単な方法のひとつは、関数の中にモジュールをハードコーディングするのではなく、関数にモジュールを渡すというものです。

たとえば、HTTPクライアントを関数の中にハードコーディングしていたとします。

```elixir
def get_username(username) do
  HTTPoison.get("https://elixirschool.com/users/#{username}")
end
```

代わりに、次のようにHTTPクライアントモジュールを引数として渡すことができます。

```elixir
def get_username(username, http_client) do
  http_client.get("https://elixirschool.com/users/#{username}")
end
```

あるいは、[apply/3](https://hexdocs.pm/elixir/Kernel.html#apply/3)関数で同じことを実現することもできます。

```elixir
def get_username(username, http_client) do
  apply(http_client, :get, ["https://elixirschool.com/users/#{username}"])
end
```

引数としてモジュールを渡すことで、関心事を分離できます。また、オブジェクト指向の文言の定義にあまりとらわれなければ、この制御の逆転は一種の[依存性注入](https://en.wikipedia.org/wiki/Dependency_injection)として認識できるかもしれません。
`get_username/2` メソッドをテストするには、 `get` 関数がアサーションに必要な値を返すモジュールを渡せばいいだけです。

この構成は非常に単純なので、関数が非常にアクセスしやすい（そして、たとえばプライベート関数の奥深くに埋もれていない）場合にのみ有用となります。

より柔軟な方法として、アプリケーションの設定に依存する方法があります。
もしかすると気づいていないかもしれませんが、Elixirのアプリケーションは、その設定の中に状態を保持しています。
モジュールをハードコーディングしたり、引数として渡したりするのではなく、アプリケーションの設定から読み取ることができるのです。

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

そして、設定ファイルの中で次のようにします。


```elixir
config :my_app, :http_client, HTTPoison
```

この構成とアプリケーションの設定への依存は、この後のすべての基礎を形成します。

考えすぎな場合は、`http_client/0` 関数を省略して、`Application.get_env/2` を直接呼ぶこともできます。また、`Application.get_env/3` にデフォルトの第3引数を与えても同じ結果を得ることができます。

アプリケーションの設定を利用することで、環境ごとに特定のモジュールを実装できます。たとえば、`dev` 環境ではサンドボックスモジュールを参照し、`test` 環境ではインメモリモジュールを使用するといったことが考えられます。

しかし、環境ごとに1つの固定されたモジュールだけでは柔軟性に欠けるかもしれません。関数がどのように使用されるかに応じて、すべての可能な実行経路をテストするために異なるレスポンスを返す必要があるかもしれません。
ほとんどの人が知らないのは、アプリケーションの設定をランタイムに変更できることです。
[Application.put_env/4](https://hexdocs.pm/elixir/Application.html#put_env/4)を見てみましょう。

あなたのアプリケーションが、HTTPリクエストが成功したかどうかによって、異なる動作をする必要があると想像してください。
複数のモジュールを作成し、それぞれに `get/1` 関数を持たせることができます。
あるモジュールは `:ok` タプルを返し、別のモジュールは `:error` タプルを返します。
そして、 `Application.put_env/4` を使って、 `get_username/1` 関数を呼び出す前に設定を行うことができます。
テストモジュールはこのような感じになります。

```elixir
# Don't do this!
defmodule MyAppTest do
  use ExUnit.Case

  setup do
    http_client = Application.get_env(:my_app, :http_client)
    on_exit(
      fn ->
        Application.put_env(:my_app, :http_client, http_client)
      end
    )
  end

  test ":ok on 200" do
    Application.put_env(:my_app, :http_client, HTTP200Mock)
    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    Application.put_env(:my_app, :http_client, HTTP404Mock)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```


どこかで必要なモジュール（`HTTP200Mock`と`HTTP404Mock`）を作成していることが前提になります。
各テスト終了後に `:http_client` が以前の状態に戻るようにするために、[`on_exit`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#on_exit/2) コールバックを [`setup`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#setup/1) フィクスチャに追加しています。

しかし、上記のようなパターンは通常、*従うべきものではありません*!
その理由は、すぐにはわからないかもしれません。

まず第一に、私たちが `:http_client` のために定義したモジュールが必要なことを行えるという保証は何もありません：ここでは、モジュールに `get/1` 関数を持たせるという契約を強制することはありません。

第二に、上記のようなテストは安全に非同期で実行することができません。
アプリケーションの状態はアプリケーション全体で共有されているので、あるテストで `:http_client` をオーバーライドしたときに、別のテスト (同時に実行される) が別の結果を期待することは十分にありえます。
このような問題に遭遇したことがあるかもしれません。*いつもは*パスしているのに、時々不可解な失敗をするテストがあります。注意してください!

第三に、このアプローチは、アプリケーションのどこかにモックモジュールが詰め込まれてしまう可能性があるため、面倒になる可能性があります。げーっ。

上記のような構造を示したのは、このアプローチの概要をかなりわかりやすく示しており、*実際の*ソリューションがどのように動作するかをもう少し理解するのに役立つからです。

## Mox : すべての問題に対する解決策

Elixirでモックを扱うには、José Valim氏自身が作成した[Mox](https://hexdocs.pm/mox/Mox.html)が最適です。このパッケージは、上記の問題をすべて解決してくれます。

前提条件として、我々のコードは設定されたモジュールを取得するためにアプリケーションの設定を参照する必要があることを忘れないでください。

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

`mox`を依存関係に含めます。

```elixir
# mix.exs
defp deps do
  [
    # ...
    {:mox, "~> 0.5.2", only: :test}
  ]
end
```

`mix deps.get`でインストールします。

次に、`test_helper.exs`を修正して、2つのことをするようにします。

1. 1つ以上のモックを定義する。
2. アプリケーションの設定でモックを設定する。

```elixir
# test_helper.exs
ExUnit.start()

# 1. define dynamic mocks
Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# ... etc...

# 2. Override the config settings (similar to adding these to config/test.exs)
Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)
# ... etc...
```

`Mox.defmock`についていくつか重要な点があります。左側の名前は任意であることです。
Elixirのモジュール名は単なるアトムです -- モジュールをどこかに作成する必要はなく、やっていることはモックモジュールの名前を「予約」しているだけです。
裏では、Moxがこの名前を持つモジュールをBEAMの中でその場で作成します。

第二に、`for:`で参照されるモジュールはビヘイビアーでなければならないということです。つまり、コールバックを定義する必要があります。
Moxはこのモジュールのイントロスペクションを使用し、`@callback`が定義されている場合のみモック関数を定義できます。
これはMoxがコントラクトを強制する方法です。
時には、ビヘイビアーモジュールを見つけるのが難しい場合があります。たとえば、 `HTTPoison` は `HTTPoison.Base` に依存していますが、ソースコードを見てみないとわからないかもしれません。
サードパーティーのパッケージのモックを作成しようとしている場合、ビヘイビアーが存在しないことに気がつくかもしれません。
そのような場合は、コントラクトの必要性を満たすために、独自のビヘイビアーとコールバックを定義する必要があるかもしれません。

これは重要なポイントです。抽象化のレイヤー (別名 [インダイレクト](https://en.wikipedia.org/wiki/Indirection)) を使って、アプリケーションがサードパーティのパッケージに*直接*依存せず、代わりにパッケージを使用する独自のモジュールを使用したいと思うかもしれません。
巧妙に作成されたアプリケーションでは、適切な「境界」を定義することが重要ですが、モックの仕組みは変わらないので、その点はご心配なく。

最後に、テストモジュールで `Mox` をインポートして `:verify_on_exit!` 関数を呼び出せば、モックを使用できます。
そして、 `expect` 関数を呼び出すことで、モックモジュールの戻り値を自由に定義できます。

```elixir
defmodule MyAppTest do
  use ExUnit.Case, async: true
  # 1. Import Mox
  import Mox
  # 2. setup fixtures
  setup :verify_on_exit!

  test ":ok on 200" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:ok, "What a guy!"} end)

    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:error, "Sorry!"} end)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

各テストで、*同じ*モックモジュール（この例では `HTTPoison.BaseMock` ）を参照し、 `expect` 関数を使って呼び出された各関数の戻り値を定義しています。

`Mox` を使用することで、非同期実行が安全になり、各モックがコントラクトに従うことが要求されます。
これらのモックは "仮想 "なので、アプリケーションを散らかすような実際のモジュールを定義する必要はありません。

Elixirのモックへようこそ!
