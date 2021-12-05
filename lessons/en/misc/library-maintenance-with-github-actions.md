%{ version: "1.0.0", title: "Library Maintenance with GitHub Actions", excerpt: """
A guideline about setting up a healthy maintenance environment for libraries using GitHub Actions.
"""
}
---

We will learn how to configure healthy environment for Elixir libraries hosted on [Github](https://github.com)
using [GitHub Actions](https://docs.github.com/en/actions).

[GitHub Actions: Reusing workflows](https://docs.github.com/en/actions/learn-github-actions/reusing-workflows)

## Collaboration Phase

- [Typespec](https://github.com/jeremyjh/dialyxir)
- [Linter](https://github.com/rrrene/credo)
- [Formatter](https://hexdocs.pm/mix/Mix.Tasks.Format.html)
- [Testing](https://hexdocs.pm/mix/Mix.Tasks.Test.html)

```yaml
name: ci

on:
  push:
    branches:
      - master
  pull_request:
    branches:
      - master

jobs:
  qa:
    uses: straw-hat-team/github-actions-workflows/.github/workflows/elixir-quality-assurance.yml@v0.1.1
    with:
      elixir-version: '1.11'
      otp-version: '22.3'
      testing-enabled: false
      formatter-enabled: false
      credo-enabled: false
      dialyzer-enabled: false
```

### dialyzer

Add the [Dialyxir](https://github.com/jeremyjh/dialyxir) dependency:

```elixir
defmodule MyLibrary.MixProject do
  use Mix.Project

  def project do
    [
      # ...
      deps: deps()
    ]
  end
  
  defp deps do
    [
      # ...
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false}
    ]
  end
end
```

In your `mix.exs`, you must configure Dialyzer with the following settings:

```elixir
defmodule MyLibrary.MixProject do
  use Mix.Project

  def project do
    [
      # ...
      dialyzer: [
        # ... other dialyzer settings
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end
end
```

Make sure that `priv/plts` directory exists before running Dialyzer. Create a file called `priv/plts/.gitkeep` and
commit the file as part of your repository to make sure the directory exists at all time.

```shell
# Creates priv/plts directory if it doesn't exists 
mdkir -p priv/plts
# Create an empty file
touch priv/plts/.gitkeep
```

You probably do not want to commit the `plts` files therefore add the following content to your `.gitignore` file:

```.gitignore
/priv/plts/*.plt
/priv/plts/*.plt.hash
```

### Releasing Phase

Create a [Hex](https://hex.pm) API Key following [Publishing from CI](https://hex.pm/docs/publish#publishing-from-ci).

Add the Hex API Key to [GitHub Encrypted Secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
named `HEX_API_KEY`.

Create a new GitHub Workflow (ex: `.github/workflows/cd.yml`) with the following content:

```yaml
name: cd

on:
  release:
    types: [ published ]

jobs:
  hex-publish:
    uses: straw-hat-team/github-actions-workflows/.github/workflows/elixir-hex-publish.yml@v0.1.1
    with:
      elixir-version: '1.11'
      otp-version: '22.3'
    secrets:
      HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

## Troubleshooting

### Credo

```log
** (Mix) The task "credo" could not be found
```

Verify that `credo` dependency was added correctly.

### Dialyzer

```log
:dialyzer.run error: No such file, directory or application: ".../_build/dev/dialyxir_erlang-..._elixir-..._deps-dev.plt"
```

Verify the Dialyzer configuration follows the guidelines.

```log
** (Mix) The task "dialyzer" could not be found
```

Verify that `dialyzer` dependency was added correctly.
