%{
  version: "1.0.0",
  title: "செயற்கூறுகள்",
  excerpt: """
  எலிக்சரிலும், மேலும்பல செயல்பாட்டு நிரலாக்கமொழிகளிலும், செயற்கூறுகள் முதல்தரகுடிமக்களாக உள்ளன. எலிக்சரிலுள்ள செயற்கூறுகளின் வகைகளைப்பற்றியும், அவற்றுக்குள் உள்ள வேறுபாடுகளைப்பற்றியும், அவற்றை எப்போது எப்படி பயன்படுத்தவேண்டும் என்றும் இப்பாடத்தில் கற்றுக்கொள்ளலாம்.
  """
}
---

## பெயரில்லா செயற்கூறுகள்

பெயரோடு இணைக்கப்படாத, பெயர் அறிவிக்கப்படாத செயற்கூறுகளுக்கு பெயரில்லா செயற்கூறுகள் என்று பெயர். நாம் `கணங்கள்` பாடத்தில் படித்ததுபோல, இவ்வகை செயற்கூறுகள் பிற செயற்கூறுகளுக்கு உள்ளீட்டு உருபுகளாக அனுப்பபடுகின்றன. ஒரு பெயரில்லா செயற்கூற்றை வரையறுக்க, `fn`, `end` என்ற இரு திறவுச்சொற்கள் தேவைப்படுகின்றன. இவற்றுக்கிடையே, ஒன்றுக்குமேற்பட்ட உள்ளீட்டு உருபுகளையும், செயற்கூற்றின் அமைப்புகளையும் வரையறுக்கலாம். ஒவ்வொரு செயற்கூறமைப்புக்கும், அவற்றுக்கான உருபுகளுக்கும் இடையே `->` குறியீடு கொடுக்கப்படவேண்டும்.

ஓர் எளிய எடுத்துக்காட்டு:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### & எனும் சுருக்கெழுத்து

பெயரில்லா செயற்கூறுகள் மிகப்பரவலாக எலிக்சரில் பயன்படுத்தப்படுவதால், அதற்கென தனியாக ஒரு சுருக்கெழுத்து வழங்கப்பட்டுள்ளது:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

சுருக்கெழுத்தைப்பயன்படுத்தி செயற்கூற்றை வரையறுக்கும்போது, அதன் உருபுகளை `&1`, `&2`, `&3`, முதலிய சுருக்கெழுத்துக்களைகொண்டு அணுகலாம்.

## பாங்குபொருத்துதல்

எலிக்சரில், பாங்குபொருத்துதல் என்பது வெறும் மதிப்புகளுக்கு மட்டுமானதல்ல. இதனை செயற்கூறுகளின் கையொப்பங்களைப்பொருத்திப்பார்க்கவும் பயன்படுத்தலாம். இப்பகுதியில் அதைப்பற்றி அறிந்துகொள்ளலாம்.

செயற்கூற்றில் கொடுக்கப்பட்டுள்ள, உள்ளீட்டு உருபுகளின் கணத்தில், முதலில் பொருந்தும் உருபுகளுக்குரிய செயற்கூரமைப்பை இயக்குகிறது:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## பெயருள்ள செயற்கூறுகள்

செயற்கூறுகளுக்கு பெயரிடுவதன்முலம், அவற்றை தேவைப்படும்போது அப்பெயர்கொண்டு அழைத்துக்கொள்ளலாம். ஒரு கூறுக்குள் `def` என்ற திறவுச்சொல்லைக்கொண்டு பெயருள்ள செயற்கூறுகளை வரையறுக்கலாம். கூறுகளைப்பற்றி அடுத்தபாடத்தில் கற்றுக்கொள்ளலாம். தற்சமயம் செயற்கூறுகளில்மட்டும் கவனம்செலுத்தலாம்.

ஒரு கூறுக்குள் வரையறுக்கப்பட்ட செயற்கூறுகள் பிறகூறுகளுக்கும் அணுக்கமாகவுள்ளன. எலிக்சரின் மிகவும் பயனுள்ள கட்டமைப்புகளில் இதுவும் ஒன்று:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

ஒரேயொருவரிக்குள் அடங்கக்கூடிய அமைப்புகொண்ட செயற்கூறுகளை வரையறுக்க `do:` என்ற திறவுச்சொல்லைப்பயன்படுத்தலாம்:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

பெயருள்ள செயற்கூறுகளையும், பாங்குபொருத்துதலையும் துணைக்கொண்டு, ஒரு செயற்கூற்றின் அமைப்பிலிருந்தே அதை மீண்டும் அழைக்கமுயலலாம்:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### செயற்கூறுகளின் பெயரும் உருபும்

முந்தையபாடங்களில், செயற்கூறுகளைக்குறிப்பிடும்போது அவற்றின் பெயரையும், உருபுகலின் எண்ணிக்கையையும் சேர்த்து குறிப்பிடவேண்டுமென்று அறிந்தோம். எனவே, வெவ்வேறு உருபெண்களைக்கொண்ட செயற்கூறுகளை பின்வருமாறு வரையறுக்கமுடியும்:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

மேலேயுள்ள நிரலில், செயற்கூறுகளின் பெயரை, குறிப்புரைக்குள் கொடுத்திருக்கிறோம். முதலாவது செயற்கூறுக்கு உள்ளீட்டு உருபுகள் எதுவும் கொடுக்கப்படவில்லை. எனவே அதனை `hello/0` என அழைக்கிறோம். இரண்டாவது செயற்கூறு ஒரேயொரு உருபினை உள்ளீடாக எடுத்துக்கொள்வதால், அதனை `hello/1` என அழைக்கிறோம். அதைப்போலவே, மூன்றாவது செயற்கூறு `hello/2` என அழைக்கப்படுகிறது. பிறமொழிகளிலுள்ள பணிமிகுப்புசெயற்கூறுகளைப் போல இல்லாமல், இவையொவ்வொன்றும், _தனித்தனி செயற்கூறுகளாகவே_ கருதப்படுகின்றன. (_ஒரே எண்ணிக்கையிலான_ உள்ளீட்டு உருபுகளையும், ஒரே பெயரையும்கொண்ட செயற்கூறுகளை வித்தியாசம்காணமட்டுமே மேற்குறிப்பிட்ட, பாங்குபொருத்துதல் பயன்படுகிறது.)

### தனிப்பட்ட செயற்கூறுகள்

பிறகூறுகளிலிருந்து ஒருசெயற்கூறினை அணுகமுடியாமல் தடுக்க, அதனை தனிப்பட்ட செயற்கூறாக வரையறுக்கவேண்டும். தனிப்பட்ட செயற்கூறுகளை அவற்றை வரையறுத்துள்ள கூறிலிருந்துமட்டுமே அணுகமுடியும். எலிக்சரில் `defp` என்ற திறவுச்சொல்லைக்கொண்டு இவற்றை வரையறுக்கலாம்:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### காப்புகள்

[கட்டுப்பாட்டுக்கட்டமைப்புகள்](../control-structures) பாடத்தில், காப்புகள் குறித்து சுருக்கமக படித்தோம். இப்போது, பெயருள்ள செயற்கூறுகளுக்கு அதை எவ்வாறு பயன்படுத்துவதென்று பார்க்கலாம். ஒரு செயற்கூற்றைப்பொருத்தியவுடன், அதன் காப்புகளை, எலிக்சர், சோதிக்கும்.

கீழேயுள்ள எடுத்துக்காட்டில் ஒரே கையொப்பம்கொண்ட இரு செயற்கூறுகள் உள்ளன. அதன் உருபுகளின் வகையை வைத்து எந்த செயற்கூற்றை இயக்கவேண்டும் என்பதைக்கண்டறிய காப்புகளைச் சார்ந்திருக்கிறோம்:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### இயல்புநிலை உருபுகள்

ஒரு உள்ளீட்டு உருபுக்கு இயல்புநிலைமதிப்பு வழங்கவேண்டுமெனில், `argument \\ value` என்ற தொடரைப்பயன்படுத்தவேண்டும்:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

காப்புகளையும், உருபுகளின் இயல்புநிலை மதிப்புகளையும் சேர்த்து பயன்படுத்தும்போது நாம் சிக்கலில் மாட்டிக்கொள்ள வாய்ப்பிருக்கிறது. ஒரு எடுத்துக்காட்டை பார்க்கலாம்:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

ஒரேகையொப்பம்கொண்ட செயற்கூறுகளில் இயல்புநிலை மதிப்புகளைப்பயன்படுத்துவது, எலிக்சரில் விரும்பத்தக்கதல்ல. இதைக்கையாள ஒரு முதன்மைச்செயற்கூற்றை இயல்புநிலை மதிப்புகளுடன் வரையறுக்கலாம்:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")
  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
