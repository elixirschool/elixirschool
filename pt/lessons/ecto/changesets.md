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