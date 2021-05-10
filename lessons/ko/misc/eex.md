%{
  version: "1.0.2",
  title: "Embedded Elixir (EEx)",
  excerpt: """
  Ruby가 ERB를 Java가 JSP를 가지고 있는 것처럼, Elixir도 EEx, 내장 Elixir를 가지고 있습니다. EEx를 통해서 문자열로 된 Elixir 코드를 심거나 평가할 수 있습니다.
  """
}
---

## API

EEx API는 문자열이나 파일을 직접 사용할 수 있게끔 지원합니다. API는 크게 3개의 컴포넌트로 구성되어 있습니다. 단순 평가, 함수 정의, AST로 컴파일.

### 평가

`eval_string/3`와 `eval_file/2`을 사용해서 문자열이나 파일에 대해서 단순 평가를 할 수 있습니다. 이는 가장 간단한 API이지만, 컴파일 없이 코드가 평가되기 때문에 가장 느립니다.

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### 정의

EEx를 사용하는 방법 중 가장 빠르고, 선호되는 것은 컴파일될 수 있도록 템플릿을 모듈에 삽입하는 것입니다. 이를 위해서는 컴파일 시간에 템플릿과 `function_from_string/5`, `function_from_file/5` 매크로가 필요합니다.

그럼 우리의 인사를 파일로 옮기고, 템플릿을 위한 함수를 생성해봅시다.

```elixir
# greeting.eex
Hi, <%= name %>

defmodule Example do
  require EEx
  EEx.function_from_file(:def, :greeting, "greeting.eex", [:name])
end

iex> Example.greeting("Sean")
"Hi, Sean"
```

### 컴파일

마지막으로, EEx는 `compile_string/2`이나 `compile_file/2`를 통해 문자열이나 파일에서 Elixir AST를 직접 생성할 방법을 제공합니다. 이 API는 주로 위에서 설명한 API에서 사용하고 있습니다만, 내장 Elixir를 처리를 직접 하고 싶은 경우에도 사용 가능합니다.

## 태그

EEx에서 기본으로 지원하는 것은 다음의 4개의 태그입니다.

```elixir
<% Elixir 표현식 - 출력물을 즉시 실행합니다 %>
<%= Elixir 표현식 - 반환된 값으로 대체됩니다 %>
<%% EEx 인용 - 안에 있는 것을 반환합니다 %>
<%# 주석 - 코드에서 제거됩니다 %>
```

결과물을 출력하고 싶은 모든 표현 식은 __반드시__ 등호(`=`)를 사용해야 합니다. 다른 템플릿 언어에서는 `if`와 같은 철을 특별하게 처리하고 있지만, EEx는 그렇지 않기 때문에 중요합니다. `=`가 없다면 아무것도 출력되지 않을 것입니다.

```elixir
<%= if true do %>
  A truthful statement
<% else %>
  A false statement
<% end %>
```

## 엔진

Elixir는 `@name`과 같은 할당을 지원하는 `EEx.SmartEngine`을 기본으로 사용합니다.

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

`EEx.SmartEngine` 할당은 템플릿 컴파일 없이 할당하는 값을 변경할 수 있으므로 유용합니다.

자신만의 엔진을 만드는 것에 흥미가 있으신가요? 무엇이 필요한지 알아보기 위해, [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html)가 어떻게 동작하는지 확인해보세요.
