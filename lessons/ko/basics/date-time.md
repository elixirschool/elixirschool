%{
  version: "1.1.1",
  title: "날짜와 시간",
  excerpt: """
  Elixir에서 시간을 다루어 봅시다.
  """
}
---

## Time

Elixir에는 시간을 다루기 위한 모듈이 있습니다.
현재 시각을 구하는 것부터 시작해보죠.

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

'Time' 구조체를 만드는 데 시길을 사용할 수도 있습니다.

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

시길에 대한 더 자세한 내용은 [시길 강의](../sigils)에서 보실 수 있습니다.
이 구조체의 부분에 손쉽게 접근할 수 있습니다.

```elixir
iex> t = ~T[19:39:31.056226]
~T[19:39:31.056226]
iex> t.hour
19
iex> t.minute
39
iex> t.day
** (KeyError) key :day not found in: ~T[19:39:31.056226]
```

그러나 한 가지 문제가 있습니다. 보시다시피 이 구조체에는 하루 내의 시간만 있고 년/월/일 데이터는 없습니다.

## Date

`Time`과 달리 `Date` 구조체는 현재 시간에 대한 정보없이 현재 날짜에 대한 정보를 가지고 있습니다.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

그리고 날짜를 다루기 위한 유용한 함수를 가지고 있습니다.

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

`day_of_week/1`는 주어진 날짜가 어떤 요일인지 계산해 줍니다.
이 경우에는 토요일이군요.
`leap_year?/1`는 이 날짜가 윤년인지 확인합니다.
다른 함수는 [문서](https://hexdocs.pm/elixir/Date.html)에서 확인할 수 있습니다.

## NaiveDateTime

날짜와 시간을 동시에 가지는 구조체가 Elixir는 두 개가 있습니다.
`NaiveDateTime`부터 이야기해보죠.
이 모듈에는 타임존 지원이 없다는 단점이 있습니다.

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

그러나 현재 시간과 날짜가 모두 있으므로 다음과 같이 시간을 더할 수 있습니다.

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

다음은 이 섹션의 제목에서 짐작할 수 있듯이 `DateTime`입니다.
이 모듈은 `NaiveDateTime`에서 이야기한 제한 사항이 없습니다. 시간과 날짜가 모두 있으며 타임존을 지원합니다.
하지만 타임존을 사용하기 전에 조심해야 합니다. 공식 문서에서도 이렇게 말하고 있는데요.

> 이 모듈의 많은 기능에는 시간대 데이터베이스가 필요합니다. 기본적으로 `Calendar.get_time_zone_database/0`에서 반환하는 기본 시간대 데이터베이스를 사용하며, 이 데이터베이스의 기본값은 `Calendar.UTCOnlyTimeZoneDatabase`입니다. 이는 "Etc/UTC" 날짜 시간 만 처리하고 다른 모든 타임존에 대해 `{:error, :utc_only_time_zone_database}`를 반환합니다.

또, NaiveDateTime에 타임존을 제공해 주기만 하면 DateTime 인스턴스를 만들 수 있습니다.

```elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## 타임존 다루기

이전 챕터에서 다루었듯, 기본적으로 Elixir에는 타임존 데이터가 없습니다.
이 문제를 해결하기 위해선, [tzdata](https://github.com/lau/tzdata) 팩키지를 설치하고 설정할 필요가 있습니다.
설치한 후에는, Tzdata를 타임존 데이터베이스로 사용하도록 Elixir의 전역 설정을 건드려줘야 합니다.

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

이제 파리 타임존으로 시간을 만들어 뉴욕 시간으로 변환해 보겠습니다.

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

보시다시피 시간이 파리 시각 12시에서 뉴욕 시각 6시로 변경되었습니다. 두 도시 간의 시차는 6시간이니까요.

끝입니다! 작업에 다른 고급 기능이 필요하면 [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html), [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) 문서를 꼼꼼히 읽어 보세요.
Elixir에서 시간과 함께 작업할 수있는 강력한 라이브러리인 [Timex](https://github.com/bitwalker/timex), [Calendar](https://github.com/lau/calendar)도 살펴보세요.
