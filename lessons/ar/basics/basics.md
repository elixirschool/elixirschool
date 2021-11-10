%{
  version: "1.1.2",
  title: "الأساسيات",
  excerpt: """
  مقدمة، أنواع البيانات والعمليات الأساسية.
  """
}
---

## البدء

### تثبيت إليكسير

يمكن إيجاد تعليمات التثبيت لكل نظم التشغيل على موقع elixir-lang.org في دليل [تثبيت إليكسير](http://elixir-lang.org/install.html).

بعد تثبيت إليكسير تستطيع أن تتأكد من النسخة المثبتة.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### تشغيل نمط موجة الأوامر التفاعلي

تضم إليكسير الأمر `iex` والذي يمكنك من تشغيل اللغة في الوضع التفاعلي وتنفيذ بعض جُمَل الأوامر

دعنا نبدأ بتنفيذ الأمر `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

دعنا نحاول كتابة بعض الجُمَل (التعبيرات) البسيطة:
```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

لا تقلق إذا لم تفهم كل التعبيرات حتى الآن، نأمل أن تصلك فكرة عامة عن اللغة وتعبيراتها.


## أنواع البيانات الأساسية

### الأعداد الصحيحة

```elixir
iex> 255
255
```

هناك دعم مدمج لنظام العد الثنائي والثماني والست عشري:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### الأعداد العشرية

في إليكسير، يجب كتابة خانة واحدة على الأقل قبل الفاصلة لتمثيل عدد عشري كما يوجد دعم للأس بستخدام `e`.

```elixir
iex> 3.41
3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### القيم المنطقية

تدعم إليكسير القِيَم المنطقية `true` و `false` وجميع القيم تعبّر عن الصحة ما عدا `false` و `nil`.

```elixir
iex> true
true
iex> false
false
```

### الذرات

الذرة تعتبر ثابتاً اسمه يساوى قيمته. إذا كنت على معرفة بلغة برمجة روبي، الذرة هي مرادفة الرموز (Symbols):

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

ملاحظة: القيم المنطقية `true` و `false` تعتبر ذرات `:true` و `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

اسماء الوحدات في إليكسير هي عبارة عن ذرات. `MyApp.MyModule` هو ذرة, حتى ولو لم يتم تعريف هذه الوحدة.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

الذرات ايضاً مستخدمة لتكون مرجع وحدات من مكتبات لغة البرمجة إرلانج.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### السلاسل النصية

القيم النصية في إليكسير هي أحرف بترميز UTF-8 محاطة بعلامتي تنصيص مزدوجة.

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

يمكن للقيم النصية أن تُكْتَب مقسمة على أكثر من سطر:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

تضم أليكسير أيضا أنواع بيانات معقدة أكثر. سوف نتعلّم أكثر عنها أثناء الدرس عن المجموعات والدوالّ.

## العمليات الأساسية

### الحساب

تدعم أليكسير العمليات الحسابية الأساسية  `+`, `-`, `*`, و `/` كما تتوقع. من المهم أن تلاحظ أن `/` دائما سيعيد عدد عشري:

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

في إليكسير، يمكنك الحصول على ناتج القسمة بدون باقٍ أو الحصول على باقي القسمة فقط عن طريق الدوالّ التالية:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### المنطق

توفّر إليكسير رموز `||`, `&&`, و `!` لعمليات حسابية، وهي تدعم أي نوع:

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

هناك ثلاث أوامر أخرى أيضا للتعامل مع القيم المنطقية مع العلم انه يجب ان يكون المعامل الاول قيمة منطقية (`true` or `false`):

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

عند إليكسير كل عمليات المقارنة المعتادة: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` و `>`.

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

لمقارنة صارمة بين أعداد صحيحة وأعداد عشرية، استخدم `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

من الخصائص المهمة في إليكسير إمكانية المقارنة بين قيمتين من نفس النوع، تأتي أهمية ذلك عند ترتيب القِيَم. ليس من الضروري أن تحفظ هذا الترتيب ولكن من باب العلم بالشيء.

```elixir
number < atom < reference < functions < port < pid < tuple < maps < list < bitstring
```

يمكن أن يؤدي هذا لمقارنات مثيرة للاهتمام، ولكنها صحيحة تماماً، ولا تستطيع أن تجدها في لغات برمجة أخرى:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### القيم النصية الممزوجة

إذا كنت من مستخدمي روبي، مزج القيم النصية في إليكسير سيبدو مألوفاً:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### الدمج بين القِيَم النصية

استخدم `<>` لعملية المزج بين القيم النصية:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
