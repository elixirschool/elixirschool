%{
  version: "1.2.3",
  title: "체인지셋",
  excerpt: """
  데이터베이스에서 데이터를 삽입, 변경 또는 삭제를 위해 `Ecto.Repo.insert/2`, `update/2` 및 `delete/2`는 첫 번째 매개변수로 체인지셋이 필요합니다. 체인지셋은 뭘까요?

  대부분의 개발자는 입력 데이터에 잠재적인 오류가 있는지 확인하는 작업에 익숙합니다. 데이터를 목적에 맞게 사용하기 전에 데이터가 올바른 상태인지 확인해야 합니다.

Ecto는 `Changeset` 모듈 및 데이터 자료구조의 방식으로 데이터 변경 작업을 위한 완벽한 솔루션을 제공합니다
  이 단원에서는 이 기능을 살펴보고 데이터를 데이터베이스에 저장하기 전에 데이터의 무결성을 확인하는 방법을 배웁니다.
  """
}
---

## 첫 번째 체인지셋 만들기

다음의 빈 `%Changeset{}` struct를 봅시다.

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

몇몇 유용할 것 같은 필드들이 보이지만 지금은 모두 비어있습니다.

체인지셋을 진정 유용하게 사용하려면 데이터가 어떤 것인지에 대한 청사진이 필요합니다.
그런 데이터 청사진으로는 필드와 타입들을 정의하고 있는 스키마가 딱이죠.

이전 단원의 `Friends.Person` 스키마를 사용합시다.

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

`Person` 스키마를 사용한 체인지셋을 생성하기 위해 `Ecto.Changeset.cast/3`을 사용합니다.

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

첫 번째 파라미터는 본래의 데이터입니다. 여기서는 `%Friends.Person{}` 구조체입니다.
Ecto는 구조체 자체에서 스키마를 찾을 수 있습니다.
두 번째 파라미터는 만들고자 하는 변경사항인데, 위에서는 그냥 비어있는 맵입니다.
세 번째 파라미터가 바로 `cast/3`가 특별한 이유입니다. 이것은 허용하는 필드 목록으로, 이를 통해 변경할 필드들만 통과하고 나머지는 안전하게 보호되도록 제어할 수 있습니다.

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

두 번째 실행에서 명시적으로 허용되지 않은 새 이름이 무시됩니다.

`cast/3` 대신 `change/2` 함수를 사용할 수 있습니다. 다만 `cast/3`처럼 변경사항을 필터링할 수는 없습니다.
변경사항의 데이터 근원지를 신뢰할 수 있거나 데이터를 수동으로 조작할 때 유용합니다.

이제 체인지셋을 만들 수 있지만 아직 유효성 검사가 없어 사람의 이름으로 어떤 것이든 넣을 수 있다 보니 다음처럼 텅 빈 이름도 적용되어 버립니다.

```elixir
iex> Ecto.Changeset.change(%Friends.Person{name: "Bob"}, %{name: ""})
#Ecto.Changeset<
  action: nil,
  changes: %{name: ""},
  errors: [],
  data: #Friends.Person<>,
  valid?: true
>
```

Ecto는 위 체인지셋이 유효하다고 말하고 있지만 실제로는 빈 이름은 허용하지 않을 것입니다. 고쳐봅시다!

## 유효성 검사

Ecto에는 도움이 되는 내장 유효성 검사 함수들이 많이 있습니다.

앞으로 `Ecto.Changeset`을 많이 사용할 것이므로 `Ecto.Changeset`을 스키마가 정의된 `person.ex`의 모듈에 임포트 시킵시다.

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

그러면 `cast/3` 함수를 직접 호출할 수 있습니다.

일반적으로 한 스키마에 한 개 이상의 체인지셋 생성 함수를 둡니다. 구조체와 변경사항 맵을 받아 체인지셋을 반환하는 함수를 하나 만들겠습니다.

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

이제 `name`이 항상 존재하도록 보장시킵니다.

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
end
```

`Friends.Person.changeset/2` 함수에 빈 이름을 넣고 호출하면, 체인지셋은 더이상 유효하지 않으며 유용한 에러 메시지까지 포함합니다.
주의: `iex`에서 작업할 때 `recompile()` 실행을 잊지 마세요. 안그러면 코드의 변경사항이 반영되지 않습니다.

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

위 체인지셋으로 `Repo.insert(changeset)`을 시도하면 같은 오류가 포함된 `{:error, changeset}`을 반환받습니다. 따라서 매번 `changeset.valid?` 를 직접 확인할 필요 없습니다.
삽입, 변경, 삭제 수행을 시도하고 에러가 있으면 처리하도록 하는것이 더 쉽습니다.

`validate_required/2` 이외에도 `validate_length/3` 함수가 있는데, 몇 가지 추가 옵션을 받습니다.

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

한 글자로 된 이름을 넘겨보면 결과가 어떨지 충분히 예상해볼 수 있겠습니다!

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "A"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "A"},
  errors: [
    name: {"should be at least %{count} character(s)",
     [count: 2, validation: :length, kind: :min, type: :string]}
  ],
  data: %Friends.Person<>,
  valid?: false
>
```

에러 메시지의 아리송한 `%{count}`에 놀라지 마세요. 이것은 다른 언어로의 번역을 돕기 위함입니다. 다른 사용자들에게 직접 에러 메시지를 보여주고 싶을 때 [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2)를 사용하여 사람이 읽기 쉽게 만들 수 있습니다. 문서에 나온 예제를 한번 살펴보세요.

`Ecto.Changeset`에는 다음과 같은 몇몇 내장 validator들이 있습니다.

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

[여기](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary)에서 전체 리스트와 사용방법같은 세부사항을 확인할 수 있습니다.

### 사용자 정의 validator

내장 validator들이 많은 유스케이스를 처리하긴 하지만, 그렇지 못한 경우도 여전히 있습니다.

지금까지 사용한 모든 `validate_` 함수는 인자와 반환값 모두 `%Ecto.Changeset{}`이므로 직접 만들어 연결하는것도 쉽습니다.

예를 들어, 사람 이름에 가상 인물의 이름만 허용하도록 만들어봅시다.

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

예제에서 두개의 새로운 보조 함수 [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3)와 [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4)를 사용하고 있습니다. 두 함수가 무엇을 하는지는 자명하지만 문서를 한번 보는 것도 추천드립니다.

항상 `%Ecto.Changeset{}`을 반환하면 `|>` 연산자를 이용해 추후 더 많은 유효성 검증을 추가할 수 있어 꽤나 유용합니다.

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

잘 동작하네요! 그런데 사실 `validate_inclusion/4` 함수가 이미 있어 직접 이 함수를 만들 필요는 없었습니다. 그래도 에러 메시지를 직접 정의하는 방법을 알게 된 건 쓸모가 있습니다.

## 프로그래밍 방식으로 변경사항 만들기

체인지셋에 직접 변경사항을 적용해야 할 때도 있습니다. 그런 경우 `put_change/3` 함수를 사용합니다.

`name` 필드를 필수로 두는 대신 사용자가 이름 없이 "익명(Anonymous)"으로 가입할 수 있게 합시다.
추가할 함수는 앞서 보았던 `validate_fictional_name/1` 함수처럼 인자와 반환값이 체인지셋입니다.

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

애플리케이션에 등록할 사용자의 이름을 "Anonymous"로 설정하는 새로운 체인지셋 생성 함수를 작성합니다.

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

파라미터에 `name`을 넘기지 않아도 `Anonymous`가 자동으로 설정될 것입니다.

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

특정 책임(`registration_changeset/2`같은)이 있는 체인지셋 생성 함수를 만드는 것은 드문 일이 아닙니다. 때로는 특정 유효성 검사만 수행하거나 특정 매개변수를 필터링하는 유연성이 필요합니다.
위의 함수는 다른 곳, 이를 테면 `sign_up/1` 함수에서도 사용할 수 있습니다.

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## 결론

이 강의에서 다루지 않은 많은 사용 사례와 기능들이 있습니다. 예를 들어 _모든_ 데이터의 유효성 검증에 사용할 수 있는 [schemaless changesets](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets)이 있고, 사이드 이펙트를 체인지셋으로 처리하는 것이나([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)) 연관관계와 임베드를 다루는 것들이 있습니다.
추후 심화 단원에서 이것들을 다뤄볼 것이긴 하지만, 그 전에 [Ecto Changeset 공식문서](https://hexdocs.pm/ecto/Ecto.Changeset.html)를 한번 보시는걸 추천드립니다.
