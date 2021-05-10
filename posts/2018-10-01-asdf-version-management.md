%{
  author: "Bobby Grayson",
  author_link: "https://github.com/notactuallypagemcconnell",
  date: ~D[2018-10-01],
  tags: ["general"],
  title: "Agnostic Version Management With asdf",
  excerpt: """
  Take a dive into flexible version management of Elixir, Erlang, and OTP with `asdf`!
  """
}

---

## What is it?
Oftentimes we need to use multiple versions of our tools.
Many communities have their own things to do this.
In Ruby we have `chruby`, `rbenv`, `rvm` and more, NodeJS has `nvm`.
These tools allow us to easily and quickly switch what we are using for a given project or environment.

Today were going to talk about my favorite version manager of choice, `asdf`, because it lets you manage multiple languages with just one tool because it is agnostic as to what you manage the version of with it.
There is one big win that I see with `asdf` that no other tool has allowed me to do as easily: control which version of OTP my Elixir was compiled with, and manage that and several versions of Elixir + OTP together.
Let's check it out!

## Setup
Installing `asdf` is a breeze.

First, clone it down:

```shell
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.5.1
```

Now its time for setup.

On macOS:

```shell
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bash_profile
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bash_profile
```

On linux (with a standard bash shell):

```shell
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
```

With ZSH:

```shell
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.zshrc
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.zshrc
```

With Fish:

```shell
echo 'source ~/.asdf/asdf.fish' >> ~/.config/fish/config.fish
mkdir -p ~/.config/fish/completions; and cp ~/.asdf/completions/asdf.fish ~/.config/fish/completions
```
Now restart your shell, and type `asdf` and we get our first introduction to the tool.

```shell
asdf

MANAGE PLUGINS
  asdf plugin-add <name> [<git-url>]   Add a plugin from the plugin repo OR, add a Git repo
                                       as a plugin by specifying the name and repo url
  asdf plugin-list                     List installed plugins
  [...]

MANAGE PACKAGES
  asdf install <name> <version>        Install a specific version of a package or,
                                       with no arguments, install all the package
                                       versions listed in the .tool-versions file
  asdf uninstall <name> <version>      Remove a specific version of a package
  asdf current                         Display current version set or being used for all packages
  asdf current <name>                  Display current version set or being used for package
  [...]

UTILS
  asdf reshim <name> <version>         Recreate shims for version of a package
  asdf update                          Update asdf to the latest stable release
  asdf update --head                   Update asdf to the latest on the master branch
```

## Using it with Elixir
To get `asdf` working with Elixir, we first will need Erlang.
Depending on our system, there are some simple steps:

On OSX:

```shell
brew install autoconf wxmac
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf install erlang 21.1
```

On Ubuntu

```shell
apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-dev libgl1-mesa-dev libglu1-mesa-dev libpng3 libssh-dev
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf install erlang 21.1
```

For the Erlang bits, we can use any ref from git or also pass a major OTP version.
`asdf install erlang ref:master` would get us the latest master version from git.
Since we can do this with Elixir, too, you can imagine how easy it makes building from a specific branch or version for debugging contributions to Elixir itself that may involve multiple versions!

Now, let’s get Elixir set up.
It will be the same on all systems since we got our plumbing done with Erlang.

```shell
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf install elixir 1.7
```

Now, what if we happened to know we needed it compiled on OTP 20 and not OTP 21, and to run in that environment?

```shell
asdf install erlang 20.3
asdf install elixir 1.7-otp-20
```

Now, we can set up what version we want to use in a given project (local environment, per directory) like so:

```shell
asdf local erlang 20.3
asdf local elixir 1.7.0-otp-20
```

Or alternatively, we can set global configs (our entire system), too:

```shell
asdf global erlang 20.3
asdf global elixir 1.7.0-otp-20
```

To learn more about how asdf manages these things under the hood and further customize, check out [their docs](https://github.com/asdf-vm/asdf#the-tool-versions-file).

As you can see, this makes it quite seamless to be able to switch around a toolset that is somewhat complicated underneath the service.
I find `asdf` to be a great tool for managing this piece of my complexity in my day to day life.
Happy hacking!

