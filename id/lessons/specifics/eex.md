---
layout: page
title: Embedded Elixir (EEx)
category: specifics
order: 3
lang: id
---

Sebagaimana Ruby punya ERB dan Java punya JSP, Elixir punya EEx atau Embedded Elixir.  Dengan EEx kita bisa memasukkan dan menjalankan Elixir di dalam string.

## Daftar Isi

- [API](#API)
	- [Evaluasi](#evaluasi)
	- [Definisi](#definisi)
	- [Kompilasi](#kompilasi)
- [Tag](#tag)
- [Engine](#engine)

## API

API EEx mendukung pengerjaan dengan string dan file secara langsung.  API tersebut dibagi dalam tiga komponen utama: evaluasi sederhana, definisi fungsi, dan kompilasi ke AST.

### Evaluasi

Menggunakan `eval_string` dan `eval_file` kita dapat melakukan evaluasi sederhana terhadap sebuah string atau isi file.  Ini adalah API paling sederhana tetapi yang paling lambat karena code dievaluasi dan bukan dikompilasi.

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### Definisi

Metode paling cepat, dan paling disukai, untuk menggunakan EEx adalah memasukkan template ke dalam sebuah modul sehingga dapat dikompilasi.  Untuk hal ini kita perlukan template kita pada saat kompilasi, bersama macro `function_from_string` dan `function_from_file`.

Mari pindahkan ucapan salam di atas ke file terpisah dan hasilkan sebuah fungsi untuk template kita:

```elixir
# greeting.eex
Hi, <%= name %>

defmodule Example do
  require EEx
  EEx.function_from_file :def, :greeting, "greeting.eex", [:name]
end

iex> Example.greeting("Sean")
"Hi, Sean"
```

### Kompilasi

Terakhir, EEx memberi kita sebuah cara untuk secara langsung menghasilkan AST Elixir dari sebuah string atau file menggunakan `compile_string` atau `compile_file`. API ini utamanya digunakan oleh API yang sudah dibahas di awal tetapi juga tersedia jika anda ingin mengimplementasi penanganan sendiri terhadap Elixir yang diembed.

## Tag

Secara default ada empat tag yang didukung di EEx:

```elixir
<% Elixir expression - inline with output %>
<%= Elixir expression - replace with result %>
<%% EEx quotation - returns the contents inside %>
<%# Comments - they are discarded from source %>
```

Semua ekspresi yang ingin menghasilkan output __harus__ menggunakan tanda sama dengan (`=`).  Adalah penting dicatat bahwa sementara bahasa templating lain memperlakukan hal seperti `if` secara berbeda, EEx tidak.  Tanpa `=` berikut ini tidak menghasilkan output:

```elixir
<%= if true do %>
  A truthful statement
<% else %>
  A false statement
<% end %>
```

## Engine

Secara default Elixir menggunakan `EEx.SmartEngine`, yang menyertakan dukungan untuk assignment (seperti `@name`):

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

Assignment di `EEx.SmartEngine` berguna karena assignment bisa diubah tanpa mengkompilasi template.

Tertarik untuk menulis engine sendiri?  Lihatlah perilaku [`EEx.Engine`](http://elixir-lang.org/docs/v1.2/eex/EEx.Engine.html) untuk melihat apa saja yang dibutuhkan.
