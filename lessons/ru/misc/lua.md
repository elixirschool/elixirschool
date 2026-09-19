%{
  version: "1.0.0",
  title: "Lua",
  excerpt: """
  Библиотека Lua предоставляет эргономичный интерфейс к Luerl, позволяющий безопасное выполнение изолированных Lua-скриптов прямо в виртуальной машине BEAM. В этом уроке мы исследуем встраивание возможностей Lua-скриптинга в наши Elixir-приложения для пользовательской логики, конфигурации и расширяемости.
  """
}
---

[Библиотека Lua](https://github.com/tv-labs/lua) для Elixir — это эргономичная обёртка над [Luerl](https://github.com/rvirding/luerl), чистой Erlang-реализацией Lua 5.3 от Роберта Вирдинга. В отличие от подходов, опирающихся на NIF или другие механизмы, эта реализация работает целиком на виртуальной машине BEAM и при этом обеспечивает отличную изоляцию и возможности интеграции.

## Зачем использовать Lua в Elixir?

Зачем нам вообще обращаться к Lua, когда Elixir сам по себе такой мощный язык? Дело в том, что при выполнении пользовательского кода Elixir несёт в себе определённые риски. Функция горячей замены кода позволяет заменять модули во время работы приложения, а значит, выполнение ненадёжного Elixir-кода способно перезаписать существующие модули прямо в работающем приложении или внедрить вредоносный код, который переживёт исходный контекст выполнения! Всё это делает прямое выполнение пользовательского Elixir-кода крайне опасным в production-среде и категорически не рекомендуется.

Lua предлагает более безопасную альтернативу: мы можем выполнять пользовательский код, тем самым обогащая наши приложения такими возможностями, как определяемая пользователем бизнес-логика и сложная конфигурация системы.

## Установка

Добавим библиотеку Lua в зависимости `mix.exs`:

```elixir
defp deps do
  [
    {:lua, "~> 0.1.0"}
  ]
end
```

Затем выполним:

```shell
mix deps.get
```

## Основы использования

Начнём с простейшего примера выполнения Lua-кода:

```elixir
iex> {result, _state} = Lua.eval!("return 2 + 3")
{[5], #PID<0.123.0>}
iex> result
[5]
```

Функция `Lua.eval!/2` возвращает кортеж, содержащий результаты (в виде списка) и состояние Lua. Важно отметить, что даже простые выражения возвращают результаты в виде списков — это связано с тем, что Lua-функции могут возвращать несколько значений.

### Сигил ~LUA

Библиотека Lua предоставляет сигил `~LUA`, который проверяет синтаксис Lua на этапе компиляции:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> {[7], _state} = Lua.eval!(~LUA[return 3 + 4])
{[7], #PID<0.124.0>}
```

Если попробовать использовать некорректный синтаксис Lua, получим ошибку компиляции:

```elixir
iex> {result, _state} = Lua.eval!(~LUA[return 2 +])
** (Lua.CompilerException) Failed to compile Lua!
```

### Оптимизация на этапе компиляции

Модификатор `c` в сочетании с сигилом компилирует наш Lua-код в `Lua.Chunk.t()` во время компиляции, что улучшает производительность во время выполнения:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> {[42], _state} = Lua.eval!(~LUA[return 6 * 7]c)
{[42], #PID<0.125.0>}
```

## Работа с состоянием Lua

Каждая среда выполнения Lua поддерживает собственное состояние, включая переменные, функции и данные. Мы можем создавать это состояние и управлять им:

```elixir
iex> lua = Lua.new()
#PID<0.126.0>

# Устанавливаем переменную
iex> lua = Lua.set!(lua, [:my_var], 42)
#PID<0.126.0>

# Читаем её обратно
iex> {[42], _state} = Lua.eval!(lua, "return my_var")
{[42], #PID<0.126.0>}
```

Также можно работать с вложенными структурами данных:

```elixir
iex> lua = Lua.new()
iex> lua = Lua.set!(lua, [:config, :database, :port], 5432)
iex> {[5432], _state} = Lua.eval!(lua, "return config.database.port")
{[5432], #PID<0.127.0>}
```

## Предоставление функций Elixir в Lua

### Простое предоставление функций

Самый прямолинейный способ предоставить функцию Elixir в Lua — использовать `Lua.set!/3`:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> 
iex> lua = 
...>   Lua.new()
...>   |> Lua.set!([:sum], fn args -> [Enum.sum(args)] end)
#PID<0.128.0>

iex> {[10], _state} = Lua.eval!(lua, ~LUA[return sum(1, 2, 3, 4)]c)
{[10], #PID<0.128.0>}
```

Обратите внимание, что функции Elixir, предоставляемые в Lua, должны:
- Принимать список аргументов
- Возвращать список результатов (даже для одиночных значений)

### Использование макроса `deflua`

Для более сложных API можно использовать макрос `deflua`:

```elixir
defmodule MathAPI do
  use Lua.API

  deflua add(a, b), do: a + b
  deflua multiply(a, b), do: a * b
  deflua power(base, exponent), do: :math.pow(base, exponent)
end

# Загружаем API в состояние Lua
iex> lua = Lua.new() |> Lua.load_api(MathAPI)
iex> {[16.0], _state} = Lua.eval!(lua, ~LUA[return power(2, 4)])
{[16.0], #PID<0.129.0>}
```

### API с пространствами имён

Опция `:scope` предоставляет нам механизм для организации функций в пространствах имён:

```elixir
defmodule StringAPI do
  use Lua.API, scope: "str"

  deflua upper(text), do: String.upcase(text)
  deflua lower(text), do: String.downcase(text)
  deflua length(text), do: String.length(text)
end

iex> lua = Lua.new() |> Lua.load_api(StringAPI)
iex> {["HELLO"], _state} = Lua.eval!(lua, ~LUA[return str.upper("hello")])
{["HELLO"], #PID<0.130.0>}
```

### API с состоянием

Иногда может потребоваться обращаться к состоянию Lua или изменять его непосредственно из наших API-функций — для этого состояние передаётся вторым аргументом `deflua`:

```elixir
defmodule CounterAPI do
  use Lua.API, scope: "counter"

  deflua increment(), state do
    current = Lua.get(state, [:count], 0)
    new_count = current + 1
    state = Lua.set!(state, [:count], new_count)
    {[new_count], state}
  end

  deflua get_count(), state do
    count = Lua.get(state, [:count], 0)
    {[count], state}
  end
end

iex> lua = Lua.new() |> Lua.load_api(CounterAPI)
iex> {[1], lua} = Lua.eval!(lua, ~LUA[return counter.increment()])
iex> {[2], lua} = Lua.eval!(lua, ~LUA[return counter.increment()])
iex> {[2], _state} = Lua.eval!(lua, ~LUA[return counter.get_count()])
```

### Вызов Lua-функций из Elixir

Мы также можем вызывать Lua-функции из нашего Elixir-кода с помощью `Lua.call_function!/3`:

```elixir
defmodule StringProcessorAPI do
  use Lua.API, scope: "processor"

  deflua process_with_lua(text), state do
    # Вызываем Lua-функцию для обработки текста
    Lua.call_function!(state, [:string, :upper], [text])
  end
end

iex> lua = Lua.new() |> Lua.load_api(StringProcessorAPI)
iex> {["PROCESSED"], _state} = Lua.eval!(lua, ~LUA[return processor.process_with_lua("processed")])
```

## Типы данных и кодирование

При работе с Lua важно понимать, как типы данных Elixir преобразуются в типы Lua:

| Тип Elixir | Тип Lua | Требует кодирования? |
|------------|---------|----------------------|
| `nil` | `nil` | Нет |
| `boolean()` | `boolean` | Нет |
| `number()` | `number` | Нет |
| `binary()` | `string` | Нет |
| `atom()` | `string` | Да |
| `map()` | `table` | Да |
| `list()` | `table` | Возможно* |
| `{:userdata, any()}` | `userdata` | Да |

*Списки требуют кодирования только в том случае, если содержат элементы, нуждающиеся в кодировании.

### Работа с ассоциативными массивами и таблицами

При кодировании ассоциативные массивы Elixir превращаются в таблицы Lua:

```elixir
iex> config = %{database: %{host: "localhost", port: 5432}, debug: true}
iex> {encoded_config, lua} = Lua.encode!(Lua.new(), config)
iex> lua = Lua.set!(lua, [:config], encoded_config)
iex> {[5432], _state} = Lua.eval!(lua, "return config.database.port")
{[5432], #PID<0.131.0>}
```

### Пользовательские данные для сложных структур

Для передачи сложных структур данных Elixir, которые мы не хотим отдавать на изменение Lua:

```elixir
defmodule User do
  defstruct [:id, :name, :email]
end

iex> user = %User{id: 1, name: "Alice", email: "alice@example.com"}
iex> {encoded_user, lua} = Lua.encode!(Lua.new(), {:userdata, user})
iex> lua = Lua.set!(lua, [:current_user], encoded_user)
iex> {[{:userdata, %User{id: 1, name: "Alice", email: "alice@example.com"}}], _state} = 
...>   Lua.eval!(lua, "return current_user")
{[{:userdata, %User{id: 1, name: "Alice", email: "alice@example.com"}}], #PID<0.132.0>}
```

## Приватный контекст и безопасность

Одна из самых мощных возможностей — поддержка приватного контекста, доступного нашему Elixir-коду, но скрытого от Lua-скриптов:

```elixir
defmodule UserAPI do
  use Lua.API, scope: "user"

  deflua get_name(), state do
    user = Lua.get_private!(state, :current_user)
    {[user.name], state}
  end

  deflua get_permission(resource), state do
    user = Lua.get_private!(state, :current_user)
    permissions = Lua.get_private!(state, :permissions)
    
    has_permission = resource in Map.get(permissions, user.id, [])
    {[has_permission], state}
  end
end

# Настраиваем контекст выполнения
user = %{id: 1, name: "Alice"}
permissions = %{1 => ["read_posts", "write_comments"]}

lua = 
  Lua.new()
  |> Lua.put_private(:current_user, user)
  |> Lua.put_private(:permissions, permissions)
  |> Lua.load_api(UserAPI)

# Пользователь может только получить своё имя и проверить права
{["Alice"], _state} = Lua.eval!(lua, ~LUA[return user.get_name()])
{[true], _state} = Lua.eval!(lua, ~LUA[return user.get_permission("read_posts")])
{[false], _state} = Lua.eval!(lua, ~LUA[return user.get_permission("admin_panel")])
```

## Практический пример: движок конфигурации

Давайте создадим практический пример, который позволит пользователям определять сложные бизнес-правила:

```elixir
defmodule PricingAPI do
  use Lua.API, scope: "pricing"

  deflua get_base_price(product_type), state do
    prices = Lua.get_private!(state, :base_prices)
    price = Map.get(prices, product_type, 0)
    {[price], state}
  end

  deflua calculate_discount(user_tier, order_amount), _state do
    discount = case user_tier do
      "premium" when order_amount >= 100 -> 0.2
      "premium" -> 0.1
      "standard" when order_amount >= 50 -> 0.05
      _ -> 0.0
    end
    {[discount], state}
  end

  deflua apply_seasonal_modifier(month), _state do
    modifier = case month do
      12 -> 0.9  # Скидка в декабре
      1 -> 0.95  # Скидка в январе
      _ -> 1.0
    end
    {[modifier], state}
  end
end

defmodule ConfigEngine do
  def calculate_price(product_type, quantity, user_tier, lua_script) do
    base_prices = %{
      "widget" => 10.0,
      "gadget" => 25.0,
      "premium_item" => 100.0
    }

    lua = 
      Lua.new()
      |> Lua.put_private(:base_prices, base_prices)
      |> Lua.load_api(PricingAPI)
      |> Lua.set!([:product_type], product_type)
      |> Lua.set!([:quantity], quantity)
      |> Lua.set!([:user_tier], user_tier)
      |> Lua.set!([:current_month], Date.utc_today().month)

    {[final_price], _state} = Lua.eval!(lua, lua_script)
    final_price
  end
end
```

Теперь пользователи смогут определять сложную логику ценообразования под свои нужды, не требуя от нас реализации множества различных сценариев в коде приложения:

```elixir
pricing_script = ~LUA"""
base_price = pricing.get_base_price(product_type)
subtotal = base_price * quantity

discount = pricing.calculate_discount(user_tier, subtotal)
seasonal_modifier = pricing.apply_seasonal_modifier(current_month)

final_price = subtotal * (1 - discount) * seasonal_modifier
return final_price
"""c

# Считаем цену для премиум-пользователя, покупающего 5 виджетов в декабре
price = ConfigEngine.calculate_price("widget", 5, "premium", pricing_script)
# Результат: 50 * 0.8 * 0.9 = 36.0
```

## Обработка ошибок и отладка

Библиотека Lua предоставляет более информативные сообщения об ошибках по сравнению с «сырым» Luerl:

```elixir
iex> try do
...>   Lua.eval!("return undefined_function()")
...> rescue
...>   e -> IO.puts("Lua error: #{inspect(e)}")
...> end
```

Для ошибок валидации на этапе компиляции:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> try do
...>   ~LUA[return 2 +]
...> rescue
...>   e in Lua.CompilerException -> IO.puts("Compile error: #{e.message}")
...> end
Compile error: Failed to compile Lua!
```

Для отладки можно инспектировать состояние Lua:

```elixir
iex> lua = Lua.new() |> Lua.set!([:debug_var], "debugging")
iex> variables = Lua.get_globals(lua)
iex> IO.inspect(variables)
```

## Тестирование интеграции с Lua

При тестировании кода, использующего Lua, мы можем передавать управляемые Lua-скрипты:

```elixir
defmodule MyAppTest do
  use ExUnit.Case
  import Lua, only: [sigil_LUA: 2]

  test "pricing calculation with lua script" do
    script = ~LUA[return base_price * quantity * 0.9]c
    
    lua = 
      Lua.new()
      |> Lua.set!([:base_price], 10.0)
      |> Lua.set!([:quantity], 3)

    {[result], _state} = Lua.eval!(lua, script)
    assert result == 27.0
  end

  test "error handling for invalid lua" do
    assert_raise Lua.CompilerException, fn ->
      Lua.eval!(~LUA[return invalid syntax])
    end
  end
end
```

## О чём стоит подумать

При интеграции Lua в наши Elixir-приложения есть ряд важных соображений в области производительности и безопасности, которые помогут обеспечить эффективное и защищённое выполнение.

### Производительность

С точки зрения производительности наибольший эффект даёт использование компилируемых чанков с модификатором `c` в сигилах `~LUA` — это устраняет накладные расходы на разбор кода при каждом выполнении. Также рекомендуется по возможности повторно использовать состояние Lua, поскольку создание нового состояния требует дорогостоящей инициализации всей среды Lua.

Преобразование данных может стать узким местом при работе с большими наборами данных, поэтому хранение данных в совместимых форматах снижает накладные расходы на конвертацию. Ещё одно соображение, влияющее как на производительность, так и на безопасность: предоставляйте только те функции, которые действительно нужны вашим скриптам, — каждая дополнительная функция увеличивает потребление памяти и потенциальные риски безопасности.

### Безопасность

При выполнении пользовательского кода никогда не предоставляйте опасные функции, обращающиеся к файловой системе, сети или процессам, — вредоносные скрипты могут скомпрометировать всё приложение. Если необходимо хранить конфиденциальные данные в состоянии Lua, используйте приватный контекст, а не Lua-переменные: приватный контекст изолирован от среды выполнения Lua.

Наконец, следуйте принципу минимальных привилегий и предоставляйте только необходимые API — каждая функция представляет собой потенциальный вектор атаки для вредоносных скриптов.

## Заключение

Библиотека Lua для Elixir предоставляет мощный и безопасный способ добавить в наши приложения возможность пользовательского скриптинга. Опираясь на сильные стороны виртуальной машины BEAM и возможности изоляции Luerl, мы можем строить гибкие и расширяемые системы, позволяющие пользователям настраивать поведение приложения без ущерба для безопасности.

Бесшовная интеграция между Elixir и Lua в сочетании с гарантиями безопасности, которые даёт выполнение всего кода на виртуальной машине BEAM, делает эту библиотеку отличным выбором для приложений, которым необходимо безопасно и эффективно выполнять пользовательски определённую логику.
