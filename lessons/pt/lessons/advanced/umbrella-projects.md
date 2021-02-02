%{
  version: "1.0.3",
  title: "Projetos Guarda-chuva",
  excerpt: """
  Em determinados momentos um projeto pode ficar enorme, realmente enorme. A ferramenta de construção Mix nos permite dividir nosso código em vários aplicativos e fazer nossos projetos em Elixir mais manejáveis à medida que crescem.
  """
}
---

## Introdução

Para criar um projeto guarda-chuva nós iniciamos um projeto como se iniciássemos um projeto Mix normal, mas colocando o argumento `--umbrella`. Neste exemplo, faremos o *shell* de um kit de ferramentas de aprendizado de máquina. Por que um kit de ferramentas de aprendizado de máquina? Por que não? É composto de vários algoritmos de aprendizado e funções de utilidades diferentes.


```shell
$ mix new machine_learning_toolkit --umbrella

* creating .gitignore
* creating README.md
* creating mix.exs
* creating apps
* creating config
* creating config/config.exs

Your umbrella project was created successfully.
Inside your project, you will find an apps/ directory
where you can create and host many apps:

    cd machine_learning_toolkit
    cd apps
    mix new my_app

Commands like "mix compile" and "mix test" when executed
in the umbrella project root will automatically run
for each application in the apps/ directory.
```

Como você pode ver a partir do comando Mix no shell, foi criado um pequeno projeto de esqueleto para nós com dois diretórios:

  - `apps/` - onde nossos sub-projetos (filhos) ficarão
  - `config/` - onde a nossa configuração dos  projetos guarda-chuva permanecerá


## Projetos filhos

Vamos mudar para o diretório de projetos `machine_learning_toolkit/apps` e criar 3 aplicações normais usando Mix desta forma:

```shell
$ mix new utilities

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/utilities.ex
* creating test
* creating test/test_helper.exs
* creating test/utilities_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd utilities
    mix test

Run "mix help" for more commands.


$ mix new datasets

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/datasets.ex
* creating test
* creating test/test_helper.exs
* creating test/datasets_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd datasets
    mix test

Run "mix help" for more commands.

$ mix new svm

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/svm.ex
* creating test
* creating test/test_helper.exs
* creating test/svm_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd svm
    mix test

Run "mix help" for more commands.
```

Agora devemos ter um árvore de projeto desta forma:

```shell
$ tree
.
├── README.md
├── apps
│   ├── datasets
│   │   ├── README.md
│   │   ├── lib
│   │   │   └── datasets.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── datasets_test.exs
│   │       └── test_helper.exs
│   ├── svm
│   │   ├── README.md
│   │   ├── lib
│   │   │   └── svm.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── svm_test.exs
│   │       └── test_helper.exs
│   └── utilities
│       ├── README.md
│       ├── lib
│       │   └── utilities.ex
│       ├── mix.exs
│       └── test
│           ├── test_helper.exs
│           └── utilities_test.exs
├── config
│   └── config.exs
└── mix.exs
```

Se voltarmos para raíz do projeto guarda-chuva, vemos que podemos chamar todos os comandos típicos, tais como o de compilação. Como os sub-projetos são apenas aplicações normais, você pode entrar nos diretórios e fazer todas as mesmas coisas que usualmente o Mix permite fazer.

```bash
$ mix compile

==> svm
Compiled lib/svm.ex
Generated svm app

==> datasets
Compiled lib/datasets.ex
Generated datasets app

==> utilities
Compiled lib/utilities.ex
Generated utilities app

Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
```

## IEx

Você pode pensar que a interação com os aplicativos poderia ser um pouco diferente em um projeto guarda-chuva. Bem, acredite ou não, você estaria errado! Se mudarmos o diretório para o diretório de nível superior e iniciar o IEx com o `iex -S mix` podemos interagir normalmente com todos os projetos. Alteraremos os conteúdos de `apps/datasets/lib/datasets.ex` para este exemplo simples.

```elixir
defmodule Datasets do
  def hello do
    IO.puts("Hello, I'm the datasets")
  end
end
```

```shell
$ iex -S mix
Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

==> datasets
Compiled lib/datasets.ex
Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)

iex> Datasets.hello
Hello, I'm the datasets
:ok
```
