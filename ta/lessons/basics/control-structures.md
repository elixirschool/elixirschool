---
version: 1.1.0
title: கட்டுப்பாட்டுக் கட்டமைப்புகள்
---

எலிக்சரிலுள்ள கட்டுப்பாட்டுக்க் கட்டமைப்புகள் குறித்து இந்தப்பாடத்தில் கற்றுக்கொள்ளலாம்.

{% include toc.html %}

## `if` மற்றும் `unless`

உங்களுக்கு நிரலாக்கம் பற்றிய அறிமுகமிருந்தால், `if/2` செயற்கூறு உங்களுக்கு ஏற்கனவே நன்கு பரிச்சயமானதாயிருக்கும். மேலும், உங்களுக்கு ரூபி மொழி தெரிந்திருந்தால், `unless/2` செயற்கூறு பற்றியும் அறிந்திருப்பீர்கள்.  எலிக்சரிலும் அவை அப்படியே செயல்படுகின்றன. ஒரேயொரு வேறுபாடு என்னவென்றால், அவை மொழியின் கூறுகளாக இல்லாமல், மாக்ரோக்களாக வரையறுக்கப்பட்டுள்ளன. இவற்றின் வரையறையை [கெர்னல் கூற்றில்](https://hexdocs.pm/elixir/Kernel.html) நீங்கள் காணலாம்.

மேலும், எலிக்சரில், மதிப்பிலி (`nil`) மற்றும் `false` என்ற இரு மதிப்புகள் மற்றுமே பொய்மையைக்குறிக்கின்றன என்பதையும் நினைவிற்கொள்ளவேண்டும்.

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

`unless/2` என்பதின் செயல்பாடும் `if/2`-ஐப்போன்றதேயாகும். ஆனால் அதன் மதிப்பீடு எதிர்மறையானதாக இருக்கவேண்டும்:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

பலபாங்குகளை ஒரேசமயத்தில் பொருத்திப்பார்ப்பதற்கு `case/2` செயல்பாடு பயன்படுகிறது:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

இங்கே `_` என்ற மாறி முக்கியபங்குவகிக்கிறது. அது இல்லையெனில், நிரலின் இயக்கம், எந்தவொரு பாங்கும் பொருந்தாதபட்சத்தில், வழுவில்முடியும்:

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

“மற்றவையனைத்தும்" என்ற பாங்கைப்பொருத்தும் செயல்பாடாக `_` ஐக்கருதலாம்.

`case/2` பாங்குபொருத்துதலை அடிப்படையாகக்கொண்டு இயங்குவதால், அதன் எல்லா விதிகளும் இதற்கும் பொருந்தும். ஏற்கனவே வரையறுக்கப்பட்ட மாறியை `case/2`ல் பயன்படுத்தவேண்டுமெனில், அதை கட்டாயம் தொங்கவிடவேண்டும் (`^/1`):

```elixir
iex> pie = 3.14
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

`case/2`ன் மற்றொரு பயனுள்ள அம்சம் காப்புகள் ஆகும்:

_இந்த எடுத்துக்காட்டு எலிக்சரின் [அதிகாரபூர்வ கையேட்டிலிருந்து](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) எடுக்கப்பட்டது._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

[காப்புகளில் பயன்படுத்தக்கூடிய கோவைகள்](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions) குறித்து மேலும் அறிந்துகொள்ள அதன் அதிகாரபூர்வ ஆவணங்களைப்பார்க்கவும்.

## `cond`

மதிப்புகளுக்குப்பதிலாக, கோவைகளைப்பொருத்திப்பார்க்கவேண்டுமெனில், `cond/1`; ஐப்பயன்படுத்தலாம். இது பிறநிரலாக்கமொழிகளிலுள்ள `else if` அல்லது `elsif` க்கு இணையானதாகும்:

_இந்த எடுத்துக்காட்டு எலிக்சரின் [அதிகாரபூர்வ கையேட்டிலிருந்து](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) எடுக்கப்பட்டது._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

`case/2`ஐப்போலவே, `cond/1` ம் எந்தவொரு கோவையும் பொருந்தாதபோது வழுவைத்தரும். இதைச்சமாளிக்க, இக்கட்டுருவின் இறுதியில் `true` க்கான கோவையைக்கொடுக்கவேண்டும்:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

`with/1` ஒரு சிறப்புக்கட்டுருவாகும். ஒன்றுக்குள் ஒன்றாக பல `case/2` கட்டுருக்களைப்பயன்படுத்தும்போதும், `case/2`க்கான கோவைகளைத்தெளிவாக வரையறுக்கமுடியாமல்போகும்போதும், `with/1`பயன்படுகிறது. `with/1` ன் கோவையானது, திறவுச்சொற்களையும், ஜெனரேட்டர்களையும், இறுதியாக ஒரு கோவையையும் கொண்டது.

[தொகுப்புகளைப்பற்றி முழுமையாகப்படிக்கும்போது](../comprehensions/) ஜெனரேட்டர்கள் குறித்தும் அறிந்துகொள்ளலாம். இப்போதைக்கு, [பாங்குபொருத்துதலைப்பயன்படுத்தி](../pattern-matching/), அவை `<-` இன் இருபுறத்தையும் ஒப்பிடுகின்றன என்பதைமட்டும் அறிந்தால்போதுமானது.

ஓர் எளிய எடுத்துக்காட்டைப்பார்த்துவிட்டு, மேலும் விரிவான எடுத்துக்காட்டுகளைக்காணலாம்:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

ஒருகோவை பொருந்தாமல்போகும்பட்சத்தில், எந்தமதிப்பு பொருந்தவில்லையோ அது திருப்பியனுப்பப்படும்:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

அடுத்து சற்றுவிரிவான எடுத்துக்காட்டைப்பார்க்கலாம். முதலில் `with/1` ஐப்பயன்படுத்தாமல் நிரலெழுதலாம். பின்னர் `with/1`ஐப்பயன்படுத்தி அதை மாற்றியமைக்கலாம்:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)
      error -> error
    end
  error -> error
end
```

`with/1`ஐப்பயன்படுத்தும்போது நிரல் சுருக்கமானதாகவும், புரிந்துகொள்ள எளிமையானதாகவும் உள்ளது:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```


எலிக்சர் 1.3 பதிப்பிலிருந்து, `with/1` உடன் `else`ஐயும் பயன்படுத்தலாம்:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
    true <- Integer.is_even(number) do
      IO.puts "#{number} divided by 2 is #{div(number, 2)}"
      :even
  else
    :error ->
      IO.puts "We don't have this item in map"
      :error
    _ ->
      IO.puts "It is odd"
      :odd
  end
```

`case`ஐப்போல பாங்குபொருத்துதலைப்பயன்படுத்தி, வழுக்களைக்கையாள `else` உதவுகிறது. பொருந்தாமல்போன முதல்மதிப்பு இதற்கு உள்ளீடாக வழங்கப்படுகிறது.
