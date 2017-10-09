---
version: 1.0.0
title: الأساسيات
---

البدء، أنواع بيانات أساسية وعمليات أساسية.

{% include toc.html %}

## البداء

تثبيت إليكسير

يمكن إيجاد تعليمات التثبيت لكل نظام التشغيل على موقع elixir-lang.org في دليل [تثبيت إليكسير](http://elixir-lang.org/install.html).

بعد تثبيت إليكسير تستطيع أن تتأكد من النسخة المثبتة.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### تجريب النمط التفاعلي

تضم إليكسير `iex`, محارة تفاعلية، الذي يسمح لنا بتقييم تعبيرات إليكسير بينما نمضي.

دعنا نبدأ بتنفيذ `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex(1)>

دعنا نحاول كتابة بعض التعبيرات بسيطة:

    iex(1)> 2+3
    5
    iex(2)> 2+3 == 5
    true
    iex(3)> String.length("The quick brown fox jumps over the lazy dog")
    43

لا تقلق إذا لم تفهم كل التعبيرات حتى الآن، نأمل أن فهمت الفكرة.


## أنواع البيانات الأساسية

### الأعداد الصحيحة

```elixir
iex> 255
255
iex> 0xFF
255
```

هناك دعم مدمج لنظام العد الثنائي والثماني والسداسي عشر:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### الأعداد الفاصلة العائمة

في إليكسير، الأعداد الفاصلة العائمة تحتاج لنقطة عشرية بعد رقم واحد على الأقل، عندهم دقة مزدوجة 64 بت، وتدعم كتابة `e` قبل الأس:

```elixir
iex> 3.41
3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### القيم المنطقية

تدعم إليكسير قيم `true` (صواب) و `false` (خطأ) كقيم منطقية، وتعتبر كل القيم كصواب باستثناء `false` و `nil`:

```elixir
iex> true
true
iex> false
false
```

### الذرات

الذرة تعتبر ثابتاً اسمه يساوى قيمته. إذا كنت على معرفة بلغة برمجة روبي، الذرة هي مرادفة مع السمبولس:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

ملاحظة: قيم منطقية `true` و `false` تعتبر ذرات `:true` و `:false` على التوالي.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### السلاسل

السلاسل في أليكسير تُشغّل مع ترميز الحروف UTF-8 وبشكل ملفوف بين اقتباس مزدوجة:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

تدعم السلاسل فصالات سطري وتسلسلات الهروب:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

تضم أليكسير أيضا أنواع بيانات معقدة أكثر. سوف نعلم أكثر عنها أثناء الدرس عن المجموعات والدالات.

## العمليات الأساسية

### حسابي

تدعم أليكسير العمليات الحسابية الأساسية  `+`, `-`, `*`, و `/` كما تتوقع. من المهم أن تلاحظ أن `/` دائما سيعيد عدد فاصل عائم:

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

إذا احتجت لقسمة عدد صحيح أم لعدد متبقي من القسمة ،عند إليكسير دالتان مفيدان لتحقيق هذا:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### القيم المنطقية

توفّر إليكسير رموز `||`, `&&`, and `!` لعمليات حسابية، وهي تدعم أي نوع:

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

هناك ثلاث عمليات إضافية، و _لا بد_ أن يكون المعطى الأول قيمة منطقية (`true` و `false`):

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

### المقارنة

عند إليكسير كل عمليات المقارنة نحن متعودون عليها: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` و `>`.

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

لمقارنة صارمة بين أعداد صحيحة وأعداد فاصل عائم، استخدم `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

سمة هامة إليكسير هي أن يمكن مقارنة أي توعين، وهذا مفيد بصفة خاصة للتصنيف. لا نحتاج أن نحفظ ترتيب التصنيف، بل من المهم أن نكون مدرك له:

```elixir
number < atom < reference < functions < port < pid < tuple < maps < list < bitstring
```

يمكن أن يؤدي هذا لمقارنات مثيرة للاهتمام، ولكن صحيحة، التي لا تستطيع أن تجدها في لغات برمجة أخرى:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### استيفاء السلسلة

إذا استخدمت روبي، استيفاء السلسلة في إليكسير سيبدو مألوفاً:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### إلحاق السلسلة

استخدم `<>` لعملية إلحاق السلسلة:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
