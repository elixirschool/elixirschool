%{
version: "1.3.0",
title: "مقدمات",
excerpt: """
آغاز، انواع داده‌ و عملیات اصلی.
"""
}
---

## آغاز

### نصب الکسیر

دستور نصب برای هر سیستم‌های عامل مختلف در سایت elixir-lang.org در صفحه‌ی [نصب الکسیر](http://elixir-lang.org/install.html) در دسترس است.

پس از نصب الکسیر، به سادگی می‌توانید بفهمید چه نسخه‌ای نصب شده است.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### آزمودن حالت تعاملی

به همراه الکسیر یک پوسته‌ی تعاملی به نام IEx نصب می‌شود که امکان ارزیابی عبارات الکسیر را فراهم می‌کند.

برای شروع دستور `iex` را اجرا کنید:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

نکته: در پاورشل ویندوز باید `iex.bat` را تایپ کنید.

خب، بیایید چند عبارت ساده‌ی الکسیر را آزمایش کنیم:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

نگران نباشید اگر هنوز همه‌ی عبارات را متوجه نمی‌شوید، اما امیدواریم متوجه مفهوم کلی بشوید.

## انواع داده‌ی پایه

### اعداد صحیح

```elixir
iex> 255
255
```

اعداد دودویی، هشت‌هشتی، و شانزده‌شانزدهی پشتیبانی می‌شوند:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### اعداد ممیز شناور

در الکسیر، اعداد ممیز شناور (اعشاری) باید حداقل یک رقم پیش از نقطه و یک رقم پس از نقطه داشته باشند. این اعداد ۶۴ بیتی هستند با دقت مضاعف و از نشانه‌ی `e` برای مقادیر توان پشتیبانی می‌کنند.

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### بولی

الکسیر از مقادیر بولی `true` و `false` پشتیبانی می‌کند؛ همه چیز درست در نظر گرفته می‌شود به جز `false` و `nil`.

```elixir
iex> true
true
iex> false
false
```

### اتم‌ها

اتم ثابتی است که نام آن همان مقدار آن است.
اگر با زبان روبی آشنا هستید، اینها معادل سمبل‌ها در روبی هستند.

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

مقادیر بولی `true` و `false` به ترتیب همان اتم‌های `:true` و `:false` هستند.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

نام ماژول‌ها هم در الکسیر اتم است. `MyApp.MyModule` یک اتم مجاز است، حتی اگر هنوز چنین ماژولی تعریف نشده باشد.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

اتم‌ها برای ارجاع به ماژول‌های کتابخانه‌های زبان برنامه‌نویسی ارلنگ هم به کار می‌روند، از جمله کتابخانه‌های درونی.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### رشته‌ها

در الکسیر رشته‌ها به صورت UTF-8 کدگذاری می‌شوند و میان علامت نقل قول دوتایی قرار می‌گیرند:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

رشته‌ها می‌توانند شکسته شوند و از دنباله‌های گریز هم پشتیبانی می‌کنند:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

الکسیر انواع داده‌ی پیچیده‌تری هم دارد.
پس از فراگیری [مجموعه‌ها](/en/lessons/basics/collections) و [توابع](/en/lessons/basics/functions) بیشتر درباره‌ی آنها خواهیم دانست.

## عملیات اصلی

### حسابی

الکسیر مطابق انتظار عملگرهای اصلی `+`، `-`، `*`، و `/` را پشتیبانی می‌کند.
توجه داشته باشید که `/` همواره عدد ممیز شناور برمی‌گرداند:

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

اگر به تقسیم عدد صحیح یا باقیمانده (پیمانه) نیاز داشتید، الکسیر دو تابع بسیار مفید برای این کار دارد:

```elixir
iex> div(10, 3)
3
iex> rem(10, 3)
1
```

### بولی

الکسیر عملگرهای بولی `||`، `&&`، و `!` را پشتیبانی می‌کند.
اینها از همه‌ی انواع داده پشتیبانی می‌کنند:

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

سه عملگر دیگر هم هستند که عملوند نخست آنها باید بولی (`true` یا `false`) باشد:

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

نکته: عملگرهای `and` و `or` الکسیر در حقیقت به `andalso` و `orelse` در ارلنگ نگاشت می‌شوند.

### مقایسه‌‌ای

الکسیر همه‌ی عملگرهای مقایسه‌ای که با آنها آشنا هستیم را دارد: `==`، `!=`، `===`، `!==`، `<=`، `>=`، `<`، و `>`.

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

برای مقایسه‌ی دقیق و سخت‌گیرانه‌ی اعداد صحیح و ممیز شناور از `===` استفاده کنید:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

یک ویژگی مهم الکسیر این است که هر دو نوع داده‌ای می‌توانند مقایسه شوند؛ این به ویژه هنگام مرتب‌سازی مفید است. لازم نیست ترتیب مرتب‌سازی را به خاطر بسپاریم، اما مهم است از آن آگاه باشیم:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

این ممکن است منجر به مقایسه‌های جالب و البته معتبری شود که شاید در زبان‌های دیگر یافت نشوند:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### درج رشته

اگر از روبی استفاده کرده باشید، درج رشته در الکسیر آشنا خواهد بود:

```elixir
iex> name = "Sean"
"Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### پیوند رشته

برای پیوند رشته از عملگر `<>` استفاده می‌شود:

```elixir
iex> name = "Sean"
"Sean"
iex> "Hello " <> name
"Hello Sean"
```
