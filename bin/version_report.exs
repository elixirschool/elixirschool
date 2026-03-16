#!/usr/bin/env elixir

defmodule VersionReport do
  @lessons_dir Path.expand("../lessons", __DIR__)

  def run(args) do
    {opts, _} = parse_args(args)
    lang_filter = opts[:lang]
    severity_filter = opts[:severity]

    english_versions = parse_language("en")
    languages = list_languages() -- ["en"]

    languages
    |> filter_languages(lang_filter)
    |> Enum.sort()
    |> Enum.each(fn lang ->
      translations = parse_language(lang)
      rows = build_rows(english_versions, translations, severity_filter)

      unless rows == [] do
        print_language_report(lang, rows)
      end
    end)
  end

  defp parse_args(args) do
    {parsed, rest, _} =
      OptionParser.parse(args, strict: [lang: :string, severity: :string])

    opts =
      parsed
      |> Enum.map(fn
        {:lang, val} -> {:lang, String.split(val, ",")}
        {:severity, val} -> {:severity, String.split(val, ",")}
      end)

    {opts, rest}
  end

  defp list_languages do
    @lessons_dir
    |> File.ls!()
    |> Enum.filter(&File.dir?(Path.join(@lessons_dir, &1)))
    |> Enum.sort()
  end

  defp filter_languages(languages, nil), do: languages
  defp filter_languages(languages, filter), do: Enum.filter(languages, &(&1 in filter))

  defp parse_language(lang) do
    lang_dir = Path.join(@lessons_dir, lang)

    lang_dir
    |> File.ls!()
    |> Enum.filter(&File.dir?(Path.join(lang_dir, &1)))
    |> Enum.flat_map(fn category ->
      category_dir = Path.join(lang_dir, category)

      category_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".md"))
      |> Enum.map(fn file ->
        lesson = String.trim_trailing(file, ".md")
        path = Path.join(category_dir, file)
        version = extract_version(path)
        {{category, lesson}, version}
      end)
    end)
    |> Map.new()
  end

  defp extract_version(path) do
    content = File.read!(path)

    case Regex.run(~r/version:\s*"([^"]+)"/, content) do
      [_, version] -> version
      nil -> nil
    end
  end

  defp build_rows(english_versions, translations, severity_filter) do
    english_versions
    |> Enum.sort_by(fn {{cat, lesson}, _} -> {cat, lesson} end)
    |> Enum.map(fn {{cat, lesson} = key, en_version} ->
      trans_version = Map.get(translations, key)
      status = compare_versions(en_version, trans_version)
      {cat, lesson, en_version, trans_version, status}
    end)
    |> filter_severity(severity_filter)
  end

  defp filter_severity(rows, nil), do: rows

  defp filter_severity(rows, severities) do
    Enum.filter(rows, fn {_, _, _, _, status} -> status in severities end)
  end

  defp compare_versions(_en, nil), do: "missing"
  defp compare_versions(en, trans) when en == trans, do: "current"

  defp compare_versions(en, trans) do
    [en_maj, en_min, en_pat] = parse_version(en)
    [tr_maj, tr_min, tr_pat] = parse_version(trans)

    cond do
      tr_maj < en_maj -> "major"
      tr_min < en_min -> "minor"
      tr_pat < en_pat -> "patch"
      true -> "current"
    end
  end

  defp parse_version(version) do
    version
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
  end

  defp print_language_report(lang, rows) do
    summary =
      rows
      |> Enum.group_by(fn {_, _, _, _, status} -> status end)
      |> Enum.map(fn {status, items} -> {status, length(items)} end)
      |> Map.new()

    cat_width = rows |> Enum.map(fn {c, _, _, _, _} -> String.length(c) end) |> Enum.max(fn -> 8 end) |> max(8)
    lesson_width = rows |> Enum.map(fn {_, l, _, _, _} -> String.length(l) end) |> Enum.max(fn -> 6 end) |> max(6)

    IO.puts("")
    IO.puts(IO.ANSI.bright() <> "=== #{lang} ===" <> IO.ANSI.reset())

    header =
      String.pad_trailing("Category", cat_width) <>
        "  " <>
        String.pad_trailing("Lesson", lesson_width) <>
        "  " <>
        String.pad_trailing("English", 10) <>
        String.pad_trailing(lang, 10) <>
        "Status"

    IO.puts(IO.ANSI.underline() <> header <> IO.ANSI.reset())

    Enum.each(rows, fn {cat, lesson, en_ver, trans_ver, status} ->
      color = status_color(status)
      trans_display = trans_ver || "—"

      line =
        String.pad_trailing(cat, cat_width) <>
          "  " <>
          String.pad_trailing(lesson, lesson_width) <>
          "  " <>
          String.pad_trailing(en_ver || "?", 10) <>
          String.pad_trailing(trans_display, 10) <>
          color <> status <> IO.ANSI.reset()

      IO.puts(line)
    end)

    summary_parts =
      ["current", "patch", "minor", "major", "missing"]
      |> Enum.filter(&Map.has_key?(summary, &1))
      |> Enum.map(fn status ->
        status_color(status) <> "#{Map.get(summary, status)} #{status}" <> IO.ANSI.reset()
      end)

    IO.puts("\nSummary: " <> Enum.join(summary_parts, ", "))
  end

  defp status_color("current"), do: IO.ANSI.green()
  defp status_color("patch"), do: IO.ANSI.yellow()
  defp status_color("minor"), do: IO.ANSI.light_yellow()
  defp status_color("major"), do: IO.ANSI.red()
  defp status_color("missing"), do: IO.ANSI.light_red()
  defp status_color(_), do: ""
end

VersionReport.run(System.argv())
