---
version: 1.2.2
title: Наборы изменений
---

При создании, изменении или удалении записей `Ecto.Repo.insert/2`, `update/2` и `delete/2` принимают набор изменений (changeset) в качестве первого параметра. Но что это такое?

Практически каждому разработчику знакома задача проверки входных данных на потенциальные ошибки. Мы хотим быть уверены, что данные находятся в надлежащем виде, прежде чем попытаемся их использовать.

Ecto полностью покрывает эту потребность при помощи модуля `Changeset` и структур данных.
В этом уроке мы познакомимся с этой функциональностью и научимся проверять данные, перед тем как сохранить их в базу данных.

{% include toc.html %}

## Создание первого набора изменений

Давайте взглянем на пустую структуру `%Changeset{}`:

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

Как можно заметить, здесь присутствуют некоторые потенциально полезные поля, но все они пусты.

Чтобы начать использовать набор изменений, необходимо при создании как-то сообщить ему информацию о том, как будут выглядеть данные.
А что может служить лучшим описанием наших данных, чем схема, в которой определены все наши поля и их типы?

Используем нашу схему `Friends.Person` из предыдущего урока:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Чтобы создать набор изменений, используя схему `Person`, воспользуемся функцией `Ecto.Changeset.cast/3`:

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

Первый параметр — это имеющиеся данные. В данном случае это структура `%Friends.Person{}`.
Ecto самостоятельно найдёт схему, соответствующую переданной структуре.
Вторым по очереди идёт изменение, которое мы хотим осуществить — пустой словарь.
Третий параметр специфичен для `cast/3` — это список полей, которым мы разрешаем измениться. Таким образом, у нас есть полный контроль над тем, какие поля могут быть изменены в ходе операции, а какие должны остаться нетронутыми.

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

На втором примере видно, что имя в результате выполнения не было изменено, поскольку мы не разрешили этого в явном виде.

Альтернативой функции `cast/3` выступает функция `change/2`, у которой нет механизма фильтрации изменяемых полей.
Эта функция будет полезной в случаях, когда мы доверяем источнику изменений или уже проверили данные вручную.

Теперь можно создавать наборы изменений, но поскольку у нас ещё нет никакой валидации, любое изменение имени будет применено. Например, полностью пустое имя:

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

Ecto утверждает, что набор изменений прошёл валидацию, но нам бы не хотелось иметь пустых имён. Давайте это исправим!

## Валидация

В Ecto включён ряд встроенных функций для валидации.

Мы будем активно использовать модуль `Ecto.Changeset`, поэтому импортируем его в наш модуль `person.ex`. Туда, где уже находится наша схема:

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

Теперь можно использовать функцию `cast/3` напрямую.

Как правило, в каждой схеме для создания набора изменений объявляют одну или несколько специальный функций. Мы поступим так же. Наша функция будет принимать структуру и словарь с изменениями, а возвращать набор изменений:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

Теперь добавим проверку того, что поле `name` всегда присутствует:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
end
```

Если мы вызовем функцию `Friends.Person.changeset/2` и передадим в неё пустое имя, то набор изменений не пройдёт валидацию и даже услужливо скажет нам об этом.
Примечание: не забудьте выполнить `recompile()` при работе в `iex`, иначе изменения в коде не возымеют эффекта.

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

При попытке выполнить `Repo.insert(changeset)` с набором изменений из примера выше мы получим `{:error, changeset}` с той же самой ошибкой в качестве результата. Поэтому не обязательно выполнять `changeset.valid?` каждый раз.
Зачастую проще попытаться создать, изменить или удалить запись, и просто обработать ошибку, если таковая возникнет.

Помимо `validate_required/2` существует также `validate_length/3`, принимающая дополнительные опции:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

Несложно догадаться, что произойдёт, если мы попробуем теперь передать в функцию имя, состоящее из одного символа.

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

Это не совсем очевидно, но в ответе теперь содержится таинственное `%{count}`. Это для того, чтобы ошибку можно было перевести на другие языки. Если вы решите выводить текст ошибки напрямую конечному пользователю, то его можно сделать человекочитаемым при помощи функции [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2). Обратите внимание на примеры в документации.
В числе других доступных валидаторов в `Ecto.Changeset` есть, например, такие:

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

С полным списком и инструкцией к ним можно ознакомиться [здесь](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary).

### Пользовательские валидаторы

Хотя встроенные валидаторы и охватывают довольно широкий спектр потребностей, всё ещё может возникнуть необходимость в чём-то нестандартном.

Каждая `validate_`-функция из тех, что мы уже использовали, принимала и возвращала набор изменений `%Ecto.Changeset{}`, поэтому нам не составит труда написать свою.

Например, можно проверять, что разрешены только имена определённых вымышленных персонажей:

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

Выше мы воспользовались двумя новыми функциями: [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) и [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4). Понять их несложно, но мы всё равно рекомендуем ознакомиться с документацией.

Считается хорошим тоном всегда возвращать `%Ecto.Changeset{}`, чтобы функции можно было затем объединять оператором `|>`:

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

Отлично, работает! Впрочем, не было никакой нужды писать эту функцию самостоятельно — можно было использовать валидатор `validate_inclusion/4`. Зато мы научились добавлять нужные нам ошибки.

## Программное изменение значений

Иногда нам нужно вручную внести правки в набор изменений. Для этого можно использовать функцию `put_change/3`.

Вместо того, чтобы делать поле `name` обязательным, давайте позволим пользователям регистрироваться без имени и автоматически будем присваивать им имя `Аноним`.
Нужная нам функция выглядит знакомо — она принимает и возвращает набор изменений, точно так же как и `validate_fictional_name/1`:

```elixir
def set_name_if_anonymous(changeset) do
  name = get_field(changeset, :name)

  if is_nil(name) do
    put_change(changeset, :name, "Аноним")
  else
    changeset
  end
end
```

Можно сделать так, чтобы имя по умолчанию пользователи получали только при регистрации. Для этого мы создадим новую функцию-конструктор набора изменений:

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

Теперь можно не передавать имя (`name`), и оно автоматически получит значение `Аноним`:

```elixir
iex> Friends.Person.registration_changeset(%Friends.Person{}, %{})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Аноним"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>
```

Отдельные функции для создания разных наборов изменений (как `registration_changeset/2` выше) — это распространённая практика. В разных ситуациях требуется разная валидация полей и параметров.
Функция из примера выше в дальнейшем может быть использована, например, в каком-нибудь `sign_up/1`:

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## Вывод

Существует ещё много возможностей и механизмов, не рассмотренных в этом уроке. Среди них, например, [бессхемные наборы изменений](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets), которые можно использовать для валидации _любых_ данных. Или же добавление побочных эффектов в ходе выполнения набора изменений ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)). Или работа с ассоциациями и вложенными структурами.
Возможно, мы затронем их в будущих, более продвинутых уроках. Но пока что мы рекомендуем обратиться к документации [Ecto Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html) за дальнейшими сведениями.
