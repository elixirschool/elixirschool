%{
  version: "0.9.2",
  title: "Mix",
  excerpt: """
  Trước khi đi sâu vào Elixir thì chúng ta cần tìm hiều về mix đầu tiên. Nếu bạn đã quen thuộc với Ruby thì mix tương ứng với Bundler, Rubygems và Rake hợp lại. Mix là một phần quan trọng trong bất cứ dự án Elixir nào và trong bài này chúng ta sẽ đi vào một vài tính năng thú vị của nó. Để xem mix có tất cả những chức năng gì thì chúng ta chạy `mix help`.

Tính cho đến thời điểm hiện tại thì chúng ta làm việc hoàn toàn bên trong `iex`, tuy nhiên việc đó có rất nhiều hạn chế. Để tạo được một dự án có ý nghĩa hơn thì chúng ta cần chia code ra thành nhiều file cho dễ quản lý, và mix giúp chúng ta làm việc đó với chức năng projects.
  """
}
---

## Tạo Projects
Khi chúng ta tạo một dự án Elixir mới, mix khiến việc đó trở nên vô cùng dễ dàng với câu lệnh `mix new`. Câu lệnh đó sẽ tạo ra cấu trúc thư mục project và những gì cần thiết ban đầu. Việc này khá dễ hiểu, vậy hãy bắt đầu thôi:

```bash
$ mix new example
```
Từ output chúng ta có thể thấy mix đã tạo ra thư mục mới và rất nhiều file khởi tạo:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```
Trong bài này chúng ta tập trung vào file `mix.exs`. Ở đây chúng ta có thể thay đổi cấu hình của chương trình của chúng ta, các phụ thuộc, biến môi trường, version. Mở file đó ra bằng editor yêu thích của bạn, bạn sẽ thấy như dưới đây:

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

Đầu tiên chúng ta hãy nhìn vào phần `project`. Tại đây chúng ta định nghĩa tên của ứng  (`app`), chỉ định phiên  (`version`), phiên bản Elixir (`elixir`), và cuối cùng là thư viện phụ thuộc của dự án (`deps`).

Phần `application` được sử dụng xuyên suốt các phần tiếp theo mà chúng ta sẽ sinh ra các file cho dự án.

## Biên dịch
Mix rất thông minh và sẽ biên dịch phần thay đổi của dự án khi cần thiết, tuy nhiên đôi khi chúng ta cũng cần chỉ định biên dịch một cách rõ ràng (explicitly). Ở phần này chúng ta sẽ đi vào việc biên dịch dự án của bạn và những gì được thực hiện trong quá trình biên dịch đó.

Để biên dịch một dự án mix, chúng ta sẽ cần chạy `mix compile` tại thư mục gốc:

```bash
$ mix compile
```
Dự án hiện tại của chúng ta không có quá nhiều thứ, vậy nên những gì được output ra cũng không quá thú vị, tuy nhiên chắc chắn là việc biên dịch sẽ diễn ra suôn sẻ:

```bash
Compiled lib/example.ex
Generated example app
```
Khi chúng ta biên dịch, mix sẽ tạo một thư mục `_build` cho thành quả biên dịch. Nếu nhìn vào bên trong `_build` chúng ta sẽ thấy application của chúng ta đã được biện dịch dưới dạng `example.app`.

## Tương tác
Sử dụng `iex` bên trong ngữ cảnh của chương trình của chúng ta có thể sẽ cần thiết. Rất may mắn là mix đã làm cho việc này trở nên vô cùng dễ dàng. Sau khi application đã được biên dịch, chúng ta có thể tạo một `iex` session mới:

```bash
$ cd example
$ iex -S mix
```
Khởi tạo `iex` theo cách này sẽ tải chương trình và toàn bộ phụ thuộc vào runtime hiện tại.

## Quản lý phụ thuộc
Dự án của chúng ta hiện tại chưa có phụ thuộc nào, nhưng ngay sau đây chúng ta sẽ tiến tiếp và định nghĩa phụ thuộc, cũng như tải chúng về.

Để tạo phụ thuộc mới, điều đầu tiên cần làm là thêm vào file `mix.exs`, phần `deps`. Danh sách phụ thuộc sẽ là một danh sách các tuples với hai biến cần thiết, và 1 biến tuỳ ý: Tên của package dưới dạng atom, chuỗi kí tự version, và các lựa chọn tuỳ ý.

Trong ví dụ này hãy xem một dự án với các phụ thuộc như là [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [{:phoenix, "~> 1.1 or ~> 1.2"},
   {:phoenix_html, "~> 2.3"},
   {:cowboy, "~> 1.0", only: [:dev, :test]},
   {:slime, "~> 0.14"}]
end
```
Chúng ta có thể nhận thấy trong ví dụ về phụ thuộc ở trên, phụ thuộc `cowboy` chỉ cần thiết trong quá trình phát triển cũng như test.

Sau khi đã định nghĩa danh sách phụ thuộc xong, việc cuối cùng chính là tải chúng về. Quá trình này cũng tương tự như `bundle install` trong ruby:

```bash
$ mix deps.get
```
Vậy đó! Chúng ta đã định nghĩa và tải về phụ thuộc của dự án. Như vậy từ nay về sau chúng ta có thể thêm các phụ thuộc vào bất kì khi nào cần thiết.

## Môi trường
Mix, cũng như bundler hỗ trợ nhiều môi trường khác nhau. Ở trạng thái ban đầu thì mix hỗ trợ ba loại môi trường:

+ `:dev` — Môi trường phát triển mặc định
+ `:test` — Được sử dụng bởi `mix test`. Sẽ được nói rõ hơn trong các bài học tiếp.
+ `:prod` — Được sử dụng khi ứng dụng được tải lên môi trường chạy sản phẩm (production).

Môi trường hiện tại có thể được truy cập sử dụng `Mix.env`. Và không nằm ngoài dự đoán, môi trường cũng có thể được thay đổi thông qua biến môi trường `MIX_ENV`.

```bash
$ MIX_ENV=prod mix compile
```
