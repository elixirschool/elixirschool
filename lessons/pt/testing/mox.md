%{
  version: "1.0.1",
  title: "Mox",
  excerpt: """
  Mox é uma biblioteca feita para criar mocks concorrentes em Elixir.
  """
}
---

## Escrever Código Testável

Os testes e os mocks que os facilitam não são, normalmente, o destaque de qualquer linguagem, e, por isso, não é surpreendente que exista menos literatura sobre eles.
No entanto, você pode _absolutamente_ usar mocks em Elixir!
A metodologia exata pode ser um pouco diferente da que você está familiarizado em outras linguagens, mas o objetivo final é o mesmo: os mocks podem simular o output de funções internas e, então, permitem-lhe verificar todos os possíveis caminhos de execução do seu código.

Antes de vermos casos de uso mais complexos, vamos falar de algumas técnicas que podem nos ajudar a tornar o nosso código mais testável.
Uma tática simples é passar um módulo para uma função em vez de ter o módulo hard-coded dentro da função.

Por exemplo, se escrevermos um cliente HTTP diretamente dentro de uma função:

```elixir
def get_username(username) do
  HTTPoison.get("https://elixirschool.com/users/#{username}")
end
```

Poderíamos, em vez disso, passar o módulo do cliente HTTP como argumento assim:

```elixir
def get_username(username, http_client) do
  http_client.get("https://elixirschool.com/users/#{username}")
end
```

Ou poderíamos usar a função [apply/3](https://hexdocs.pm/elixir/Kernel.html#apply/3) que realiza o mesmo:

```elixir
def get_username(username, http_client) do
  apply(http_client, :get, ["https://elixirschool.com/users/#{username}"])
end
```

Passar o módulo como argumento ajuda a separar as responsabilidades e, se não nos assustarmos demais com a verbosidade de programação orientada a objetos na definição, poderemos reconhecer esta inversão de controle como uma espécie de [Injeção de Dependência](https://en.wikipedia.org/wiki/Dependency_injection).
Para testar o método `get_username/2`, você só precisaria passar um módulo com uma função `get` que retorne o valor necessário para as suas verificações.

Esta lógica é muito simples, e, por isso, é apenas útil quando a função é facilmente acessível (e não, por exemplo, quando está enterrada em algum lugar bem fundo de uma função privada).

Uma tática mais flexível depende de configuração da aplicação.
Talvez não se tenha ainda apercebido, mas uma aplicação Elixir mantém o estado na sua configuração.
Em vez de chamar um módulo diretamente ou passá-lo como um argumento, pode ler o mesmo a partir da configuração da aplicação.

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

Então, no seu arquivo de configuração:

```elixir
config :my_app, :http_client, HTTPoison
```

Esta lógica e a sua dependência na configuração da aplicação forma a base de tudo que se segue.

Se você é propenso a pensar demais, sim, poderia omitir a função `http_client/0` e chamar diretamente `Application.get_env/2`, e, sim, poderia também fornecer um terceiro argumento padrão a `Application.get_env/3` e obter o mesmo resultado.

Nos aproveitar do configuração da aplicação nos permite ter implementações específicas do módulo para cada ambiente; você poderia fazer referência a um módulo sandbox para o ambiente `dev` enquanto que o ambiente `test` poderia usar um módulo da memória.

Contudo, ter um único módulo fixo por ambiente pode não ser flexível o suficiente: dependendo de como a sua função é usada, você pode precisar devolver diferentes respostas para conseguir testar todos os caminhos de execução possíveis.
O que a maior parte das pessoas não sabe é que você pode _mudar_ a configuração da aplicação em templo de execução!
Vamos dar uma olhada em [Application.put_env/4](https://hexdocs.pm/elixir/Application.html#put_env/4).

Imagine que a sua aplicação precisa agir de forma diferente dependendo de se a requisição HTTP foi, ou não, feita com sucesso.
Poderíamos criar múltiplos módulos, cada um com uma função `get/1`.
Um módulo poderia devolver uma tupla `:ok`, e outro poderia devolver uma tupla `:error`.
Então, depois poderíamos usar o `Application.put_env/4` para definir a configuração antes de chamar a nossa função `get_username/1`.
O nosso módulo de teste teria mais ou menos este aspecto:

```elixir
# Don't do this!
defmodule MyAppTest do
  use ExUnit.Case

  setup do
    http_client = Application.get_env(:my_app, :http_client)
    on_exit(
      fn ->
        Application.put_env(:my_app, :http_client, http_client)
      end
    )
  end

  test ":ok on 200" do
    Application.put_env(:my_app, :http_client, HTTP200Mock)
    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    Application.put_env(:my_app, :http_client, HTTP404Mock)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

É assumido que você tenha criado os módulos necessários em algum lugar (`HTTP200Mock` e `HTTP404Mock`).
Nós adicionamos um callback [`on_exit`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#on_exit/2) ao [`setup`](https://hexdocs.pm/ex_unit/master/ExUnit.Callbacks.html#setup/1) para assegurar que o `:http_client` é devolvido ao seu estado anterior depois de cada teste.

No entanto, um padrão como o descrito acima normalmente _NÃO_ é algo que você deva seguir ou fazer!
As razãos para isto poderão não ser imediatamente óbvias.

Primeiramente, não há nada que garante que os módulos que definimos no nosso `:http_client` podem fazer o que necessitam de fazer: não há aqui a imposição de um contrato que requer que os módulos tenham uma função `get/1`.

Em segundo lugar, testes como o descrito acima não podem rodar com segurança de forma assíncrona.
Devido ao estado da aplicação ser partilhado por _toda_ a aplicação, é completamente possível que quando você dá override do `:http_client` num teste, que um outro teste (rodando simultaneamente) espere um resultado diferente.
Você pode ter encontrado problemas como este quando o teste é executado _usualmente_ passa, mas às vezes falha inexplicavelmente. Cuidado!

Em terceiro lugar, esta abordagem pode ficar confusa porque você acaba com um conjunto de módulos mock em algum lugar no meio da sua aplicação. Que nojo.

Fizemos uma demonstração da estrutura acima porque descreve a abordagem de uma forma bastante direta que nos ajuda a compreender um pouco melhor sobre como a solução _real_ funciona.

## Mox : A Solução para todos os Problemas

A bibiloteca ideal para trabalhar com mocks em Elixir é a [Mox](https://hexdocs.pm/mox/Mox.html), de autoria do próprio José Valim, e resolve todos os problemas delineados acima.

Lembre-se: como requisito, o seu código deve olhar para a configuração da sua aplicação para obter o seu módulo configurado:

```elixir
def get_username(username) do
  http_client().get("https://elixirschool.com/users/#{username}")
end

defp http_client do
  Application.get_env(:my_app, :http_client)
end
```

Depois poderá incluir `mox` nas suas dependências:

```elixir
# mix.exs
defp deps do
  [
    # ...
    {:mox, "~> 0.5.2", only: :test}
  ]
end
```

Instale o mesmo com `mix deps.get`.

Depois, modifique o seu `test_helper.exs` para que este faça 2 coisas:

1. deve definir um ou mais mocks
2. deve definir a configuração da aplicação com o mock

```elixir
# test_helper.exs
ExUnit.start()

# 1. definir mocks dinâmicos
Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)
# ... etc...

# 2. Dar override das configurações do config (similar a adicionar os mesmos a `config/test.exs`)
Application.put_env(:my_app, :http_client, HTTPoison.BaseMock)
# ... etc...
```

Algumas coisas importantes a se notar sobre o `Mox.defmock`: o nome do lado esquerdo é arbitrário.
Os nomes dos módulos em Elixir são apenas atoms -- você não precisa criar o módulo em nenhum, tudo que você está fazendo é "reservando" um nome para o módulo mock.
Nos bastidores, o Mox irá criar o módulo com esse nome em tempo real dentro do BEAM.

A segunda coisa complicada é que o módulo referido por `for:` _deve_ ser um comportamento: _deve_ definir callbacks.
Mox usa introspecção neste módulo e você poderá apenas definir funções mock quando uma `@callback` tiver sido definida.
É assim que o Mox aplica o contrato.
Às vezes pode ser difícil encontrar o módulo de comportamento: `HTTPoison`, por exemplo, depende do `HTTPoison.Base`, mas você não tem forma de saber isso a não ser que olhe para o código fonte.
Se estiver a tentar criar um mock para uma biblioteca de terceiro, poderá já ter descoberto que esse comportamento não existe!
Nesses casos você poderá ter de definir o seu próprio comportamento e callbacks para satisfazer a necessidade de um contrato.

Esta situação traz consigo um ponto importante: você poderá querer usar uma camada de abstração (ou seja, [indirection](https://en.wikipedia.org/wiki/Indirection)) para que a sua aplicação não dependa de uma biblioteca de terceiro _diretamente_, mas, em vez disso, você usaria o seu próprio módulo que, por sua vez, usaria essa biblioteca.
É importante, numa aplicação bem desenhada e concebida, definir os "limites" adequados, mas a mecânica dos mocks não se altera, por isso, não deixe que isso o atrapalhe.

Finalmente, nos nossos módulos de teste, você pode colocar os seus mocks em uso ao importar `Mox` e chamando a sua função `:verify_on_exit!`.
Depois você estará livre de definir os valores de retorno dos seus módulos mock usando uma ou mais chamadas para a função `expect`:

```elixir
defmodule MyAppTest do
  use ExUnit.Case, async: true
  # 1. Importar Mox
  import Mox
  # 2. setup da configuração
  setup :verify_on_exit!

  test ":ok on 200" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:ok, "What a guy!"} end)

    assert {:ok, _} = MyModule.get_username("twinkie")
  end

  test ":error on 404" do
    expect(HTTPoison.BaseMock, :get, fn _ -> {:error, "Sorry!"} end)
    assert {:error, _} = MyModule.get_username("does-not-exist")
  end
end
```

Para cada teste, nós fazemos referência ao _mesmo_ módulo mock (`HTTPoison.BaseMock` neste exemplo), e usamos a função `expect` para definir o valor que é retornado para cada função chamada.

Usar o `Mox` é perfeitamente seguro para uma execução assíncrona, e requer que cada mock siga um contrato.
Atendendo que estes mocks são "virtuais", não há necessidade de definir módulos reais que poderiam atrapalhar a nossa aplicação.

Bem vindo aos mocks em Elixir!
