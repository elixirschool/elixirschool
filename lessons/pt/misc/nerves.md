%{
  version: "1.1.2",
  title: "Nerves",
  excerpt: """

  """
}
---

## Introdução e requisitos

Nós falaremos sobre Nerves nessa lição.
O projeto Nerves é um framework para utilizar Elixir em desenvolvimento de software embarcado.
Como o website do Nerves diz, ele permite que você "construa e faça deploy de software embarcado à prova de balas em Elixir".
Essa lição será um pouco diferente de outras lições da Elixir School.
Nerves é um pouco mais difícil de absorver já que requer a configuração de um sistema avançado e hardware adicional, então pode não ser adequado para iniciantes.

Para escrever código embarcado usando Nerves, você vai precisar de um dos [dispositivos suportados](https://hexdocs.pm/nerves/targets.html), um leitor de cartão com um cartão de memória suportado pelo hardware de sua escolha, e uma conexão a rede cabeada para acessar esse dispositivo pela rede.

De qualquer forma, nós sugerimos usar um Raspberry Pi, já que ele tem um LED controlável onboard.
Também é recomendável ter uma tela conectada ao seu dispositivo alvo já que isso vai simplificar o debug usando IEx.

## Configuração

O projeto Nerves tem um excelente [Guia de introdução](https://hexdocs.pm/nerves/getting-started.html), mas a quantidade de detalhes lá pode ser assustadora para alguns usuários.
Em vez disso, esse tutorial vai tentar apresentar "menos palavras, mais código".

Primeiramente, você vai precisar de um ambiente configurado.
Você pode encontrar o guia na parte de [Instalação](https://hexdocs.pm/nerves/installation.html) da wiki do Nerves.
Por favor, tenha certeza de que você tem a mesma versão tanto do OTP quanto do Elixir mencionadas no guia.
Não utilizar a versão correta pode causar problemas conforme você progride.
No momento em que esse guia foi escrito, qualquer versão de Elixir (compilada com Erlang/OTP 21) deve funcionar.

Depois de configurar, você deve conseguir construir seu primeiro projeto Nerves!

Nosso objetivo será chegar ao "Hello world" do desenvolvimento embarcado: um LED piscando controlado por uma API HTTP simples.

## Criando um projeto

Para gerar um novo projeto, execute `mix nerves.new network_led` e responda `Y` à pergunta sobre obter e instalar as dependências.

Você deve ver a seguinte saída:

```
Your Nerves project was created successfully.

You should now pick a target. See https://hexdocs.pm/nerves/targets.html#content
for supported targets. If your target is on the list, set `MIX_TARGET`
to its tag name:

For example, for the Raspberry Pi 3 you can either
  $ export MIX_TARGET=rpi3
Or prefix `mix` commands like the following:
  $ MIX_TARGET=rpi3 mix firmware

If you will be using a custom system, update the `mix.exs`
dependencies to point to desired system's package.

Now download the dependencies and build a firmware archive:
  $ cd network_led
  $ mix deps.get
  $ mix firmware

If your target boots up using an SDCard (like the Raspberry Pi 3),
then insert an SDCard into a reader on your computer and run:
  $ mix firmware.burn

Plug the SDCard into the target and power it up. See target documentation
above for more information and other targets.
```

Nosso projeto foi gerado e está pronto para ser transferido para nosso dispositivo de teste!
Vamos tentar agora!

No caso de um Raspberry Pi 3, você define `MIX_TARGET=rpi3`, mas você pode mudar isso para se adequar ao hardware que você tem dependendo do hardware alvo (veja a lista na [documentação do Nerves](https://hexdocs.pm/nerves/targets.html#content)).

Vamos configurar nossas dependências primeiro:

```shell
$ export MIX_TARGET=rpi3
$ cd network_led
$ mix deps.get

....

Nerves environment
  MIX_TARGET:   rpi3
  MIX_ENV:      dev
Resolving Nerves artifacts...
  Resolving nerves_system_rpi3
  => Trying https://github.com/nerves-project/nerves_system_rpi3/releases/download/v1.12.2/nerves_system_rpi3-portable-1.12.2-E904717.tar.gz
|==================================================| 100% (142 / 142) MB
  => Success
  Resolving nerves_toolchain_arm_unknown_linux_gnueabihf
  => Trying https://github.com/nerves-project/toolchains/releases/download/v1.3.2/nerves_toolchain_arm_unknown_linux_gnueabihf-darwin_x86_64-1.3.2-E31F29C.tar.xz
|==================================================| 100% (55 / 55) MB
  => Success
```

Nota: certifique-se de ter configurado a variável de ambiente que especifica a plataforma alvo antes de executar `mix deps.get`, pois esse comando irá baixar as imagens apropriadas e ferramentas para a plataforma especificada.

## Gravando o firmware

Agora nós podemos continuar a transferir o drive.
Coloque o cartão no leitor, e se você configurou tudo corretamente nas etapas anteriores, depois de rodar `mix firmware.burn` e confirmar o dispositivo que está usando você deveria receber essa pergunta:

```
Building ......../network_led/_build/rpi_dev/nerves/images/network_led.fw...
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
```

Se você tiver certeza que esse é o cartão no qual você quer gravar - escolha `Y` e depois de algum tempo o cartão de memória estará pronto:

```
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
|====================================| 100% (32.51 / 32.51) MB
Success!
Elapsed time: 8.022 s
```

Agora é o momento de colocar o cartão de memória em seu dispositivo e verificar se funciona.

Se você tiver uma tela conectada - você deve ver uma sequência de boot Linux nela depois de ligar o dispositivo com esse cartão de memória inserido.

## Configurando a rede

A próxima etapa é configurar a rede.
O ecossistema Nerves provê uma variedade de pacotes, e [vintage_net](https://github.com/nerves-networking/vintage_net) é o que precisaremos para conectar o dispositivo à rede através da porta cabeada Ethernet.

Esse pacote já está presente em seu projeto como uma dependência de [`nerves_pack`](https://github.com/nerves-project/nerves_pack).
No entanto, por padrão, ele usa DHCP (veja a configuração para ele em `config/targets.exs` depois de rodar `config :vintage_net`).
É mais fácil ter um endereço IP estático.

Para configurar uma rede estática na porta cabeada Ethernet, você deve atualizar a configuração do `:vintage_net` no `config/config.exs` da seguinte maneira:

```elixir
# Statically assign an address
config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{
         method: :static,
         address: "192.168.88.2",
         prefix_length: 24,
         gateway: "192.168.88.1",
         name_servers: ["8.8.8.8", "8.8.4.4"]
       }
     }},
    {"wlan0", %{type: VintageNetWiFi}}
  ]
```

Por favor note que essa configuração atualiza somente a rede cabeada Ethernet.
Se você quiser usar rede sem fio - dê uma olhada no [VintageNet Cookbook](https://hexdocs.pm/vintage_net/cookbook.html#wifi).

Note que você precisa usar seus parâmetros de rede local aqui - em minha rede há um IP desalocado `192.168.88.2`, que eu irei usar.
No entanto, em seu caso, pode ser diferente.

Depois de mudar isso, nós vamos precisar gravar a versão modificada do firmware através de `mix firmware.burn`, e depois iniciar o dispositivo com o novo cartão.

Quando você ligar o dispositivo, você pode usar `ping` para vê-lo ficar online.

```
Request timeout for icmp_seq 206
Request timeout for icmp_seq 207
64 bytes from 192.168.88.2: icmp_seq=208 ttl=64 time=2.247 ms
64 bytes from 192.168.88.2: icmp_seq=209 ttl=64 time=2.658 ms
```

Essa saída significa que o dispositivo agora pode ser alcançado através da rede.

## Gravação de firmware de rede

Até então, nós temos gravado cartões SD e inserido-os fisicamente em nosso hardware.
Enquanto isso é um ótimo começo, é mais direto enviar nossas atualizações pela rede.
O pacote [`ssh_subsystem_fwup`](https://github.com/nerves-project/ssh_subsystem_fwup) faz exatamente isso.
Ele já está presente em seu projeto por padrão e é configurado para auto-detectar e encontrar chaves SSH em seu diretório `~/.ssh`.

Para usar a funcionalidade de atualização de firmware por rede, você vai precisar gerar um script de upload com `mix firmware.gen.script`.
Esse comando vai gerar um novo script `upload.sh` que podemos rodar para atualizar o firmware.

Se a rede estiver funcional depois da etapa anterior, você pode prosseguir.

Para atualizar suas configurações, a melhor forma é usar `mix firmware && ./upload.sh 192.168.88.2`: o primeiro comando cria o firmware atualizado, e o segundo o envia pela rede e atualiza o dispositivo.
Você pode finalmente parar de tirar e colocar cartões SD no dispositivo!

_Dica: `ssh 192.168.88.2` te dá um shell IEx no dispositivo no contexto da aplicação._

_Solução de Problemas: Se você não tiver uma chave ssh existente em sua pasta home, você vai receber um erro `No SSH public keys Found in ~/.ssh.`.
Nesse caso, você vai precisar rodar `ssh-keygen` e re-gravar o firmware para usar o recurso de atualização por rede._

## Configurando o controle do LED

Para interagir com LEDs, você vai precisar do pacote [nerves_leds](https://github.com/nerves-project/nerves_leds) instalado, o que é feito adicionando `{:nerves_leds, "~> 0.8", targets: @all_targets},` no arquivo `mix.exs`.

Depois de instalar a dependência, você precisa configurar a lista de LED para o dispositivo.
Por exemplo, para todos modelos de Raspberry Pi, existe apenas um LED onboard: `led0`.
Vamos usá-lo adicionando uma linha `config :nerves_leds, names: [green: "led0"]` ao arquivo `config/config.exs`.

Para outros dispositivos, você pode dar uma olhada na [parte correspondente do projeto nerves_example](https://github.com/nerves-project/nerves_examples/tree/main/hello_leds/config).

Depois de configurar o LED em si, nós certamente precisamos controlá-lo de alguma forma.
Para fazer isso, nós adicionaremos um GenServer (veja detalhes sobre GenServers na lição [Concorrência OTP](../../advanced/otp-concurrency.md)) em `lib/network_led/blinker.ex` com esse conteúdo:

```elixir
defmodule NetworkLed.Blinker do
  use GenServer

  @moduledoc """
    Simple GenServer to control GPIO #18.
  """

  require Logger
  alias Nerves.Leds

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    enable()

    {:ok, state}
  end

  def handle_cast(:enable, state) do
    Logger.info("Enabling LED")
    Leds.set(green: true)

    {:noreply, state}
  end

  def handle_cast(:disable, state) do
    Logger.info("Disabling LED")
    Leds.set(green: false)

    {:noreply, state}
  end

  def enable() do
    GenServer.cast(__MODULE__, :enable)
  end

  def disable() do
    GenServer.cast(__MODULE__, :disable)
  end
end

```

Para habilitar isso, você também precisa adicioná-lo à árvore de supervisão em `lib/network_led/application.ex`: adicione `{NetworkLed.Blinker, name: NetworkLed.Blinker}` sob o grupo `def children(_target) do`.

Note que o Nerves tem duas diferentes árvores de supervisão na aplicação - uma para a máquina hospedeira e uma para os dispositivos de fato.

Depois disso, é só fazer upload do firmware e, ao rodar o IEx através de ssh no dispositivo alvo, checar que `NetworkLed.Blinker.disable()` desliga o LED (que é habilitado por padrão no código), e `NetworkLed.Blinker.enable()` liga.

Nós temos controle do LED através do prompt de comando!

Agora a única peça faltando no quebra-cabeça é controlar o LED através da interface web.

## Adicionando o servidor web

Nessa etapa, nós vamos usar `Plug.Router`.
Se você precisar de um lembrete - sinta-se livre para passar o olho na lição sobre [Plug](../../../lessons/specifics/plug/).

Primeiro, nós vamos adicionar `{:plug_cowboy, "~> 2.0"}` no arquivo `mix.exs` e instalar as dependências.

Então, adicione a lógica para processar essas requisições em `lib/network_led/http.ex`:

```elixir
defmodule NetworkLed.Http do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Feel free to use API endpoints!"))

  get "/enable" do
    NetworkLed.Blinker.enable()
    send_resp(conn, 200, "LED enabled")
  end

  get "/disable" do
    NetworkLed.Blinker.disable()
    send_resp(conn, 200, "LED disabled")
  end

  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

E, a etapa final - adicione `{Plug.Cowboy, scheme: :http, plug: NetworkLed.Http, options: [port: 80]}` para a árvore de supervisão da aplicação.

Depois da atualização do firmware, você pode testá-lo! `http://192.168.88.2/` está retornando uma resposta em texto puro, e `http://192.168.88.2/enable` junto a `http://192.168.88.2/disable` ativam e desativam, respectivamente, o LED!

Você pode até mesmo empacotar interfaces de usuário feitas com Phoenix na sua aplicação Nerves, no entanto, isso vai [precisar de algumas alterações](https://github.com/nerves-project/nerves/blob/master/docs/User%20Interfaces.md#phoenix-web-interfaces).
