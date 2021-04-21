%{
  version: "1.2.2",
  title: "チェンジセット",
  excerpt: """
  挿入、更新、またはデータベースからデータの削除をするために、 `Ecto.Repo.insert/2` 、 `update/2` そして `delete/2` は第１引数にチェンジセットを必要とします。
  しかしチェンジセットとは何でしょうか？

  ほぼ全ての開発者にとって馴染みのあるタスクは、潜在的なエラーのために入力データをチェックすることです。目的に沿ってデータを使用する前に、そのデータが正常な状態であることを確認したいのです。

  Ectoは `Changeset` モジュールとデータ構造体という形で、データの変更を扱うための完全なソリューションを提供します。
  このレッスンではそれらの機能を調べ、データベースへ永続化する前にデータの整合性を検証する方法を学びます。
  """
}
---

## 最初のChangesetを作る

空の `%Changeset{}` 構造体を見てみましょう:

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

見ての通り、便利そうなフィールドがいくつかありますが、全て空になっています。

チェンジセットを本当に役立つものにするためには、作成時に、どのようなデータになるかという設計図を提供する必要があります。
フィールドと型の定義を持つ私たちが作ったスキーマよりも、データのためのより良い設計図とはなんでしょうか？

前のレッスンの `Friends.Person` スキーマを使いましょう:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

`Person` スキーマを使うチェンジセットを作るためには、 `Ecto.Changeset.cast/3` を使います:

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

最初のパラメータは元のデータで、この場合は初期化された `%Friends.Person{}` 構造体です。
Ectoは構造体そのものに基づいてスキーマを見つけることができます。
2番目は私たちが行いたい変更であり、ただの空のマップです。
3番目のパラメータが `cast/3` を特別なものにします。これは通過させることを許可するフィールドのリストであり、これによってどのフィールドが変更可能なのかを制御可能とし、残りを安全に保護します。

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [:name, :age])
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Jack"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>

iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

2回目では新しいnameが明示的に許可されていないため、無視されていることがわかるでしょう。

`cast/3` の代わりとして `change/2` もあり、これは `cast/3` のように変更をフィルタリングする機能を持ちません。
これは変更を加えるソースが信頼できるとき、あるいは手動でデータを扱う時に便利です。

ここではチェンジセットを作りましたが、バリデーションを持っていないので、personのnameにあらゆる変更が受け付けられてしまい、その結果、空の名前になる可能性もあります。

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => ""}, [:name, :age])
%Ecto.Changeset<
  action: nil,
  changes: %{name: nil},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>
```

Ectoはチェンジセットが正常であると言っていますが、実際には空の名前を許可したくありません。これを修正しましょう！

## バリデーション

Ectoは私たちを手助けするために、いくつものビルトインのバリデーション機能を持っています。

これから `Ecto.Changeset` を何度も使うので、以下のスキーマを持つ `person.ex` に `Ecto.Changeset` インポートしましょう:

```elixir
defmodule Friends.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

これで `cast/3` 関数を直接使うことができます。

1つのスキーマに複数のチェンジセット作成関数を持つことはよくあります。まずは、構造体、変更のマップを受け取って、チェンジセットを返すものを作りましょう:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

これで `name` が常に存在することを保証できます:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
end
```

`Friends.Person.changeset/2` 関数に空のnameを渡して呼び出すと、チェンジセットは無効になり、役に立つエラーメッセージまで含まれます。
注: `iex` を使っている場合は `recompile()` の実行を忘れないでください。そうしなければ、コードの変更が反映されません。

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => ""})
%Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [name: {"can't be blank", [validation: :required]}],
  data: %Friends.Person<>,
  valid?: false
>
```

上のチェンジセットで `Repo.insert(changeset)` をしようとする場合、同じエラーとともに `{:error, changeset}` を受け取るので、 `changeset.valid?` を自身で毎回チェックする必要はありません。
挿入、更新、削除を試みて、エラーがある場合は後から処理をする方が簡単です。

`validate_required/2` とは別に、 いくつかの追加オプションを受け取る `validate_length/3` もあります。

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

nameに対して1つの文字を渡した場合、どのような結果になるかを試してみましょう！

```elixir
iex> User.changeset(%User{}, %{"name" => "A"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "A"},
  errors: [
    name: {"should be at least %{count} character(s)",
     [count: 2, validation: :length, min: 2]}
  ],
  data: #User<>,
  valid?: false
>
```

エラーメッセージが暗号のような `%{count}` を含んでいることに驚くかもしれません。これは他言語への翻訳を補助するためです。ユーザーに直接エラーを表示したい場合、 [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) を使って人が読める形式に変更できます。ドキュメントで提供されている例に目を通してください。

`Ecto.Changeset` にある他のビルトインのバリデーションは、以下のものがあります:

- validate_acceptance/3
- validate_change/3 & /4
- validate_confirmation/3
- validate_exclusion/4 & validate_inclusion/4
- validate_format/4
- validate_number/3
- validate_subset/4

これらの使用方法の詳細と完全なリストは [ここ](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary) で確認できます。

### カスタムバリデーション

ビルトインのバリデーションは広い範囲のユースケースをカバーしていますが、それらとは別のものがまだ必要かもしれません。

私たちがこれまで使ってきた全ての `validate_` 関数は `%Ecto.Changeset{}` を受け取って返すので、私たち自身のものを簡単に接続することができます。

例えば、架空のキャラクター名のみの許可を確実にすることができます:

```elixir
@fictional_names ["Black Panther", "Wonder Woman", "Spiderman"]
def validate_fictional_name(changeset) do
  name = get_field(changeset, :name)

  if name in @fictional_names do
    changeset
  else
    add_error(changeset, :name, "is not a superhero")
  end
end
```

上のコードでは2つの新しいヘルパー関数である [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) と [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4) を導入しました。これらの動作はほとんど名前が表す通りですが、ドキュメントのリンクを確認することをお勧めします。

`|>` オペレータを使って他のバリデーションを追加しやすいようにするため、 `%Ecto.Changeset{}` 常に返すことがグッドプラクティスです。

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
  |> validate_fictional_name()
end
```

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "Bob"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Bob"},
  errors: [name: {"is not a superhero", []}],
  data: %Friends.Person<>,
  valid?: false
>
```

素晴らしい、動きました！しかし、 `validate_inclusion/4` 関数を代わりに使うこともできるので、この関数を私たち自身が実装する必要はそれほどありません。それでも、役に立つはずの自身のエラー追加する方法を確認できます。

## プログラムでの変更の追加

手動でチェンジセットに変更を加えたいことがあるでしょう。 `put_change/3` ヘルパーはこの目的のために存在します。

`name` フィールドを必須にするよりも、名前無しでのサインアップをユーザーに許可し、彼らを"Anonymous"と呼びましょう。
必要な関数はおなじみのものになます。先ほど紹介した `validate_fictional_name/1` のように、チェンジセットを受け取って返します。

```elixir
def set_name_if_anonymous(changeset) do
  name = get_field(changeset, :name)

  if is_nil(name) do
    put_change(changeset, :name, "Anonymous")
  else
    changeset
  end
end
```

ユーザーの名前を"Anonymous"として設定できるのは、ユーザーがアプリケーションに登録したときだけです。これを行うために、新しいチェンジセット作成関数を作ります。

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

これで `name` を渡す必要はなくなり、 `Anonymous` は自動的に設定されます:

```elixir
iex> Friends.Person.registration_changeset(%Friends.Person{}, %{})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Anonymous"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>
```

特定の責任を持つ（ `registration_changeset/2` のような）チェンジセット作成関数を持つことは珍しいことではありません。特定のバリデーションだけを実行したり、特定のパラメータをフィルタリングしたりする柔軟性が必要なこともあります。
上の関数は、他の場所にある専用の `sign_up/1` ヘルパーで使用することができます:

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## まとめ

_あらゆる_ データのバリデーションに使える [schemaless changesets](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) や、チェンジセット ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)) に伴う副作用の処理、アソシエーションや埋め込みなど、このレッスンではカバーできなかった多くのユースケースや機能があります。
将来的に、上級レッスンとしてこれらをカバーするかもしれませんが、それまでは [Ecto Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html) の公式ドキュメントで詳細を見ることをお勧めします。
