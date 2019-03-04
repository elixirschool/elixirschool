---
version: 1.1.0
title: Changesets
---

Para inserir, atualizar ou excluir as informações de um banco de dados, `Ecto.Repo.insert/2`, `update/2` e `delete/2` é necessário um changeset como primeiro parâmetro.
Mas o que são exatamente changesets?

Uma tarefa comum para quase todos os desenvolvedores é verificar os dados de entrada para possíveis erros — Queremos ter certeza de que os dados estão no estado correto antes de tentarmos usá-los para nossos propósitos.

O Ecto fornece uma solução completa para trabalhar com alteração de dados na forma do módulo `Changeset` e de estruturas de dados. 
Nesta lição, vamos explorar essa funcionalidade e aprender a verificar a integridade dos dados antes de persisti-los no banco de dados.

{% include toc.html %}

## Criando seu primeiro changeset
 
Vamos ver uma estrutura `%Changeset{}` vazia:

```elixir
iex> %Ecto.Changeset{}
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

Como você pode ver, tem alguns campos potencialmente úteis, mas estão todos vazios.

Para um changeset ser verdadeiramente útil, quando o criamos, precisamos fornecer um diagrama de como são os dados. 
Qual o melhor diagrama para nossos dados senão os schemas que criamos que definem nossos campos e tipos?

Vamos ver um schema comum de `User`:

```elixir
defmodule User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
  end
end
```
Para criar um changeset usando o schema `User`, vamos usar `Ecto.Changetset.cast/4`:

```elixir
iex> Ecto.Changeset.cast(%User{name: "Bob"}, %{}, [:name])
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: #User<>,
 valid?: true>
 ```

O primeiro parâmetro é o dado original - uma stuct `%User{}` vazia neste caso. 
Ecto é inteligente o suficiente para encontrar o schema baseado na própria estrutura.
O segundo parâmetro são as alterações que queremos fazer - apenas uma map vazio.
O terceiro parâmetro é o que faz o `cast / 4` especial: é uma lista de campos permitidos, 
The third parameter is what makes `cast/4` special: it is a list of fields allowed to go through, o que nos dá a capacidade de controlar quais campos podem ser alterados e proteger o resto.

 ```elixir
 iex> Ecto.Changeset.cast(%User{name: "Bob"}, %{"name" => "Jack"}, [:name])
 #Ecto.Changeset<
  action: nil,
  changes: %{name: "Jack"},
  errors: [],
  data: #User<>,
  valid?: true
>

iex> Ecto.Changeset.cast(%User{name: "Bob"}, %{"name" => "Jack"}, [])
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: #User<>,
 valid?: true>
```

Você pode ver como o novo nome foi ignorado na segunda vez, onde não foi explicitamente permitido.

Uma alternativa para o `cast/4` é o `change/2`, que não tem a capacidade de filtrar alterações como `cast / 4`.
É útil quando você confia na origem que fez as alterações ou quando trabalha com dados manualmente.

Agora podemos criar changesets, mas como não temos validação, quaisquer alterações ao nome do usuário serão aceitas, para que possamos terminar com um nome vazio:

```elixir
iex> Ecto.Changeset.cast(%User{name: "Bob"}, %{"name" => ""}, [:name])
#Ecto.Changeset<
 action: nil,
 changes: %{name: ""},
 errors: [],
 data: #User<>,
 valid?: true
>
```

Ecto diz que o conjunto de alterações é válido, mas, na verdade, não queremos permitir nomes vazios. Vamos consertar isso!

## Validations

O Ecto vem com várias funções de validação integradas para nos ajudar.

Vamos usar muito o `Ecto.Changeset`, então vamos importar `Ecto.Changeset` para o nosso módulo `user.ex`, que também contém o nosso schema:

```elixir
defmodule User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:name, :string)
  end
end
```

Agora nós podemos usar a função `cast/4` diretamente.

É comum ter uma ou mais funções de construção de changeset para um esquema. Vamos fazer uma que aceite uma struct, um map de alterações e retorne um changeset:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
end
```

Agora vamos garantir que o `name` está sempre presente:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
end
```

Quando chamamos a função `User.changeset / 2` e passamos um nome vazio, o changeset não será mais válido, e irá conter uma mensagem de erro.
Nota: não esqueça de executar `recompile()` quando estiver trabalhando no `iex`, caso contrário, não surtirá efeito as alterações feitas no código.

```elixir
iex> User.changeset(%User{}, %{"name" => ""})
#Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [name: {"can't be blank", [validation: :required]}],
  data: #User<>,
  valid?: false
>
```

Caso você tente usar `Repo.insert(changeset)` com o changeset descrito acima, irá receber um `{:error, changeset}` de volta com o mesmo erro, então você não precisa checar `changeset.valid?` você mesmo toda vez.
É mais facil tentar executar o insert, update ou delete, então processar os erros depois, caso existam.

Além de `validate_required/2`, existe também `validate_length/3`, que possui algumas opções extras: 

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

Você pode tentar adivinhar qual seria o resultado se passássemos um nome que consistisse em um único caractere!

```elixir
iex> User.changeset(%User{}, %{"name" => "A"})
#Ecto.Changeset<
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

Você pode se surpreender já que a mensagem de erro contém o `%{count}` enigmático - isto é para ajudar a tradução para outras línguas; se você quiser exibir os erros diretamente para o usuário, você pode torná-los legíveis usando [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) - Dê uma olhada no exemplo fornecido na documentação.

Alguns dos outros validadores integrados no `Ecto.Changeset` são:

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

Você pode encontrar a lista completa com os detalhes de como usa-los [aqui](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary).
