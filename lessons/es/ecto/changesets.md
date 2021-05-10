%{
  version: "1.2.2",
  title: "Changesets",
  excerpt: """
  Con el objetivo de insertar, actualizar o borrar datos de la base de datos, `Ecto.Repo.insert/2`, `update/2` y `delete/2` requieren un *changeset* como primer parámetro. Pero ¿Qué son los *changesets*?

Una tarea familiar para casi todo desarrollador es revisar la data de entrada en busca de potenciales errores - queremos asegurarnos que la data esté en un estado correcto, antes de intentar usarlos para nuestros propósitos.

Ecto provee una solución completa para trabajar con los cambios de datos en la forma de un módulo `Changeset` y una estructura de datos.
En esta lección vamos a explorar esta funcionalidad y aprender como verificar la integridad de la data antes de guardarla a la base de datos.
  """
}
---

## Creando tu primer changeset

Vamos a ver una estructura de `%Changeset{}` vacía:

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

Como puedes ver tiene algunos campos potencialmente útiles pero todos están vacíos.

Para que un *changeset* sea realmente útil cuando lo creamos necesitamos proveer una representación de como la data debería ser.
¿Pero qué mejor representación para nuestra data que los esquemas que creamos para definir campos y tipos?

Vamos a usar el esquema `Friends.Person` de la lección anterior:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Para crear un *changeset* usando el esquema `Person` vamos a usar `Ecto.Changeset.cast/3`:

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

El primer parámetro es la data original, una estructura inicial de `%Friends.Person{}` en este caso.
Ecto es lo suficientemente inteligente para encontrar el esquema basándose en la estructura misma.
El segundo parámetro son los cambios que queremos hacer, solo un mapa vació.
El tercer parámetro es lo que hace a `cast/3` especial: es una lista de los campos permitidos a usar los cuales nos dan la habilidad para controlar que campos pueden ser cambiados y mantener seguros al resto.

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

Puedes ver como el nuevo nombre fue ignorado en la segunda linea, donde este no fue explícitamente permitido.

Una alternativa a `cast/3`es la función `change/2` la cual no tiene la habilidad de filtrar cambios como `cast/3`.
Es útil cuando confías en la fuente que está haciendo los cambios o cuando trabajas con data manualmente.

Ahora podemos crear *changesets* pero dado que no tenemos validaciones cualquier cambio al nombre de la persona será aceptado, por lo que podríamos terminar con un nombre vació:

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

Ecto dice que el *changeset* es válido pero realmente no queremos permitir valores vacíos. ¡Vamos a corregir eso!

## Validaciones

Ecto viene con un número de funciones validadoras para ayudarnos.

Vamos a usar `Ecto.Changeset` mucho, entonces vamos a importar `Ecto.Changeset` en nuestro módulo `person.ex` el cual también contiene:

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

Ahora podemos usar la función `cast/3` directamente.

Es común tener uno o mas funciones que creen *changesets* para un esquema. Vamos a hacer uno que acepte una estructura, un mapa de cambios y retorne un *changeset*:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

Vamos vamos a asegurarnos de que `name` esté siempre presente.

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
end
```

Cuando llamamos a la función `Friends.Person.changeset/2` y le pasamos un nombre vació, el *changeset* ya no será válido e incluso contendrá un mensaje de error útil.
Nota: no olvides correr `recompile()` cuando trabajes en `iex` de otro modo no reconocerá los cambio que hagas en el código.

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

Si tratas de ejecutar `Repo.insert(changeset)` con el *changeset* de arriba recibirás una tupla `{:error, changeset}` con el mismo error por lo que no tienes que revisar `changeset.valid?` por ti mismo cada vez.
Es fácil intentar hacer una inserción, actualización o eliminación y procesar el error luego si es que hay alguno.

Aparte de `validate_required/2`, existe también `validate_length/3`, pero toma algunas opciones extra:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

¡Puedes probarlo y adivinar cual sería el resultado si pasamos un nombre que consista de un simple carácter!

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

Podrías estar sorprendido de que el mensaje de error contiene `%{count}` - esto es de ayuda para otros idiomas; si quieres mostrar los errores al usuario directamente puedes "humanizarlos" usando la función [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) — dale un vistazo al ejemplo provisto en la documentación.

Algunos de los validadores incluidos en `Ecto.Changeset` son:

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

Puedes encontrar la lista completa con detalles de como usarlos [aquí](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary).

### Validadores personalizados

A pesar de que lo validadores incluidos cubren un amplio rango de casos de uso, aún puedes necesitas algo diferente.

Cada función `validate_` que usamos hasta ahora acepta y regresa un `%Ecto.Changeset{}` por lo que podemos fácilmente insertar el nuestro.

Por ejemplo podemos asegurarnos de que solo nombres de personajes ficticios está permitidos:

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

Arriba introdujimos dos nuevas funciones de ayuda [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) y [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4). Lo que hacen casi que se explica por si mismo pero te recomiendo revisar los enlaces a la documentación.

Es una buena práctica siempre retornar un `%Ecto.Changeset{}` por lo que puedes usar el operador `|>` y hacer sencillo agregar mas validadores después:

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

¡Genial, funciona! Sin embargo no necesitamos implementar esta función por nosotros mismos, la función validadora `validate_inclusion/4` podría ser usada en su lugar, puedes ver como puedes agregar tus propios errores lo cual puede ser útil.

## Agregando cambios programáticamente

A veces quieres introducir cambios al *changeset* manualmente. la función `put_change/3` existe para este propósito.

En lugar de hacer el campo `name` requerido vamos a permitir a los usuarios registrarse sin un nombre y los llamaremos "Anónimo".
La función que necesitamos lucirá familiar, acepta t regresa un *changeset* tal como la función `validate_fictional_name/1` que hicimos antes:

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

Podemos configurar el nombre de usuario como "Anónimo" solo cuando ellos se registren en nuestra aplicación, para hacer esto vamos a crear una nueva función creadora de *changeset*:

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

No tenemos que pasar un `name` y `Anonymous` debería ser una asignación automática:

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

Teniendo funciones creadoras de *changesets* que tengan una responsabilidad específica (como `registration_changeset/2`) es común, a veces necesitas la flexibilidad de hacer solo ciertas validaciones o filtrar parámetros específicos.
La función de arriba podría ser luego usada en una función de ayuda dedicada `sign_up/1` en cualquier otro sitio:

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## Conclusión

Hay muchos casos de uso y funcionalidad que no hemos cubierto en esta lección tal como [changesets sin esquema](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) que puedes usar para validar _cualquier_ data; o tratar con efecto colaterales a lo largo del *changeset* ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2) o trabajar con asociaciones y embebidos.
Podríamos cubrir estos en una futura lección avanzada, pero por ahora te alentamos a explorar la [documentación de Ecto Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html) para mas información.
