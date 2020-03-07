---
version: 1.2.2
title: Changesets
---

Para inserir, atualizar ou excluir as informações de um banco de dados, `Ecto.Repo.insert/2`, `update/2` e `delete/2` requerem um changeset como primeiro parâmetro.
Mas o que são exatamente changesets?

Uma tarefa comum para quase todos os desenvolvedores é verificar os dados de entrada por possíveis erros — queremos ter certeza de que os dados estão no estado correto antes de tentarmos usá-los para nossos propósitos.

O Ecto fornece uma solução completa para trabalhar com alteração de dados na forma do módulo `Changeset` e de estruturas de dados.
Nesta lição, vamos explorar essa funcionalidade e aprender a verificar a integridade dos dados antes de persisti-los no banco de dados.

{% include toc.html %}

## Criando seu primeiro changeset

Vamos ver uma estrutura `%Changeset{}` vazia:

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

Como você pode ver, tem alguns campos potencialmente úteis, mas estão todos vazios.

Para um changeset ser verdadeiramente útil, quando o criamos, precisamos fornecer um diagrama de como são os dados.
Qual o melhor diagrama para nossos dados senão os schemas que criamos que definem nossos campos e tipos?

Vamos utilizar o schema `Friends.Person` da lição anterior:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Para criar um changeset usando o schema `Person`, vamos usar `Ecto.Changeset.cast/3`:

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
 ```

O primeiro parâmetro é o dado original - uma struct `%Friends.Person{}` vazia neste caso.
Ecto é inteligente o suficiente para encontrar o schema baseado na própria estrutura.
O segundo parâmetro são as alterações que queremos fazer - apenas um map vazio.
O terceiro parâmetro é o que faz o `cast/3` especial: é uma lista de campos permitidos, o que nos dá a capacidade de controlar quais campos podem ser alterados e proteger o resto.

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

Você pode ver como o novo nome foi ignorado na segunda vez, onde não foi explicitamente permitido.

Uma alternativa para o `cast/3` é o `change/2`, que não tem a capacidade de filtrar alterações como `cast/3`.
É útil quando você confia na origem que fez as alterações ou quando trabalha com dados manualmente.

Agora podemos criar changesets, mas como não temos validação, quaisquer alterações ao nome do usuário serão aceitas, então podemos acabar com um nome vazio:

```elixir
iex> Ecto.Changeset.change(%Friends.Person{name: "Bob"}, %{"name" => ""})
%Ecto.Changeset<
  action: nil,
  changes: %{name: nil},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>
```

Ecto diz que o conjunto de alterações é válido, mas, na verdade, não queremos permitir nomes vazios. Vamos consertar isso!

## Validações

O Ecto vem com várias funções de validação integradas para nos ajudar.

Vamos usar muito o `Ecto.Changeset`, então vamos importar `Ecto.Changeset` para o nosso módulo `person.ex`, que também contém o nosso schema:

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

Agora nós podemos usar a função `cast/3` diretamente.

É comum ter uma ou mais funções de construção de changeset para um schema. Vamos fazer uma que aceite uma struct, um map de alterações e retorne um changeset:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

Agora podemos garantir que o `name` está sempre presente:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
end
```

Quando chamamos a função `Friends.Person.changeset/2` e passamos um nome vazio, o changeset não será mais válido, e irá conter uma mensagem de erro.
Nota: não esqueça de executar `recompile()` quando estiver trabalhando no `iex`, caso contrário, as alterações feitas no código não terão efeito.

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

Caso você tente usar `Repo.insert(changeset)` com o changeset descrito acima, irá receber um `{:error, changeset}` de volta com o mesmo erro, então você não precisa checar `changeset.valid?` você mesmo toda vez.
É mais fácil tentar executar o insert, update ou delete, e então processar os erros depois, caso existam.

Além de `validate_required/2`, existe também `validate_length/3`, que possui algumas opções extras:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

Você pode tentar adivinhar qual seria o resultado se passássemos um nome que consistisse em um único caractere!

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

Você pode se surpreender já que a mensagem de erro contém o `%{count}` enigmático - isto é para ajudar a tradução para outras línguas; se você quiser exibir os erros diretamente para o usuário, você pode torná-los legíveis usando [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) - dê uma olhada no exemplo fornecido na documentação.

Alguns dos outros validadores integrados no `Ecto.Changeset` são:

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

Você pode encontrar a lista completa com os detalhes de como usá-los [aqui](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary).

### Validações Customizadas

Embora os validadores integrados cubram uma ampla gama de casos de uso, você ainda pode precisar de algo diferente.

Toda função `validate_` que usamos até agora aceita e retorna um `%Ecto.Changeset{}`, para que possamos facilmente ligar o nosso.

Por exemplo, podemos ter certeza de que somente nomes de personagens fictícios são permitidos:

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

Acima nós introduzimos duas novas funções auxiliares: [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) e [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4). O que elas fazem é quase auto-explicativo, mas eu aconselho você a verificar os links da documentação.

É uma boa prática retornar sempre um `%Ecto.Changeset{}`, então você pode usar o operador `|>` e facilitar a adição de mais validações posteriormente:

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

Ótimo, funciona! No entanto, realmente não havia necessidade de implementar essa função — a função `validate_inclusion/4` poderia ter sido usada; ainda, você pode ver como adicionar seus próprios erros, e isso pode ser útil.

## Adicionando alterações programaticamente

Às vezes você quer introduzir mudanças em um changeset manualmente. O `put_change/3` existe para este propósito.

Em vez de tornar obrigatório o campo `name`, vamos permitir usuários se inscrevam sem um nome, e os chamaremos de "Anonymous".
A função que precisamos parecerá familiar — aceita e retorna um changeset, assim como o `validate_fictional_name/1` que introduzimos anteriormente:

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

Nós podemos definir o nome do usuário como "Anonymous", apenas quando se registrar na aplicação; para fazer isso, vamos criar uma nova função de changeset:

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

Agora nós não temos que passar um `name`, e `Anonymous` será definido automaticamente, como esperado:

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

Tendo uma função changeset que tem uma responsabilidade específica (como `registration_changeset/2`) não é incomum — às vezes, você precisa da flexibilidade para executar apenas algumas validações ou filtrar parâmetros específicos.
A função acima poderia ser usada em um `sign_up/1` dedicado em outro lugar:

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## Conclusão

Há muitos casos de uso e funcionalidades que não abordamos nesta lição, tal como [changesets sem schema](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) que você pode usar para validar _qualquer_ dado, ou lidar com efeitos colaterais ao lado do changeset ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)) ou trabalhar com associações e incorporações.
Podemos abordar isso no futuro, lições avançadas, mas enquanto isso, nós encorajamos a explorar a [Documentação do Ecto Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html) para mais informações.
