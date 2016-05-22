---
layout: page
title: 문서화
category: basics
order: 11
lang: ko
---

Elixir 코드 문서화하기.

{% include toc.html %}

## 주석

프로그래밍을 할 때 우리가 얼마나 주석을 달아야 하는지, 무엇이 문서화의 품질을 보장하는지는 논란의 여지가 있습니다. 그러나, 우리가 동일한 코드베이스를 가지고 협업하는데 있어서 문서화가 얼마나 중요한 지는 모두가 동의하고 있습니다.


Elixir에서는 문서화를 *일급 시민*으로 취급하고 있습니다. 이는 다양한 함수에 접근하여 여러분의 프로젝트에 대한 문서를 생성합니다. Elixir는 코드베이스에 주석을 달기 위한 여러가지 다양한 특성을 코어에서 제공합니다.  다음의 3가지 방식을 보도록 합시다:

  - `#` - 인라인으로 문서화하고자 할 때 쓰입니다.
  - `@moduledoc` - 모듈 수준에서 문서화하고자 할 때 쓰입니다.
  - `@doc` - 함수 수준에서 문서화하고자 할 때 쓰입니다.

### 인라인 문서화

코드에 주석을 다는 가장 심플한 방법은 인라인 주석일 겁니다. Ruby, Python과 비슷하게 Elixir의 인라인 주석은 `#`로 나타낼 수 있습니다. 이는 환경에 따라 다르지만 *파운드* 또는 *해시* 로 알려져 있기도 합니다. 

다음의 Elixir 스크립트를 봅시다(greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts "Hello, " <> "chum."
```

이 스크립트가 돌아가는 동안, Elixir는 `#`로 시작하여 라인이 끝나는 부분까지 읽어들이지 않고 버립니다. 이는 연산에 대해 어떤 값을 부여하지도 않고 스크립트의 성능에 어떠한 영향도 주지 않습니다. 그러나, 어떤 일이 일어날 지 확신이 서지 않을 때, 프로그래머가 이 부분에 대해 여러분의 주석을 읽으면서 알아야 합니다. 한 줄 주석을 너무 남용하지 않도록 주의하세요! 한 줄 주석으로 코드베이스를 채우는 것이 누군가에게는 불쾌한 악몽이 될 수도 있습니다.

### 모듈 문서화하기

`@moduledoc` 주석자는 모듈 수준에서 인라인 주석을 달 수 있게 해줍니다. 일반적으로, 파일의 첫번째 줄에 있는 `defmodule` 선언부의 바로 아래에 위치합니다. `@moduledoc`으로 장식된 한 줄 주석을 아래의 예제에서 볼 수 있습니다.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

IEx에서 모듈의 문서에 접근하고자 한다면 `h` 헬퍼 함수를 이용할 수 있습니다.

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### 함수 문서화하기


Elixir는 모듈 범위에서 주석을 달 수 있게 해주었듯이, 함수 범위에서도 비슷한 방식으로 주석을 달 수 있게 해줍니다. `@doc` 주석자는 함수 수준에서의 인라인 주석을 가능하게 해줍니다. `@doc` 주석자는 주석을 달고자 하는 함수 선언부의 바로 위쪽에 위치합니다.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t) :: String.t
  def hello(name) do
    "Hello, " <> name
  end
end
```

다시 IEx로 들어갑시다. 모듈의 이름이 딸린 함수에 대해 헬퍼 명령(`h`)을 이용하면 다음과 같은 화면을 볼 수 있습니다.

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

`hello/1` prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

문서 내에서 마크업을 어떻게 이용하고, 터미널이 이를 어떻게 렌더링하는지 주목하세요. 더욱 세련되어지거나 Elixir 생태계에 멋진 기능들이 추가되는 것들을 떠나서, ExDoc가 HTML 문서를 한번에 생성한다는 것이 엄청 흥미롭게 느껴질 겁니다.

## ExDoc

ExDoc는 **HTML(HyperText Markup Language) 문서를 생성하여 Elixir 프로젝트를 위한 온라인 문서를 제공하는** 공식 Elixir 프로젝트 입니다. 물론, [Github](https://github.com/elixir-lang/ex_doc)에서 찾을 수 있는 프로젝트 한정입니다. 먼저, 어플리케이션을 만들기 위해 Mix 프로젝트를 생성해 봅시다:


```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone
```


이제 `@doc` 레슨에서 보았던 코드들을 `lib/greeter.ex`라는 파일에 복사/붙여넣기하고, 모든 코드들이 여전히 잘 동작하는지 커맨드라인으로 확인해보세요. Mix 프로젝트 폴더 내에 있으므로, `iex -S mix` 명령 시퀀스로 조금 색다르게 IEx를 시작해야 합니다.


```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```


### 설치하기

모든 것들이 제대로 동작한다고 가정했을 때, 위의 출력에서 ExDoc를 셋업할 준비가 되어있다는 것을 볼 수 있습니다. `mix.exs` 파일 내부에 의존성을 `:earmark`, `:ex_doc` 이렇게 두 가지 추가해두세요;


```elixir
  def deps do
    [{:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
```

프로덕션 환경에서 이 의존성들이 다운로드 받아서 컴파일되는 것을 원하지 않기 때문에 `only: :dev` 키-값 쌍을 명시해 두었습니다. 왜 Earmark를 쓸까요? Earmark는 elixir 프로그래밍 언어를 위한 마크다운 파서 입니다. ExDoc를 이용하여 `@moduledoc`, `@doc` 내부의 문서를 HTML 문서로 아름답게 변환시켜 줍니다.


Earmark를 쓸 필요가 없다면, 그닥 의미를 가지지 않습니다. 여러분은 마크업 툴을 Pandoc이나 Hoedown, 혹은 Cmark로 바꿀 수도 있습니다; 그렇다면, [여기](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool)를 참고해서 설정을 조금 더 건드려야 할 필요가 있습니다. 여기서는, Earmark 중심으로 다루도록 하겠습니다.

### 문서화 생성하기

계속해서, 커맨드 라인에서 다음과 같이 두 개의 명령을 실행해보세요:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

모든 것들이 계획대로 돌아갔을 때, 위의 예제와 같은 출력 메시지와 유사한 메시지를 볼 수 있습니다. Mix 프로젝트 내부를 들여다보았을 때, **doc/**라는 디렉토리를 볼 수 있을 겁니다. 그 내부에는 자동으로 생성된 문서가 있습니다. 웹 브라우저로 색인 페이지를 열어보면 다음과 같은 화면을 보게 될 것입니다.

![ExDoc Screenshot 1]({{ site.url }}/assets/documentation_1.png)

Earmark가 마크다운을 렌더링하고 ExDoc가 이를 쓸만한 포멧으로 표시하는 것을 볼 수 있습니다. 

![ExDoc Screenshot 2]({{ site.url }}/assets/documentation_2.png)

Github에 배포할 수도 있고, 홈페이지에도 배포할 수 있지만, 흔하게는 [HexDocs](https://hexdocs.pm/)에 배포하기도 합니다.

## 좋은 습관

Elixir의 모범 가이드 라인에 따라 주석을 달아야 합니다. Elixir는 확실히 역사가 오래되지 않은 언어이기 때문에, 생태계가 커져감에 따라 많은 표준들이  생겨날 것입니다. 커뮤니티에서도 좋은 습관을 정립하기 위해 많은 노력을 기울여 왔습니다. 좋은 습관들에 대해서 더 알아보고자 한다면 [엘릭서 스타일 가이드](https://github.com/niftyn8/elixir_style_guide)를 보세요. 

  - 항상 모듈을 문서화해두세요.


```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

- 모듈을 문서화하고자 하는 것이 아니라면, `@moduledoc`을 공백으로 **비워 두지 마세요**. 차라리 다음과 같이 `false`로 두는 게 낫습니다:


```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - 모듈 문서 내에서 함수를 설명하고자 할 때, 다음과 같이 역따옴표를 이용해보세요:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```

 - `@moduledoc` 밑으로는 어떤 코드든지 다음과 같이 한 줄씩 비워두세요:


```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```


 - IEx나 ExDoc에서 쉽게 읽을 수 있게, 함수 내부에 마크다운 문법으로 주석을 달아보세요: 


```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t) :: String.t
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - 여러분의 문서에 코드 예제를 첨삭하도록 해보세요. 모듈, 함수 혹은 [ExUnit.DocTest][] 매크로 내에서 코드 예제를 발견하여 자동화된 테스트를 생성할 수 있습니다. 매크로를 이용하고자 한다면, 테스트 케이스로부터  `doctest/1` 매크로를 불러온 후 [공식 문서][ExUnit.DocTest]에 명시된 가이드라인에 따라 예시 코드를 작성할 필요가 있습니다.
 
[ExUnit.DocTest]: http://elixir-lang.org/docs/master/ex_unit/ExUnit.DocTest.html
